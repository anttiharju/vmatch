#!/bin/sh

# Check for relative Markdown links and verify they exist
# Usage: ./check-relative-links.sh file1.md file2.md ...

set -eu

if [ $# -eq 0 ]; then
    echo "Usage: $0 <file1.md> [file2.md] [...]"
    exit 1
fi

EXIT_CODE=0

for file in "$@"; do
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        EXIT_CODE=1
        continue
    fi

    # Get the directory of the current file to resolve relative paths
    dir=$(dirname "$file")

    echo "Checking links in $file..."

    # Find all lines with relative links using grep
    link_lines=$(grep -n "[^]]*](\.[^)]*)" "$file" || true)

    # If no links are found, continue to the next file
    if [ -z "$link_lines" ]; then
        echo "  No relative links found"
        continue
    fi

    file_has_broken_links=0

    # Use a for loop to process links instead of a pipeline/while loop
    for line_with_num in $link_lines; do
        # Extract line number and content
        line_num=$(echo "$line_with_num" | cut -d: -f1)
        line=$(echo "$line_with_num" | cut -d: -f2-)

        # Extract the link portion using sed
        link=$(echo "$line" | grep -o "](\.[^)]*)" | awk -F'[(]' '{print $2}' | awk -F'[)]' '{print $1}')

        # Handle anchor links by removing the #section part
        target_path=$(echo "$link" | awk -F'#' '{print $1}')

        # Construct the full path relative to the file's location
        full_path="$dir/$target_path"

        if [ -z "$target_path" ]; then
            # Skip empty links (just anchors)
            continue
        elif [ ! -e "$full_path" ]; then
            echo "  ❌ Broken link: $link on line $line_num in $file"
            file_has_broken_links=1
        else
            echo "  ✅ Valid link: $link"
        fi
    done

    # Update the exit code if broken links were found
    if [ "$file_has_broken_links" -eq 1 ]; then
        EXIT_CODE=1
    fi
done

if [ "$EXIT_CODE" -eq 0 ]; then
    echo "✅ All relative links are valid!"
fi

exit "$EXIT_CODE"
