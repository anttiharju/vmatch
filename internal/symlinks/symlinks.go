package symlinks

import (
	"fmt"
	"go/build"
	"os"
	"path/filepath"
	"strings"

	"github.com/anttiharju/vmatch/internal/scripts"
)

func Maintain() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return 1
	}

	vmatchDir := filepath.Join(homeDir, ".vmatch", "bin")
	fmt.Printf("Ensuring vmatch directory exists: %s...\n", vmatchDir)

	binDir := homeDir + string(os.PathSeparator) + "bin"
	fmt.Printf("Creating symlinks in %s...\n", binDir)

	goPath := build.Default.GOPATH
	fmt.Printf("GOPATH: %s\n", goPath)

	// Path to GOPATH/bin directory
	goBinDir := filepath.Join(goPath, "bin")
	fmt.Printf("Listing files in %s (excluding hidden files and scripts):\n", goBinDir)

	// Check if bin directory exists
	if _, err := os.Stat(goBinDir); os.IsNotExist(err) {
		fmt.Printf("Directory %s does not exist\n", goBinDir)

		return 1
	}

	// Read all entries in the bin directory
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

	// Print each entry in the bin directory (excluding hidden files and scripts)
	for _, entry := range entries {
		// Skip hidden files (files starting with a dot)
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		// Skip files that match script names
		if scriptNames[entry.Name()] {
			continue
		}

		// Only print the file name
		fmt.Println(entry.Name())
	}

	return 0
}
