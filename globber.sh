#!/bin/bash
# filepath: /Users/antti/anttiharju/vmatch/globber.sh

set -euo pipefail

# Directory containing workflow files
WORKFLOW_DIR=".github/workflows"

# Function to extract paths from a workflow file and format them for lefthook
extract_paths() {
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

    # Convert the paths to a comma-separated list for lefthook glob format
    local formatted_paths=""
    while IFS= read -r path; do
        # Replace /**/* pattern with /* for lefthook compatibility
        path=$(echo "$path" | sed 's/\/\*\*\/\*/\/\*/g')

        if [ -n "$formatted_paths" ]; then
            formatted_paths="$formatted_paths,$path"
        else
            formatted_paths="$path"
        fi
    done <<< "$paths"

    # Output the lefthook job format
    echo "    - name: $job_name"
    echo "      glob: \"{$formatted_paths}\""
    echo "      run: echo \"TODO: Add command for $job_name\""
    echo ""
}

# Main function
main() {
    echo "# Lefthook jobs generated from workflow globs"
    echo "pre-commit:"
    echo "  parallel: true"
    echo "  jobs:"

    # Check if the workflow directory exists
    if [ ! -d "$WORKFLOW_DIR" ]; then
        echo "Error: Workflow directory not found: $WORKFLOW_DIR" >&2
        echo "Current directory: $(pwd)" >&2
        return 1
    fi

    # List all workflow files that match the pattern
    echo "Looking for glob-*.yml files in $WORKFLOW_DIR" >&2
    ls -la "$WORKFLOW_DIR"/glob-*.yml >&2 || echo "No glob workflow files found" >&2

    # Process each glob workflow file
    for file in "$WORKFLOW_DIR"/glob-*.yml; do
        if [ -f "$file" ]; then
            echo "Found workflow file: $file" >&2

            # Skip comment lines at the start and extract workflow name
            local workflow_name
            workflow_name=$(awk '
                /^\/\// { next; }  # Skip comment lines starting with //
                /^name:/ { sub(/^name: /, ""); print $0; exit; }
            ' "$file")

            echo "Workflow name: $workflow_name" >&2

            # Extract job name from workflow name
            local job_name
            job_name=$(echo "$workflow_name" | cut -d ' ' -f 2-)

            echo "Job name: $job_name" >&2

            extract_paths "$file" "$job_name"
        fi
    done
}

# Run the main function
main
