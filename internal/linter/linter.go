package linter

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/shims"
	"github.com/anttiharju/vmatch/internal/wrapper"
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

func Wrap(shim shims.Shim) *WrappedLinter {
	baseWrapper := wrapper.BaseWrapper{Name: string(shim)}

	err := baseWrapper.GenerateInstallPath(".golangci-version", linterParser, validateVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.InstallPathIssue, err.Error())
	}

	return &WrappedLinter{
		BaseWrapper: baseWrapper,
	}
}

func (w *WrappedLinter) Run(ctx context.Context, args []string) int {
	if w.noBinary() {
		w.install(ctx)
	}

	//nolint:gosec // I don't think a wrapper can avoid G204.
	linter := exec.CommandContext(ctx, w.getGolangCILintPath(), args...)

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

func (w *WrappedLinter) install(ctx context.Context) {
	//nolint:lll // Install command example from https://golangci-lint.run/welcome/install/#binaries
	// curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.59.1
	// todo: pin to a sha instead of HEAD, but automate updates
	curl := "curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/cc3567e3127d8530afb69be1b7bd20ba9ebcc7c1/install.sh"
	pipe := " | "
	sh := "sh -s -- -b "
	command := curl + pipe + sh + w.InstallPath + " v" + w.DesiredVersion
	cmd := exec.CommandContext(ctx, "sh", "-c", command)

	err := cmd.Start()
	if err != nil {
		w.ExitWithPrint(exitcode.CMDStartIssue, "failed to start command: "+err.Error())
	}

	err = cmd.Wait()
	if err != nil {
		w.ExitWithPrint(exitcode.CMDStartIssue, "failed to wait for command: "+err.Error())
	}
}

func (w *WrappedLinter) getGolangCILintPath() string {
	return w.InstallPath + string(os.PathSeparator) + "golangci-lint"
}

var _ wrapper.Interface = (*WrappedLinter)(nil)
