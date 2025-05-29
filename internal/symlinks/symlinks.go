package symlinks

import (
	"fmt"
	"go/build"
	"os"
	"path/filepath"
)

func Maintain() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return 1
	}

	binDir := homeDir + string(os.PathSeparator) + "bin"
	fmt.Printf("Creating symlinks in %s...\n", binDir)

	goPath := build.Default.GOPATH
	fmt.Printf("GOPATH: %s\n", goPath)

	// Path to GOPATH/bin directory
	goBinDir := filepath.Join(goPath, "bin")
	fmt.Printf("Listing files in %s:\n", goBinDir)

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

	// Print each entry in the bin directory
	for _, entry := range entries {
		filePath := filepath.Join(goBinDir, entry.Name())

		info, err := entry.Info()
		if err != nil {
			fmt.Printf("%s (error getting info: %v)\n", entry.Name(), err)

			continue
		}

		// Show if it's a symlink, directory or regular file
		fileType := "regular file"
		if entry.IsDir() {
			fileType = "directory"
		} else if info.Mode()&os.ModeSymlink != 0 {
			fileType = "symlink"
			// If it's a symlink, try to read the target
			target, err := os.Readlink(filePath)
			if err == nil {
				fileType = "symlink -> " + target
			}
		}

		fmt.Printf("%s (%s, %d bytes)\n", entry.Name(), fileType, info.Size())
	}

	return 0
}
