package symlinks

import (
	"fmt"
	"go/build"
	"os"
	"path/filepath"
	"strings"

	"github.com/anttiharju/vmatch/internal/scripts"
)

//nolint:cyclop,funlen
func Maintain() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		fmt.Printf("Error getting user home directory: %v\n", err)

		return 1
	}

	// Create ~/.vmatch/bin if it doesn't exist
	vmatchDir := filepath.Join(homeDir, ".vmatch", "bin")
	fmt.Printf("Ensuring vmatch directory exists: %s...\n", vmatchDir)

	err = os.MkdirAll(vmatchDir, 0o755)
	if err != nil {
		fmt.Printf("Error creating directory %s: %v\n", vmatchDir, err)

		return 1
	}

	// Get GOPATH/bin
	goPath := build.Default.GOPATH
	goBinDir := filepath.Join(goPath, "bin")
	fmt.Printf("GOPATH bin directory: %s\n", goBinDir)

	// Check if bin directory exists
	if _, err := os.Stat(goBinDir); os.IsNotExist(err) {
		fmt.Printf("Directory %s does not exist\n", goBinDir)

		return 1
	}

	// Read all entries in the GOPATH/bin directory
	entries, err := os.ReadDir(goBinDir)
	if err != nil {
		fmt.Printf("Error reading directory %s: %v\n", goBinDir, err)

		return 1
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
		fmt.Printf("Error reading directory %s: %v\n", vmatchDir, err)

		return 1
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
		} else {
			fmt.Printf("Removed: %s\n", filePath)
		}
	}

	// Create symlinks for binaries from GOPATH/bin to ~/.vmatch/bin
	fmt.Printf("Creating symlinks in %s...\n", vmatchDir)

	for _, binary := range binaries {
		sourcePath := filepath.Join(goBinDir, binary)
		targetPath := filepath.Join(vmatchDir, binary)

		// Remove existing symlink if it exists
		_ = os.Remove(targetPath)

		// Create new symlink
		err := os.Symlink(sourcePath, targetPath)
		if err != nil {
			fmt.Printf("Error creating symlink for %s: %v\n", binary, err)
		} else {
			fmt.Printf("Created symlink: %s -> %s\n", targetPath, sourcePath)
		}
	}

	return 0
}
