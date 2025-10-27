package shims

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"

	"github.com/anttiharju/vmatch/internal/exitcode"
)

type Shim string

const (
	Golang       Shim = "go"
	GolangCILint Shim = "golangci-lint"
)

func Shims() []Shim {
	return []Shim{Golang, GolangCILint}
}

func (s Shim) File() string {
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

func Inject() exitcode.Exitcode {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: failed to get home directory: %v\n", err)

		return exitcode.ScriptsHomeError
	}

	binDir := filepath.Join(homeDir, ".vmatch", "bin")
	if !exists(binDir) {
		if err := os.MkdirAll(binDir, 0o755); err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to create directory %s: %v\n", binDir, err)

			return exitcode.ScriptsCreateError
		}
	}

	scripts := Shims()
	for _, shim := range scripts {
		if err := createShim(binDir, shim); err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to create script %s: %v\n", shim, err)

			return exitcode.ScriptsDirError
		}
	}

	return exitcode.Success
}

//go:embed go.sh golangci-lint.sh
var scripts embed.FS

func createShim(binDir string, script Shim) error {
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
