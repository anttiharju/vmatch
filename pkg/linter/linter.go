package linter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"slices"

	"github.com/anttiharju/vmatch/pkg/exitcode"
	"github.com/anttiharju/vmatch/pkg/finder"
	"github.com/anttiharju/vmatch/pkg/wrapper"
)

type WrappedLinter struct {
	wrapper.BaseWrapper
	desiredVersion string
	installPath    string
}

func getInstallPath(version string) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get install path: %w", err)
	}

	ps := string(os.PathSeparator)
	installPath := homeDir + ps + ".vmatch" + ps + "golangci-lint" + ps + "v" + version

	return installPath, nil
}

func NewWrapper(name string) *WrappedLinter {
	baseWrapper := wrapper.BaseWrapper{Name: name}

	desiredVersion, err := finder.GetLinterVersion()
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.VersionReadFileIssue, err.Error())
	}

	installPath, err := getInstallPath(desiredVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.InstallPathIssue, err.Error())
	}

	return &WrappedLinter{
		BaseWrapper:    baseWrapper,
		desiredVersion: desiredVersion,
		installPath:    installPath,
	}
}

func (w *WrappedLinter) Run(ctx context.Context) int {
	if w.noBinary() {
		w.install(ctx)
	}

	args := os.Args[1:]
	if !slices.Contains(args, "--color") {
		args = append(args, "--color", "always")
	}

	//nolint:gosec // I don't think a wrapper can avoid G204.
	linter := exec.Command(w.getGolangCILintPath(), args...)
	linterOutput, _ := linter.Output()

	fmt.Print(string(linterOutput))

	return linter.ProcessState.ExitCode()
}

func (w *WrappedLinter) noBinary() bool {
	_, err := os.Stat(w.getGolangCILintPath())

	return os.IsNotExist(err)
}

func (w *WrappedLinter) install(_ context.Context) {
	//nolint:lll // Official binary install command:
	// curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1
	// todo: pin to a sha instead of master, but automate updates
	curl := "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
	pipe := " | "
	sh := "sh -s -- -b "
	command := curl + pipe + sh + w.installPath + " v" + w.desiredVersion
	cmd := exec.Command("sh", "-c", command)

	err := cmd.Start()
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to start command: "+err.Error())
	}

	err = cmd.Wait()
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to wait for command: "+err.Error())
	}
}

func (w *WrappedLinter) getGolangCILintPath() string {
	return w.installPath + string(os.PathSeparator) + "golangci-lint"
}

var _ wrapper.Interface = (*WrappedLinter)(nil)
