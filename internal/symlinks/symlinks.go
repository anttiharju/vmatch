package symlinks

import (
	"fmt"
	"go/build"
	"os"
	"path/filepath"
	"strings"

	"github.com/anttiharju/vmatch/internal/shims"
)

func Sync() {
	if err := sync(); err != nil {
		fmt.Printf("vmatch: error during GOPATH/bin symlink sync: %v\n", err)
	}
}

func sync() error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("getting user home directory: %w", err)
	}

	vmatchDir, err := ensureVmatchDirExists(homeDir)
	if err != nil {
		return fmt.Errorf("ensuring vmatch directory exists: %w", err)
	}

	goBinDir, err := getGoBinDir()
	if err != nil {
		return fmt.Errorf("getting Go bin directory: %w", err)
	}

	// If Go bin directory doesn't exist, exit quietly
	if goBinDir == "" {
		return nil
	}

	scriptNames := buildShimNamesMap()

	binaries, err := collectRelevantBinaries(goBinDir, scriptNames)
	if err != nil {
		return fmt.Errorf("collecting relevant binaries: %w", err)
	}

	if err := cleanVmatchBinDirectory(vmatchDir, scriptNames); err != nil {
		return fmt.Errorf("cleaning vmatch bin directory: %w", err)
	}

	if err := createSymlinksForBinaries(goBinDir, vmatchDir, binaries); err != nil {
		return fmt.Errorf("creating symlinks for binaries: %w", err)
	}

	return nil
}

func ensureVmatchDirExists(homeDir string) (string, error) {
	vmatchDir := filepath.Join(homeDir, ".vmatch", "bin")

	err := os.MkdirAll(vmatchDir, 0o755)
	if err != nil {
		return "", fmt.Errorf("creating directory %s: %w", vmatchDir, err)
	}

	return vmatchDir, nil
}

func getGoBinDir() (string, error) {
	goPath := build.Default.GOPATH
	goBinDir := filepath.Join(goPath, "bin")

	if _, err := os.Stat(goBinDir); os.IsNotExist(err) {
		return "", nil // Return empty string and no error if directory doesn't exist
	} else if err != nil {
		return "", fmt.Errorf("checking Go bin directory: %w", err)
	}

	return goBinDir, nil
}

func buildShimNamesMap() map[string]bool {
	shimNames := make(map[string]bool)
	for _, shim := range shims.Shims() {
		shimNames[string(shim)] = true
	}

	return shimNames
}

func collectRelevantBinaries(goBinDir string, shimNames map[string]bool) ([]string, error) {
	entries, err := os.ReadDir(goBinDir)
	if err != nil {
		return nil, fmt.Errorf("reading directory %s: %w", goBinDir, err)
	}

	binaries := make([]string, 0, len(entries))

	for _, entry := range entries {
		if shouldIncludeBinary(entry.Name(), shimNames) {
			binaries = append(binaries, entry.Name())
		}
	}

	return binaries, nil
}

func shouldIncludeBinary(name string, shimtNames map[string]bool) bool {
	// Skip hidden files (files starting with a dot)
	if strings.HasPrefix(name, ".") {
		return false
	}

	// Skip files that match shim names
	if shimtNames[name] {
		return false
	}

	return true
}

func cleanVmatchBinDirectory(vmatchDir string, shimNames map[string]bool) error {
	entries, err := os.ReadDir(vmatchDir)
	if err != nil {
		return fmt.Errorf("reading directory %s: %w", vmatchDir, err)
	}

	for _, entry := range entries {
		// Skip if it's a shim we want to keep
		if shimNames[entry.Name()] {
			continue
		}

		// Remove other files
		filePath := filepath.Join(vmatchDir, entry.Name())
		if err := os.Remove(filePath); err != nil {
			return fmt.Errorf("removing file %s: %w", filePath, err)
		}
	}

	return nil
}

func createSymlinksForBinaries(goBinDir, vmatchDir string, binaries []string) error {
	for _, binary := range binaries {
		sourcePath := filepath.Join(goBinDir, binary)
		targetPath := filepath.Join(vmatchDir, binary)

		// Create new symlink
		if err := os.Symlink(sourcePath, targetPath); err != nil {
			return fmt.Errorf("creating symlink for %s: %w", binary, err)
		}
	}

	return nil
}
