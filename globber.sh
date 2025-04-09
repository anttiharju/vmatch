#!/bin/bash

set -euo pipefail

# Directory containing workflow files
WORKFLOW_DIR=".github/workflows"

# Function to extract paths from a workflow file and format them for lefthook
extract_paths_and_commands() {
    local file="$1"
    local job_name="$2"

    echo "Processing file: $file" >&2

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

    echo "Found paths:" >&2
    echo "$paths" >&2

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

    echo "Found comment: $step_comment" >&2

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
        echo "Using step name from workflow: $job_name" >&2
    fi

    # Extract the run command
    local run_command
    run_command=$(awk '
        BEGIN { found=0; in_steps=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /steps:/ { in_steps=1; }
        in_steps==1 && /run:/ { sub(/^.*run: /, ""); print; exit; }
    ' "$file")

    echo "Found command: $run_command" >&2

    # Check for stage_fixed comment after the run command
    local stage_fixed
    stage_fixed=$(awk '
        BEGIN { found=0; in_steps=0; after_run=0; }
        /^\/\// { next; }  # Skip comment lines starting with //
        /steps:/ { in_steps=1; }
        in_steps==1 && /run:/ { after_run=1; next; }
        after_run==1 && /# stage_fixed:/ { print; exit; }
    ' "$file")

    # Also check for uncommented stage_fixed property
    if [ -z "$stage_fixed" ]; then
        stage_fixed=$(awk '
            BEGIN { found=0; in_steps=0; }
            /^\/\// { next; }  # Skip comment lines starting with //
            /steps:/ { in_steps=1; }
            in_steps==1 && /stage_fixed:/ { print; exit; }
        ' "$file")
    fi

    echo "Found stage_fixed: $stage_fixed" >&2

    # Convert the paths to a comma-separated list for lefthook wildcard format
    local formatted_paths=""
    while IFS= read -r path; do
        # Convert GitHub Actions path patterns to lefthook-compatible glob patterns

        # Handle specific patterns
        if [[ "$path" == "**/*.go" || "$path" == "**/*.sh" || "$path" == "**/*.bash" || "$path" == "**/*.dash" || "$path" == "**/*.ksh" ]]; then
            # For files with these extensions in any directory, just use *.extension in lefthook
            path=${path#**/}
        elif [[ "$path" == "**/*.yml" || "$path" == "**/action.yml" ]]; then
            # For yml files in any directory, use *.yml in lefthook
            path=${path#**/}
        elif [[ "$path" =~ ^([^*]+)/\*\*/\*$ ]]; then
            # Handle patterns like "dist/brew/**/*" -> "dist/brew/*"
            path="${BASH_REMATCH[1]}/*"
        elif [[ "$path" =~ ^([^*]+)/\*\*/\*\*$ ]]; then
            # Handle patterns like "dist/brew/**/**" -> "dist/brew/*"
            path="${BASH_REMATCH[1]}/*"
        else
            # General replacement: any **/ pattern becomes just *
            path=${path//\*\*\//*/}
        fi

        if [ -n "$formatted_paths" ]; then
            formatted_paths="$formatted_paths,$path"
        else
            formatted_paths="$path"
        fi
    done <<< "$paths"

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
            echo "Found workflow file: $file" >&2

            # Extract job name from filename
            local job_name
            job_name=$(basename "$file" | sed 's/^wildcard-//;s/\.yml$//')

            # Replace hyphens with spaces and capitalize first letter
            job_name=$(echo "$job_name" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

            echo "Job name: $job_name" >&2

            extract_paths_and_commands "$file" "$job_name"
        fi
    done
}

# Run the main function
main
