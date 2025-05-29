package linter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/find"
	"github.com/anttiharju/vmatch/pkg/wrapper"
)

type WrappedLinter struct {
	wrapper.BaseWrapper
}

func linterParser(content []byte) (string, error) {
	trimmed := strings.TrimSpace(string(content))

	return trimmed, nil
}

var versionPattern = regexp.MustCompile(`^\d+\.\d+\.\d+$`) // major.minor.patch

func validateVersion(version string) (string, error) {
	if !versionPattern.MatchString(version) {
		return "", fmt.Errorf("invalid version format '%s'", version)
	}

	return version, nil
}

func Wrap(name string) *WrappedLinter {
	baseWrapper := wrapper.BaseWrapper{Name: name}

	desiredVersion, err := find.Version(".golangci-version", linterParser, validateVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.VersionReadFileIssue, err.Error())
	}

	err = baseWrapper.GenerateInstallPath(desiredVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.InstallPathIssue, err.Error())
	}

	return &WrappedLinter{
		BaseWrapper: baseWrapper,
	}
}

func (w *WrappedLinter) Run(_ context.Context, args []string) int {
	if w.noBinary() {
		w.install()
	}

	//nolint:gosec // I don't think a wrapper can avoid G204.
	linter := exec.Command(w.getGolangCILintPath(), args...)

	linter.Stdin = os.Stdin
	linter.Stdout = os.Stdout
	linter.Stderr = os.Stderr

	_ = linter.Run()

	return linter.ProcessState.ExitCode()
}

func (w *WrappedLinter) noBinary() bool {
	_, err := os.Stat(w.getGolangCILintPath())

	return os.IsNotExist(err)
}

func (w *WrappedLinter) install() {
	//nolint:lll // Install command example from https://golangci-lint.run/welcome/install/#binaries
	// curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1
	// todo: pin to a sha instead of HEAD, but automate updates
	curl := "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh"
	pipe := " | "
	sh := "sh -s -- -b "
	command := curl + pipe + sh + w.InstallPath + " v" + w.DesiredVersion
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
	return w.InstallPath + string(os.PathSeparator) + "golangci-lint"
}

var _ wrapper.Interface = (*WrappedLinter)(nil)
