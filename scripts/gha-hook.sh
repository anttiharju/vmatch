#!/bin/bash

set -euo pipefail

# Directory containing workflow files
WORKFLOW_DIR=".github/workflows"
ACTION_DIR=".github/actions/detect-changes"
ACTION_YML="${ACTION_DIR}/action.yml"
PLAN_YML=".github/workflows/plan.yml"

# Extract job IDs and their details from wildcard workflow files
parse_wildcard_files() {
    # Initialize arrays locally
    local workflows_list=()
    local ids_list=()
    local descriptions_list=()
    local paths_list=()
    local step_names_list=()
    local action_refs_list=()
    local always_list=()  # New array to track if the check should run always

    # Get all wildcard workflow files
    for file in "${WORKFLOW_DIR}"/wildcard-*.yml; do
        if [ -f "$file" ]; then
            # Extract job name from filename
            local job_name
            job_name=$(basename "$file" | sed 's/^wildcard-//;s/\.yml$//')
            workflows_list+=("$job_name")

            # Extract job ID (used in GitHub Actions)
            local job_id
            job_id=$(grep -A 3 "jobs:" "$file" | grep -v "jobs:" | grep ":" | head -n 1 | sed 's/://')
            job_id=$(echo "$job_id" | tr -d ' ')

            # Check if this job should always run (no paths in the trigger)
            local should_always_run=false
            if ! grep -q "paths:" "$file"; then
                should_always_run=true
                job_id="always"  # Use 'always' as the ID
            fi

            ids_list+=("$job_id")
            always_list+=("$should_always_run")

            # Generate a readable description
            local desc
            desc=$(echo "$job_name" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
            descriptions_list+=("$desc")

            # Extract paths that trigger the workflow
            local path_list
            path_list=$(awk '
                BEGIN { found=0; }
                /paths:/ { found=1; next; }
                found==1 && /^ *[^- ]/ { found=0; }
                found==1 && /^ *- / { gsub(/^ *- /,""); gsub(/"/,""); print; }
            ' "$file" | tr '\n' ',' | sed 's/,$//')
            paths_list+=("$path_list")

            # Extract step name used in the workflow
            local step_name
            step_name=$(awk '
                BEGIN { found=0; }
                /steps:/ { found=1; next; }
                found==1 && /- name:/ {
                    sub(/.*name: */, "");
                    sub(/^"/, "");
                    sub(/"$/, "");
                    print;
                    exit;
                }
            ' "$file")
            step_names_list+=("$step_name")

            # Extract action reference (the uses: line)
            local action_ref
            action_ref=$(awk '
                BEGIN { found=0; }
                /steps:/ { found=1; next; }
                found==1 && /uses:/ && !/.\/\.github/ {
                    sub(/.*uses: */, "");
                    sub(/^"/, "");
                    sub(/"$/, "");
                    print;
                    exit;
                }
            ' "$file")
            action_refs_list+=("$action_ref")
        fi
    done

    # Make arrays available globally
    workflows=("${workflows_list[@]}")
    ids=("${ids_list[@]}")
    descriptions=("${descriptions_list[@]}")
    paths=("${paths_list[@]}")
    step_names=("${step_names_list[@]}")
    action_refs=("${action_refs_list[@]}")
    always=("${always_list[@]}")
}

# Generate the detect-changes action.yml file
generate_detect_changes_action() {
    mkdir -p "$ACTION_DIR"

    # Create the header
    cat > "$ACTION_YML" << EOF
name: "Detect changes"
description: "Decide what steps need running based on changes"
inputs:
  changes:
    description: "JSON array of changed files"
    required: true
runs:
  using: "composite"
  steps:
EOF

    # Instead of associative arrays, we'll use regular arrays and checking functions
    local used_ids=()

    # Function to check if an ID is already used
    is_id_used() {
        local id="$1"
        local i
        for i in "${!used_ids[@]}"; do
            if [[ "${used_ids[$i]}" == "$id" ]]; then
                return 0  # true, ID is used
            fi
        done
        return 1  # false, ID is not used
    }

    # Add steps for each workflow
    for i in "${!workflows[@]}"; do
        local id="${ids[$i]}"
        local workflow="${workflows[$i]}"

        # Skip if we already have a step with this ID
        if is_id_used "$id"; then
            continue
        fi

        # Skip check-relative-markdown-links as it doesn't need a detect-changes step
        if [[ "$workflow" == "check-relative-markdown-links" ]]; then
            continue
        fi

        # Mark this ID as used
        used_ids+=("$id")

        if [[ -n "$id" ]]; then
            cat >> "$ACTION_YML" << EOF
    - id: ${id}
      uses: anttiharju/actions/compare-changes@v0
      with:
        wildcard: ${workflow}
        changes: \${{ inputs.changes }}
EOF
        fi
    done

    # Add outputs section
    echo "outputs:" >> "$ACTION_YML"

    # Reset the used IDs array for outputs
    used_ids=()

    # Add outputs for each job
    for i in "${!workflows[@]}"; do
        local id="${ids[$i]}"
        local workflow="${workflows[$i]}"

        # Skip duplicate IDs and always jobs (they don't need outputs)
        if is_id_used "$id" || [[ "$id" == "always" ]] || [[ "$workflow" == "check-relative-markdown-links" ]]; then
            continue
        fi

        used_ids+=("$id")

        if [[ -n "$id" ]]; then
            cat >> "$ACTION_YML" << EOF
  ${id}:
    description: "Whether ${descriptions[$i]} have changed"
    value: \${{ steps.${id}.outputs.changed }}
EOF
        fi
    done

    # Debug info
    echo "Generated ${ACTION_YML} with $(grep -c "id:" "$ACTION_YML") steps and $(grep -c "value:" "$ACTION_YML") outputs"
}

# Generate or update the plan.yml file with conditional steps
update_plan_yml() {
    local tempfile
    tempfile=$(mktemp)

    # If plan.yml doesn't exist, create a basic structure
    if [ ! -f "$PLAN_YML" ]; then
        cat > "$tempfile" << EOF
name: Plan
on:
  pull_request:
  workflow_call:
    outputs:
      release:
        description: "Whether to trigger github-release job"
        value: \${{ jobs.validate.outputs.binary_changed }}
      distribution:
        description: "Whether to trigger distribution workflow"
        value: \${{ jobs.validate.outputs.homebrew_formula_changed || jobs.validate.outputs.binary_changed }}
      documentation:
        description: "Whether to trigger documentation workflow"
        value: \${{ jobs.validate.outputs.documentation_changed }}

jobs:
  validate:
    name: Validate
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Find changes
        id: changes
        uses: anttiharju/actions/find-changes@v0

      - name: Detect changes
        id: changed
        uses: ./.github/actions/detect-changes
        with:
          changes: \${{ steps.changes.outputs.array }}

EOF
    else
        # Keep everything up to the Find changes step, then replace the rest
        awk '
          BEGIN { found=0 }
          /- name: Find changes/ { found=1 }
          { if (!found) print }
          /- name: Find changes/ {
              print "      - name: Find changes";
              print "        id: changes";
              print "        uses: anttiharju/actions/find-changes@v0";
              print "";
              print "      - name: Detect changes";
              print "        id: changed";
              print "        uses: ./.github/actions/detect-changes";
              print "        with:";
              print "          changes: \${{ steps.changes.outputs.array }}";
              print "";
              exit;
          }
        ' "$PLAN_YML" > "$tempfile"
    fi

    # Instead of associative arrays, we'll use regular arrays and a check function
    local used_steps=()

    # Function to check if a step is already used
    is_step_used() {
        local step="$1"
        local i
        for i in "${!used_steps[@]}"; do
            if [[ "${used_steps[$i]}" == "$step" ]]; then
                return 0  # true, step is used
            fi
        done
        return 1  # false, step is not used
    }

    # Add conditional steps for each workflow
    for i in "${!workflows[@]}"; do
        local id="${ids[$i]}"
        local workflow="${workflows[$i]}"
        local step_name="${step_names[$i]}"
        local action_ref="${action_refs[$i]}"

        # Skip if we've already added this step
        if is_step_used "$step_name"; then
            continue
        fi
        used_steps+=("$step_name")

        if [[ -n "$step_name" && -n "$action_ref" ]]; then
            # Special handling for check-relative-markdown-links and editorconfig-checker
            if [[ "$workflow" == "check-relative-markdown-links" || "$workflow" == "editorconfig-checker" ]]; then
                cat >> "$tempfile" << EOF
      - if: always()
        name: ${step_name}
        uses: ${action_ref}

EOF
            # For other 'always' jobs, they run regardless of changes plus on push
            elif [[ "$id" == "always" ]]; then
                cat >> "$tempfile" << EOF
      - if: always() || github.event_name == 'push'
        name: ${step_name}
        uses: ${action_ref}

EOF
            # Normal conditional steps
            else
                cat >> "$tempfile" << EOF
      - if: always() && (steps.changed.outputs.${id} == 'true' || github.event_name == 'push')
        name: ${step_name}
        uses: ${action_ref}

EOF
            fi
        fi
    done

    # Add outputs section
    cat >> "$tempfile" << EOF
    outputs:
EOF

    # Check for specific job IDs that need to be exposed as outputs
    local has_binary=false
    local has_doc=false
    local has_formula=false

    for i in "${!ids[@]}"; do
        if [[ "${ids[$i]}" == "binary" ]]; then
            has_binary=true
        elif [[ "${ids[$i]}" == "documentation" ]]; then
            has_doc=true
        elif [[ "${ids[$i]}" == "validate-formula" ]]; then
            has_formula=true
        fi
    done

    if $has_binary; then
        echo '      binary_changed: ${{ steps.changed.outputs.binary }}' >> "$tempfile"
    fi
    if $has_doc; then
        echo '      documentation_changed: ${{ steps.changed.outputs.documentation }}' >> "$tempfile"
    fi
    if $has_formula; then
        echo '      homebrew_formula_changed: ${{ steps.changed.outputs.validate-formula }}' >> "$tempfile"
    fi

    # Replace the plan.yml file
    mv "$tempfile" "$PLAN_YML"

    # Debug info
    echo "Updated ${PLAN_YML} with $(grep -c "- if:" "$PLAN_YML") conditional steps"
}

main() {
    echo "Starting GitHub Actions hook generation..."

    # Declare global arrays
    declare -a workflows
    declare -a ids
    declare -a descriptions
    declare -a paths
    declare -a step_names
    declare -a action_refs
    declare -a always

    # Parse wildcard workflow files
    parse_wildcard_files

    # Check if we found any workflows
    if [[ ${#workflows[@]} -eq 0 ]]; then
        echo "Error: No wildcard-*.yml workflow files found in ${WORKFLOW_DIR}"
        exit 1
    fi

    echo "Found ${#workflows[@]} wildcard workflows to process"

    # Generate detect-changes action
    generate_detect_changes_action

    # Update plan.yml with conditional steps
    update_plan_yml

    echo "GitHub Actions hook files generated successfully!"
}

main "$@"
