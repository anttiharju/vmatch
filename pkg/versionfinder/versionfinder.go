package versionfinder

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func GetVersion(filename string) (string, error) {
	workDir, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("cannot get current working directory: %w", err)
	}

	for {
		filePath := filepath.Join(workDir, filename)
		if _, err := os.Stat(filePath); err == nil {
			content, err := os.ReadFile(filePath)
			if err != nil {
				return "", fmt.Errorf("cannot read version file '%s': %w", filePath, err)
			}

			rawContent := strings.TrimSpace(string(content))

			return validate(rawContent)
		}

		parentDir := filepath.Dir(workDir)
		if parentDir == workDir {
			break
		}

		workDir = parentDir
	}

	return "", fmt.Errorf("cannot find version file '%s'", filename)
}

var versionPattern = regexp.MustCompile(`^\d+\.\d+\.\d+$`)

func validate(version string) (string, error) {
	if !versionPattern.MatchString(version) {
		return "", fmt.Errorf("invalid version format '%s'", version)
	}

	return version, nil
}
