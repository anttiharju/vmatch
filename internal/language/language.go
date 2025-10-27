package language

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"runtime"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/install"
	"github.com/anttiharju/vmatch/internal/shims"
	"github.com/anttiharju/vmatch/internal/wrapper"
)

type WrappedLanguage struct {
	wrapper.BaseWrapper
}

func languageParser(content []byte) (string, error) {
	lines := strings.Split(string(content), "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "go ") {
			trimmed := strings.TrimPrefix(line, "go ")

			return trimmed, nil
		}
	}

	return "", errors.New("cannot find go version")
}

// No patch as tools like stringer mandate not having it.
var versionPattern = regexp.MustCompile(`^\d+\.\d+(?:\.\d+)?$`) // major.minor or major.minor.patch

func validateVersion(version string) (string, error) {
	if !versionPattern.MatchString(version) {
		return "", fmt.Errorf("invalid version format '%s'", version)
	}

	// If the version is in major.minor format, add .0 so that a version can still be downloaded.
	if strings.Count(version, ".") == 1 {
		return version + ".0", nil
	}

	return version, nil
}

func Wrap(script shims.Shim) *WrappedLanguage {
	baseWrapper := wrapper.BaseWrapper{Name: string(script)}

	err := baseWrapper.GenerateInstallPath("go.mod", languageParser, validateVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.InstallPathIssue, err.Error())
	}

	return &WrappedLanguage{
		BaseWrapper: baseWrapper,
	}
}

func (w *WrappedLanguage) Run(ctx context.Context, args []string) int {
	if w.noBinary() {
		w.install(ctx)
	}

	//nolint:gosec // I don't think a wrapper can avoid G204.
	language := exec.CommandContext(ctx, w.getGoPath(), args...)

	language.Stdin = os.Stdin
	language.Stdout = os.Stdout
	language.Stderr = os.Stderr

	_ = language.Run()

	return language.ProcessState.ExitCode()
}

func (w *WrappedLanguage) noBinary() bool {
	_, err := os.Stat(w.getGoPath())

	return os.IsNotExist(err)
}

func (w *WrappedLanguage) install(ctx context.Context) {
	downloadURL := buildDownloadURL(w.DesiredVersion)

	err := install.FromURL(ctx, w.DesiredVersion, downloadURL, w.InstallPath)
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to install Go: "+err.Error())
	}

	if w.noBinary() {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to install Go: binary not found after installation")
	}
}

func buildDownloadURL(version string) string {
	return fmt.Sprintf("https://go.dev/dl/go%s.%s-%s.tar.gz",
		version,
		runtime.GOOS,
		runtime.GOARCH)
}

func (w *WrappedLanguage) getGoPath() string {
	return w.InstallPath + string(os.PathSeparator) + "bin" + string(os.PathSeparator) + "go"
}

var _ wrapper.Interface = (*WrappedLanguage)(nil)
