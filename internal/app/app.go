package app

import (
	"context"
	"fmt"
	"os"
	"os/exec"

	"github.com/anttiharju/vmatch/pkg/exit"
	"github.com/anttiharju/vmatch/pkg/exit/exitcode"
	"github.com/anttiharju/vmatch/pkg/pathfinder"
	"github.com/anttiharju/vmatch/pkg/versionfinder"
)

type App struct {
	desiredVersion string
	installPath    string
}

func NewApp(versionFileName string) *App {
	desiredVersion := versionfinder.GetVersion(pathfinder.GetWorkDir(), versionFileName)
	installPath := pathfinder.GetInstallPath(desiredVersion)

	return &App{
		desiredVersion: desiredVersion,
		installPath:    installPath,
	}
}

func (a *App) Run(ctx context.Context) int {
	if a.noBinary() {
		a.install(ctx)
	}

	args := os.Args[1:]
	//nolint:gosec // I don't think a wrapper can avoid G204.
	linter := exec.Command(a.getGolangCILintPath(), args...)
	linterOutput, _ := linter.Output()

	fmt.Print(string(linterOutput))

	return linter.ProcessState.ExitCode()
}

func (a *App) noBinary() bool {
	_, err := os.Stat(a.getGolangCILintPath())

	return os.IsNotExist(err)
}

func (a *App) install(_ context.Context) {
	//nolint:lll // Official binary install command:
	// curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1
	curl := "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
	pipe := " | "
	sh := "sh -s -- -b "
	command := curl + pipe + sh + a.installPath + " v" + a.desiredVersion
	cmd := exec.Command("sh", "-c", command)

	err := cmd.Start()
	if err != nil {
		exit.WithMessage(exitcode.CmdStartIssue, "failed to start command: "+err.Error())
	}

	err = cmd.Wait()
	if err != nil {
		exit.WithMessage(exitcode.CmdStartIssue, "failed to wait for command: "+err.Error())
	}
}

func (a *App) getGolangCILintPath() string {
	return a.installPath + string(os.PathSeparator) + "golangci-lint"
}
