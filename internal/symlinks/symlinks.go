package symlinks

import (
	"fmt"
	"go/build"
	"os"
	"path/filepath"
	"strings"

	"github.com/anttiharju/vmatch/internal/scripts"
)

func Sync() {
	if err := sync(); err != nil {
		fmt.Printf("Error during sync: %v\n", err)
	}
}

//nolint:cyclop,funlen
func sync() error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("getting user home directory: %w", err)
	}

	// Create ~/.vmatch/bin if it doesn't exist
	vmatchDir := filepath.Join(homeDir, ".vmatch", "bin")

	err = os.MkdirAll(vmatchDir, 0o755)
	if err != nil {
		return fmt.Errorf("creating directory %s: %w", vmatchDir, err)
	}

	// Get GOPATH/bin
	goPath := build.Default.GOPATH
	goBinDir := filepath.Join(goPath, "bin")

	// Check if bin directory exists
	if _, err := os.Stat(goBinDir); os.IsNotExist(err) {
		return fmt.Errorf("directory %s does not exist", goBinDir)
	}

	// Read all entries in the GOPATH/bin directory
	entries, err := os.ReadDir(goBinDir)
	if err != nil {
		return fmt.Errorf("reading directory %s: %w", goBinDir, err)
	}

	// Get the list of scripts to filter out
	scriptsList := scripts.Scripts()

	scriptNames := make(map[string]bool)
	for _, script := range scriptsList {
		scriptNames[string(script)] = true
	}

	// Collect relevant binaries
	binaries := make([]string, 0, len(entries))

	for _, entry := range entries {
		// Skip hidden files (files starting with a dot)
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		// Skip files that match script names
		if scriptNames[entry.Name()] {
			continue
		}

		binaries = append(binaries, entry.Name())
	}

	// Clean up ~/.vmatch/bin - remove files that aren't in scripts.Scripts()
	vmatchEntries, err := os.ReadDir(vmatchDir)
	if err != nil {
		return fmt.Errorf("reading directory %s: %w", vmatchDir, err)
	}

	for _, entry := range vmatchEntries {
		// Skip if it's a script we want to keep
		if scriptNames[entry.Name()] {
			continue
		}

		// Remove other files
		filePath := filepath.Join(vmatchDir, entry.Name())

		err := os.Remove(filePath)
		if err != nil {
			fmt.Printf("Error removing file %s: %v\n", filePath, err)
		}
	}

	for _, binary := range binaries {
		sourcePath := filepath.Join(goBinDir, binary)
		targetPath := filepath.Join(vmatchDir, binary)

		// Remove existing symlink if it exists
		_ = os.Remove(targetPath)

		// Create new symlink
		err := os.Symlink(sourcePath, targetPath)
		if err != nil {
			fmt.Printf("Error creating symlink for %s: %v\n", binary, err)
		}
	}

	return nil
}
