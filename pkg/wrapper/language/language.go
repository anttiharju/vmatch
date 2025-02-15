package language

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/anttiharju/vmatch/pkg/exitcode"
	"github.com/anttiharju/vmatch/pkg/finder"
	"github.com/anttiharju/vmatch/pkg/wrapper"
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

func Wrap(name string) *WrappedLanguage {
	baseWrapper := wrapper.BaseWrapper{Name: name}

	desiredVersion, err := finder.GetVersion("go.mod", languageParser)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.VersionReadFileIssue, err.Error())
	}

	err = baseWrapper.GenerateInstallPath(desiredVersion)
	if err != nil {
		baseWrapper.ExitWithPrintln(exitcode.InstallPathIssue, err.Error())
	}

	return &WrappedLanguage{
		BaseWrapper: baseWrapper,
	}
}

func (w *WrappedLanguage) Run(args []string) int {
	if w.noBinary() {
		w.install()
	}

	//nolint:gosec // I don't think a wrapper can avoid G204.
	language := exec.Command(w.getGoPath(), args...)

	languageOutput, _ := language.CombinedOutput()
	fmt.Print(string(languageOutput))

	return language.ProcessState.ExitCode()
}

func (w *WrappedLanguage) noBinary() bool {
	_, err := os.Stat(w.getGoPath())

	return os.IsNotExist(err)
}

func (w *WrappedLanguage) install() {
	//nolint:lll // Install command example:
	// curl -sSfL https://raw.githubusercontent.com/anttiharju/vmatch-go/HEAD/install.sh | sh -s -- 1.23.6 darwin arm64 "$HOME/.vmatch/go/v1.23.6"
	// todo: pin to a sha instead of HEAD, but automate updates
	curl := "curl -sSfL https://raw.githubusercontent.com/anttiharju/vmatch-go/HEAD/install.sh"
	pipe := " | "
	sh := "sh -s -- "
	versionArgs := w.DesiredVersion + " " + runtime.GOOS + " " + runtime.GOARCH + " "
	command := curl + pipe + sh + versionArgs + w.InstallPath
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

func (w *WrappedLanguage) getGoPath() string {
	return w.InstallPath + string(os.PathSeparator) + "bin" + string(os.PathSeparator) + "go"
}

var _ wrapper.Interface = (*WrappedLanguage)(nil)
