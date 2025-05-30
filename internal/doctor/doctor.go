package doctor

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/anttiharju/vmatch/internal/scripts"
)

func Diagnose() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("❌ Error getting home directory: %v\n", err)

		return 1
	}

	binDir := filepath.Join(homeDir, ".vmatch", "bin")
	expectedPaths := map[string]string{
		string(scripts.Golang):       filepath.Join(binDir, string(scripts.Golang)),
		string(scripts.GolangCILint): filepath.Join(binDir, string(scripts.GolangCILint)),
	}

	healthy := true

	_, vmatchErr := exec.LookPath("vmatch")
	if vmatchErr != nil {
		fmt.Println("❌ vmatch: Not found in PATH")

		healthy = false
	}

	for tool, expectedPath := range expectedPaths {
		actualPath, err := exec.LookPath(tool)
		if err != nil {
			fmt.Printf("❌ %s: Not found in PATH\n", tool)

			healthy = false

			continue
		}

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

	inform(binDir, healthy)

	return 0
}

func inform(binDir string, healthy bool) {
	if healthy {
		fmt.Println("✅ vmatch installation is healthy.")
	} else {
		fmt.Printf("\n⚠️  vmatch is not installed correctly!")
		fmt.Printf("\n    Add '%s' to PATH with one of the following commands:\n\n", binDir)
		fmt.Printf("zsh  🍎\n")
		fmt.Printf(" echo 'export PATH=\"%s:$PATH\"' >> ~/.zshrc && source ~/.zshrc\n\n", binDir)
		fmt.Printf("bash 🐧\n")
		fmt.Printf(" echo 'export PATH=\"%s:$PATH\"' >> ~/.bashrc && source ~/.bashrc\n\n", binDir)
		fmt.Printf("fish 🐟\n")
		fmt.Printf(" fish_add_path %s\n\n", binDir)
		fmt.Printf("And run 'vmatch doctor' again to verify your setup.\n")
	}
}
