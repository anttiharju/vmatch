package symlinks

import (
	"fmt"
	"os"
)

func Maintain() int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return 1
	}

	binDir := homeDir + string(os.PathSeparator) + "bin"
	fmt.Printf("Creating symlinks in %s...\n", binDir)

	return 0
}
