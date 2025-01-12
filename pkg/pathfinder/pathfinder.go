package pathfinder

import (
	"os"
	"strings"

	"github.com/anttiharju/vmatch/pkg/exit"
	"github.com/anttiharju/vmatch/pkg/exit/exitcode"
)

func GetInstallPath(version string) string {
	homeDir := GetHomeDir()
	ps := string(os.PathSeparator)
	installPath := homeDir + ps + ".vmatch" + ps + "golangci-lint" + ps + "v" + version

	return installPath
}

func GetHomeDir() string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		exit.WithMessage(exitcode.UserHomeDirIssue, "Cannot get user home directory")
	}

	return homeDir
}

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
