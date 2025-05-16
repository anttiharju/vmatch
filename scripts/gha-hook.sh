#!/bin/bash

set -euo pipefail

# Directory containing workflow files
WORKFLOW_DIR=".github/workflows"
ACTION_DIR=".github/actions/detect-changes"
ACTION_YML="${ACTION_DIR}/action.yml"
PLAN_YML=".github/workflows/plan.yml"

# Extract job IDs and their details from wildcard workflow files
parse_wildcard_files() {
    local workflows=()
    local ids=()
    local descriptions=()
    local paths=()
    local step_names=()
    local action_refs=()

    # Get all wildcard workflow files
    for file in "${WORKFLOW_DIR}"/wildcard-*.yml; do
        if [ -f "$file" ]; then
            # Extract job name from filename
            local job_name
            job_name=$(basename "$file" | sed 's/^wildcard-//;s/\.yml$//')
            workflows+=("$job_name")

            # Extract job ID (used in GitHub Actions)
            local job_id
            job_id=$(grep -A 3 "jobs:" "$file" | grep -v "jobs:" | grep ":" | head -n 1 | sed 's/://')
            job_id=$(echo "$job_id" | xargs)
            ids+=("$job_id")

            # Generate a readable description
            local desc
            desc=$(echo "$job_name" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')
            descriptions+=("$desc")

            # Extract paths that trigger the workflow
            local path_list
            path_list=$(awk '
                BEGIN { found=0; }
                /paths:/ { found=1; next; }
                found==1 && /^ *[^- ]/ { found=0; }
                found==1 && /^ *- / { gsub(/^ *- /,""); gsub(/"/,""); print; }
            ' "$file" | paste -sd, -)
            paths+=("$path_list")

            # Extract step name used in the workflow
            local step_name
            step_name=$(awk '
                BEGIN { found=0; in_steps=0; }
                /steps:/ { in_steps=1; next; }
                in_steps==1 && /name:/ {
                    gsub(/^.*name: /,"");
                    gsub(/"/,"");
                    print;
                    exit;
                }
            ' "$file")
            step_names+=("$step_name")

            # Extract action reference (the uses: line)
            local action_ref
            action_ref=$(awk '
                BEGIN { found=0; in_steps=0; }
                /steps:/ { in_steps=1; next; }
                in_steps==1 && /uses:/ && !/\.\/\.github/ {
                    gsub(/^.*uses: /,"");
                    gsub(/"/,"");
                    print;
                    exit;
                }
            ' "$file")
            action_refs+=("$action_ref")
        fi
    done

    # Export arrays to be used by other functions
    export workflows=("${workflows[@]}")
    export ids=("${ids[@]}")
    export descriptions=("${descriptions[@]}")
    export paths=("${paths[@]}")
    export step_names=("${step_names[@]}")
    export action_refs=("${action_refs[@]}")
}

# Generate the detect-changes action.yml file
generate_detect_changes_action() {
    mkdir -p "$ACTION_DIR"

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

    # Add steps for each workflow
    for i in "${!workflows[@]}"; do
        cat >> "$ACTION_YML" << EOF
    - id: ${ids[$i]}
      uses: anttiharju/actions/compare-changes@v0
      with:
        wildcard: ${workflows[$i]}
        changes: \${{ inputs.changes }}
EOF
    done

    # Add outputs section
    cat >> "$ACTION_YML" << EOF
outputs:
EOF

    # Add outputs for each job
    for i in "${!workflows[@]}"; do
        cat >> "$ACTION_YML" << EOF
  ${ids[$i]}:
    description: "Whether ${descriptions[$i]} have changed"
    value: \${{ steps.${ids[$i]}.outputs.changed }}
EOF
    done

    echo "Generated ${ACTION_YML}"
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
        # Read existing file up to the "steps:" section
        awk '
          /steps:/ { print; print "      - name: Find changes"; print "        id: changes"; print "        uses: anttiharju/actions/find-changes@v0"; print ""; print "      - name: Detect changes"; print "        id: changed"; print "        uses: ./.github/actions/detect-changes"; print "        with:"; print "          changes: ${{ steps.changes.outputs.array }}"; print ""; exit; }
          { print }
        ' "$PLAN_YML" > "$tempfile"
    fi

    # Add conditional steps for each workflow
    for i in "${!workflows[@]}"; do
        cat >> "$tempfile" << EOF
      - if: always() && (steps.changed.outputs.${ids[$i]} == 'true' || github.event_name == 'push')
        name: ${step_names[$i]}
        uses: ${action_refs[$i]}

EOF
    done

    # Add outputs section
    cat >> "$tempfile" << EOF
    outputs:
      binary_changed: \${{ steps.changed.outputs.binary }}
      homebrew_formula_changed: \${{ steps.changed.outputs.homebrew_formula }}
      documentation_changed: \${{ steps.changed.outputs.documentation }}
EOF

    # Replace the plan.yml file
    mv "$tempfile" "$PLAN_YML"
    echo "Updated ${PLAN_YML}"
}

main() {
    # Parse wildcard workflow files
    parse_wildcard_files

    # Generate detect-changes action
    generate_detect_changes_action

    # Update plan.yml with conditional steps
    update_plan_yml

    echo "GitHub Actions hook files generated successfully!"
}

main "$@"
