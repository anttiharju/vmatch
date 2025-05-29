package scripts

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

type Script string

const (
	//nolint:varnamelen
	Go             Script = "go"
	GolangCILint   Script = "golangci-lint"
	GolangCILintV2 Script = "golangci-lint-v2"
)

func (s Script) File() string {
	switch s {
	case Go:
		return "go.sh"
	case GolangCILint, GolangCILintV2:
		return "golangci-lint.sh"
	default:
		return ""
	}
}

//go:embed go.sh golangci-lint.sh
var scripts embed.FS

//nolint:cyclop // this is fairly simple and I don't think it needs to be refactored for now
func Inject() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: failed to get home directory: %v\n", err)

		return 1
	}

	binDir := filepath.Join(homeDir, ".vmatch", "bin")
	goPath := filepath.Join(binDir, string(Go))
	lintPath := filepath.Join(binDir, string(GolangCILint))
	lintV2Path := filepath.Join(binDir, string(GolangCILintV2))

	goExists := exists(goPath)
	lintExists := exists(lintPath)
	lintV2Exists := exists(lintV2Path)

	if goExists && lintExists && lintV2Exists {
		return 0
	}

	dirExists := exists(binDir)
	if !dirExists {
		if err := os.MkdirAll(binDir, 0o755); err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to create directory %s: %v\n", binDir, err)

			return 1
		}
	}

	if !goExists {
		if err := createScript(string(Go), Go.File(), goPath); err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)

			return 1
		}
	}

	if !lintExists {
		if err := createScript(string(GolangCILint), GolangCILint.File(), lintPath); err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)

			return 1
		}
	}

	if !lintV2Exists {
		if err := createScript(string(GolangCILintV2), GolangCILintV2.File(), lintV2Path); err != nil {
			fmt.Fprintf(os.Stderr, "%v\n", err)

			return 1
		}
	}

	return 0
}

func exists(path string) bool {
	_, err := os.Stat(path)

	return err == nil
}

// createScript writes an embedded script to the destination path
func createScript(name, sourcePath, destPath string) error {
	content, err := fs.ReadFile(scripts, sourcePath)
	if err != nil {
		return fmt.Errorf("failed to read embedded script %s: %w", name, err)
	}

	//nolint:gosec // using 0o755 instead of 0o600 is intentional here
	if err := os.WriteFile(destPath, content, 0o755); err != nil {
		return fmt.Errorf("failed to write script %s: %w", name, err)
	}

	return nil
}
