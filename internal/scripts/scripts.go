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
	Golang       Script = "go"
	GolangCILint Script = "golangci-lint"
)

func Scripts() []Script {
	return []Script{Golang, GolangCILint}
}

func (s Script) File() string {
	switch s {
	case Golang:
		return "go.sh"
	case GolangCILint:
		return "golangci-lint.sh"
	default:
		return ""
	}
}

func exists(path string) bool {
	_, err := os.Stat(path)

	return err == nil
}

func Inject() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: failed to get home directory: %v\n", err)

		return 1
	}

	binDir := filepath.Join(homeDir, ".vmatch", "bin")
	if !exists(binDir) {
		if err := os.MkdirAll(binDir, 0o755); err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to create directory %s: %v\n", binDir, err)

			return 1
		}
	}

	scripts := Scripts()
	for _, script := range scripts {
		if err := createScript(binDir, script); err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to create script %s: %v\n", script, err)

			return 1
		}
	}

	return 0
}

//go:embed go.sh golangci-lint.sh
var scripts embed.FS

func createScript(binDir string, script Script) error {
	name := string(script)
	sourcePath := script.File()
	destPath := filepath.Join(binDir, string(script))

	if exists(destPath) {
		return nil
	}

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
