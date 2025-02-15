package finder

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
)

type parser func(content []byte) (string, error)

func GetVersion(filename string, parse parser) (string, error) {
	location, err := locateFile(filename)
	if err != nil {
		return "", fmt.Errorf("cannot find version file '%s': %w", filename, err)
	}

	content, err := os.ReadFile(location)
	if err != nil {
		return "", fmt.Errorf("cannot read version file '%s': %w", location, err)
	}

	version, err := parse(content)
	if err != nil {
		return "", fmt.Errorf("could not parse %s: %w", location, err)
	}

	return validateVersion(version)
}

func locateFile(filename string) (string, error) {
	workDir, err := os.Getwd()
	if err != nil {
		return "", fmt.Errorf("cannot get current working directory: %w", err)
	}

	for {
		filePath := filepath.Join(workDir, filename)
		if _, err := os.Stat(filePath); err == nil {
			return filePath, nil
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

func validateVersion(version string) (string, error) {
	if !versionPattern.MatchString(version) {
		return "", fmt.Errorf("invalid version format '%s'", version)
	}

	return version, nil
}
