package doctor

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

func Diagnose() int {
	// Get user home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("❌ Error getting home directory: %v\n", err)

		return 1
	}

	// Define expected paths
	binDir := filepath.Join(homeDir, ".vmatch", "bin")
	expectedPaths := map[string]string{
		"go":               filepath.Join(binDir, "go"),
		"golangci-lint":    filepath.Join(binDir, "golangci-lint"),
		"golangci-lint-v2": filepath.Join(binDir, "golangci-lint-v2"),
	}

	// Check each tool
	healthy := true

	for tool, expectedPath := range expectedPaths {
		actualPath, err := exec.LookPath(tool)
		if err != nil {
			fmt.Printf("❌ %s: Not found in PATH\n", tool)

			healthy = false

			continue
		}

		// Normalize paths (resolve symlinks if necessary)
		actualPath, err = filepath.EvalSymlinks(actualPath)
		if err != nil {
			fmt.Printf("❌ %s: Error resolving path: %v\n", tool, err)

			healthy = false

			continue
		}

		if actualPath != expectedPath {
			fmt.Printf("❌ %s: Found at %s, but expected %s\n", tool, actualPath, expectedPath)

			healthy = false
		}
	}

	if !healthy {
		//nolint:lll
		fmt.Printf("\n⚠️  vmatch is not installed correctly! Add '%s' to PATH with one of the following commands:\n\n", binDir)
		fmt.Printf("zsh 🍎\n")
		fmt.Printf(" echo 'export PATH=\"%s:$PATH\"' >> ~/.zshrc && source ~/.zshrc\n\n", binDir)
		fmt.Printf("bash 🐧\n")
		fmt.Printf(" echo 'export PATH=\"%s:$PATH\"' >> ~/.bashrc && source ~/.bashrc\n\n", binDir)
		fmt.Printf("fish 🐟\n")
		fmt.Printf(" fish_add_path %s\n\n", binDir)
		fmt.Printf("And run 'vmatch doctor' again to verify your setup.\n")

		return 0 // We don't want to fail the command, just inform the user
	}

	fmt.Println("✅ vmatch installation is healthy.")

	return 0
}
