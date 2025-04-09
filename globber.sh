#!/bin/bash

set -euo pipefail

# Directory containing workflow files
WORKFLOW_DIR=".github/workflows"

# Function to extract paths from a workflow file and format them for lefthook
extract_paths_and_commands() {
    local file="$1"
    local job_name="$2"

    # Extract the paths section, skipping any comment lines at the start
    local paths
    paths=$(awk '
        BEGIN { found=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /paths:/ { found=1; next; }
        found==1 && /^ *[^- ]/ { found=0; }
        found==1 && /^ *- / { print $0; }
    ' "$file" | sed 's/^ *- //g' | sed 's/"//g')

    if [ -z "$paths" ]; then
        echo "No paths found in $file" >&2
        return
    fi

    # Extract any comments above the step name
    local step_comment
    step_comment=$(awk '
        BEGIN { found=0; comment=""; in_steps=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /steps:/ { in_steps=1; next; }
        in_steps==1 && /^ *#/ { comment=comment $0 "\n"; next; }
        in_steps==1 && /^ *- name:/ { found=1; exit; }
        in_steps==1 && /^ *[^#]/ && comment != "" { found=0; exit; }
        END { if (found) print comment; }
    ' "$file" | sed 's/^ *//g')

    # Remove trailing newline if present
    step_comment=${step_comment%$'\n'}

    # Extract the step name
    local step_name
    step_name=$(awk '
        BEGIN { found=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /- name:/ { sub(/.*name: /, ""); print; exit; }
    ' "$file")

    # If step name is found, use it instead of the filename-based job name
    if [ -n "$step_name" ]; then
        job_name="$step_name"
    fi

    # Extract the run command - handling multiline with | character
    # Extract the run command - handling multiline with | character
    local run_command
    run_command=$(awk '
        BEGIN { found=0; in_steps=0; in_run=0; command=""; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /steps:/ { in_steps=1; }
        in_steps==1 && /run:/ {
            if ($0 ~ /run: \|/) {
                in_run=1;
                next;
            } else {
                sub(/^.*run: /, "");
                print;
                exit;
            }
        }
        in_run==1 && /^ +/ {
            # Collect indented lines after run: |
            gsub(/^[ \t]+/, "", $0);  # Remove leading spaces

            # Skip comment-only lines
            if ($0 ~ /^#/) {
                next;
            }

            # Append line to command
            if (command == "") {
                command = $0;
            } else {
                command = command "; " $0;
            }
        }
        in_run==1 && /^ *$/ { next; }  # Skip empty lines
        in_run==1 && (/^ *[^- ]/ && !/^ +/) { in_run=0; }  # End of run block
        END {
            if (command != "") {
                print command;
            }
        }
    ' "$file")

    # Check for stage_fixed comment after the run command
    local stage_fixed
    stage_fixed=$(awk '
        BEGIN { found=0; in_steps=0; after_run=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /steps:/ { in_steps=1; }
        in_steps==1 && /run:/ {
            after_run=1;
            if ($0 ~ /run: \|/) {
                # For multiline run, keep reading until indentation changes
                next;
            } else {
                next;
            }
        }
        after_run==1 && /^ +[^- #]/ && /run: \|/ {
            # Skip content lines of multiline run
            next;
        }
        after_run==1 && /# stage_fixed:/ { print; exit; }
        after_run==1 && /stage_fixed:/ { print; exit; }
    ' "$file")

    # Convert the paths to a comma-separated list for lefthook wildcard format
    local formatted_paths=""
    local shell_exts=()
    local has_go=false
    local has_yml=false
    local has_yaml=false
    local has_md=false
    local special_paths=()

    # First pass - identify groups of extensions
    while IFS= read -r path; do
        # Check for common extension patterns to group
        if [[ "$path" == "**/*.sh" ]]; then
            shell_exts+=(".sh")
        elif [[ "$path" == "**/*.bash" ]]; then
            shell_exts+=(".bash")
        elif [[ "$path" == "**/*.dash" ]]; then
            shell_exts+=(".dash")
        elif [[ "$path" == "**/*.ksh" ]]; then
            shell_exts+=(".ksh")
        elif [[ "$path" == "**/*.go" ]]; then
            has_go=true
        elif [[ "$path" == "**/*.yml" || "$path" == "**/action.yml" ]]; then
            has_yml=true
        elif [[ "$path" == "**/*.yaml" ]]; then
            has_yaml=true
        elif [[ "$path" == "**/*.md" ]]; then
            has_md=true
        elif [[ "$path" =~ ^([^*]+)/\*\*/\*$ ]]; then
            # Handle patterns like "dist/brew/**/*" -> "dist/brew/*"
            special_paths+=("${BASH_REMATCH[1]}/*")
        elif [[ "$path" =~ ^([^*]+)/\*\*/\*\*$ ]]; then
            # Handle patterns like "dist/brew/**/**" -> "dist/brew/*"
            special_paths+=("${BASH_REMATCH[1]}/*")
        else
            # Handle specific paths that shouldn't be grouped
            path=${path//\*\*\//*/}
            special_paths+=("$path")
        fi
    done <<< "$paths"

    # Build groups of extensions for cleaner glob patterns
    if [[ ${#shell_exts[@]} -gt 0 ]]; then
        # Join shell extensions into a single pattern like "*{.sh,.bash,.dash,.ksh}"
        local shell_pattern="*{"
        for i in "${!shell_exts[@]}"; do
            shell_pattern+="${shell_exts[$i]}"
            if [[ $i -lt $((${#shell_exts[@]} - 1)) ]]; then
                shell_pattern+=","
            fi
        done
        shell_pattern+="}"
        special_paths+=("$shell_pattern")
    fi

    # Add other grouped extensions
    [[ "$has_go" = true ]] && special_paths+=("*.go")
    [[ "$has_yml" = true ]] && special_paths+=("*.yml")
    [[ "$has_yaml" = true ]] && special_paths+=("*.yaml")
    [[ "$has_md" = true ]] && special_paths+=("*.md")

    # Now generate the final formatted paths
    for path in "${special_paths[@]}"; do
        if [ -n "$formatted_paths" ]; then
            formatted_paths="$formatted_paths,$path"
        else
            formatted_paths="$path"
        fi
    done

    # Output the comment if found
    if [ -n "$step_comment" ]; then
        echo "    $step_comment"
    fi

    # Output the lefthook job format
    echo "    - name: $job_name"

    # Only add curly braces if there's more than one item
    if [[ "$formatted_paths" == *","* ]]; then
        echo "      glob: \"{$formatted_paths}\""
    else
        echo "      glob: \"$formatted_paths\""
    fi

    # Use the actual run command if found, otherwise use the placeholder
    if [ -n "$run_command" ]; then
        echo "      run: $run_command"
    else
        echo "      run: echo \"TODO: Add command for $job_name\""
    fi

    # Add stage_fixed: true if found in comments or as property
    if [[ "$stage_fixed" == *"stage_fixed: true"* ]] || [[ "$stage_fixed" == *"# stage_fixed: true"* ]]; then
        echo "      stage_fixed: true"
    fi

    echo ""
}

# Main function
main() {
    echo "# Lefthook jobs generated from workflow wildcards"
    echo "pre-commit:"
    echo "  parallel: true"
    echo "  jobs:"

    # Check if the workflow directory exists
    if [ ! -d "$WORKFLOW_DIR" ]; then
        echo "Error: Workflow directory not found: $WORKFLOW_DIR" >&2
        echo "Current directory: $(pwd)" >&2
        return 1
    fi

    # Process each wildcard workflow file
    for file in "$WORKFLOW_DIR"/wildcard-*.yml; do
        if [ -f "$file" ]; then

            # Extract job name from filename
            local job_name
            job_name=$(basename "$file" | sed 's/^wildcard-//;s/\.yml$//')

            # Replace hyphens with spaces and capitalize first letter
            job_name=$(echo "$job_name" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

            extract_paths_and_commands "$file" "$job_name"
        fi
    done
}

# Run the main function
main
