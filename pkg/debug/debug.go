package debug

import (
	"os"
	"strings"
)

func getFilePath() string {
	binPath, _ := os.Executable()
	binDir := binPath[:strings.LastIndex(binPath, string(os.PathSeparator))]

	return binDir + string(os.PathSeparator) + "debug.txt"
}

func WriteToFile(s string) {
	bytes := []byte(s)
	ownerOnlyRW := os.FileMode(0o600)
	_ = os.WriteFile(getFilePath(), bytes, ownerOnlyRW)
}
