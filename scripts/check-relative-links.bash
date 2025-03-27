#!/usr/bin/env bash

# Check for relative Markdown links and verify they exist
# Usage: ./check-relative-links.sh file1.md file2.md ...

set -eu

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <file1.md> [file2.md] [...]"
    exit 1
fi

EXIT_CODE=0

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: File not found: $file"
        EXIT_CODE=1
        continue
    fi

    # Get the directory of the current file to resolve relative paths
    dir=$(dirname "$file")

    echo "Checking links in $file..."

    # Extract all relative links in one pass with awk
    # This avoids multiple grep/awk/echo calls per link
    link_data=$(awk '
        match($0, /\]\(\.[^)]*\)/) {
            link = substr($0, RSTART+2, RLENGTH-3)
            gsub(/#.*$/, "", link)  # Remove anchor part
            if (link != "") {
                print NR ":" link
            }
        }' "$file")

    # If no links are found, continue to the next file
    if [[ -z "$link_data" ]]; then
        echo "  No relative links found"
        continue
    fi

    # Initialize before the subshell
    broken_links_found=0

    # Process each link
    while IFS=: read -r line_num link; do
        # Construct the full path relative to the file's location
        full_path="$dir/$link"

        if [[ ! -e "$full_path" ]]; then
            echo "  ❌ Broken link: $link on line $line_num in $file"
            broken_links_found=1
        else
            echo "  ✅ Valid link: $link"
        fi
    done < <(echo "$link_data")

    # Now broken_links_found is accessible outside of the subshell
    if [[ $broken_links_found -eq 1 ]]; then
        EXIT_CODE=1
    fi
done

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "✅ All relative links are valid!"
fi

exit "$EXIT_CODE"
