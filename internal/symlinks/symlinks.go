package symlinks

import (
	"fmt"
	"go/build"
	"os"
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

	return 0
}
