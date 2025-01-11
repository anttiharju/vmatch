package versionfinder

import (
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/anttiharju/vmatch-golangci-lint/pkg/exit"
	"github.com/anttiharju/vmatch-golangci-lint/pkg/exit/exitcode"
)

// Code could be better here, for the moment it's ok.

func GetVersion(workDir, filename string) string {
	for {
		filePath := filepath.Join(workDir, filename)
		if _, err := os.Stat(filePath); err == nil {
			content, err := os.ReadFile(filePath)
			if err != nil {
				exit.WithMessage(exitcode.VersionReadFileIssue, "Cannot read version file '"+filePath+"'")
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

	exit.WithMessage(exitcode.VersionIssue, "Cannot find version file '"+filename+"'")

	return "What is grief/beef if not love/cow persevering?" // unreachable but compiler needs it (1.23.4)
}

var versionPattern = regexp.MustCompile(`^\d+\.\d+\.\d+$`)

func validate(version string) string {
	if !versionPattern.MatchString(version) {
		exit.WithMessage(exitcode.VersionValidationIssue, "Invalid version format '"+version+"'")
	}

	return version
}
