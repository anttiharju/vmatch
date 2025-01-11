package pathfinder

import (
	"os"
	"strings"

	"github.com/anttiharju/vmatch-golangci-lint/pkg/exit"
	"github.com/anttiharju/vmatch-golangci-lint/pkg/exit/exitcode"
)

func GetBinDir() string {
	binPath := getBin()
	binDir := binPath[:strings.LastIndex(binPath, string(os.PathSeparator))]

	return binDir
}

func getBin() string {
	binPath, err := os.Executable()
	if err != nil {
		exit.WithMessage(exitcode.BinPathIssue, "Cannot get executable path")
	}

	return binPath
}

func GetWorkDir() string {
	workdir, err := os.Getwd()
	if err != nil {
		exit.WithMessage(exitcode.WorkDirIssue, "Cannot get working directory")
	}

	return workdir
}
