#!/usr/bin/env python3

# Imported from
# https://github.com/anttiharju/actions/tree/3bf46fab21d645c42acdf6a8e70a84fbecfa383e/check-shellcheck

import sys


def is_shell_script(file_info):
    return any(
        shell_indicator.lower() in file_info.lower()
        for shell_indicator in [
            "POSIX shell script",
            "sh script text executable",
            "sh script, ASCII text executable",
            "Bourne-Again shell script",
        ]
    )


def main():
    for line in sys.stdin:
        parts = line.strip().split(":", 1)
        if len(parts) != 2:
            continue

        filename, file_type = parts

        if is_shell_script(file_type):
            print(filename)


if __name__ == "__main__":
    main()
