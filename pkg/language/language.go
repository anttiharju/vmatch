package language

import (
	"archive/tar"
	"compress/gzip"
	"context"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"time"

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

// No patch as tools like stringer mandate not having it.
var versionPattern = regexp.MustCompile(`^\d+\.\d+(?:\.\d+)?$`) // major.minor or major.minor.patch

func validateVersion(version string) (string, error) {
	if !versionPattern.MatchString(version) {
		return "", fmt.Errorf("invalid version format '%s'", version)
	}

	return version, nil
}

func Wrap(name string) *WrappedLanguage {
	baseWrapper := wrapper.BaseWrapper{Name: name}

	desiredVersion, err := finder.GetVersion("go.mod", languageParser, validateVersion)
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

func (w *WrappedLanguage) Run(ctx context.Context, args []string) int {
	if w.noBinary() {
		w.install(ctx)
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

func (w *WrappedLanguage) install(ctx context.Context) {
	goVersion := w.DesiredVersion
	goOS := runtime.GOOS
	goArch := runtime.GOARCH
	installPath := w.InstallPath

	// Ensure install directory exists
	err := os.MkdirAll(installPath, 0o755)
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create install directory: "+err.Error())
	}

	// Download and extract Go
	url := fmt.Sprintf("https://go.dev/dl/go%s.%s-%s.tar.gz", goVersion, goOS, goArch)

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "creating request: "+err.Error())
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to download Go: "+err.Error())
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		msg := fmt.Sprintf("failed to download Go: received status code %d", resp.StatusCode)
		w.ExitWithPrint(exitcode.CmdStartIssue, msg)
	}

	// Decompress and extract tar.gz
	gzr, err := gzip.NewReader(resp.Body)
	if err != nil {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create gzip reader: "+err.Error())
	}
	defer gzr.Close()

	tarReader := tar.NewReader(gzr)

	// Extract files, stripping the top-level directory
	for {
		header, err := tarReader.Next()
		if errors.Is(err, io.EOF) {
			break
		}

		if err != nil {
			w.ExitWithPrint(exitcode.CmdStartIssue, "error extracting tar archive: "+err.Error())
		}

		// Skip the top-level directory by removing the first path component
		parts := strings.SplitN(header.Name, "/", 2)
		if len(parts) < 2 {
			continue // Skip if there's no second part (top-level directory itself)
		}

		target := filepath.Join(installPath, parts[1])

		switch header.Typeflag {
		case tar.TypeDir:
			// Create directory
			err = os.MkdirAll(target, 0o755)
			if err != nil {
				w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create directory: "+err.Error())
			}
		case tar.TypeReg:
			// Create file
			dir := filepath.Dir(target)
			if err := os.MkdirAll(dir, 0o755); err != nil {
				w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create file directory: "+err.Error())
			}

			f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create file: "+err.Error())
			}

			if _, err := io.Copy(f, tarReader); err != nil {
				f.Close()
				w.ExitWithPrint(exitcode.CmdStartIssue, "failed to write file: "+err.Error())
			}

			f.Close()
		}
	}

	// Verify installation
	if w.noBinary() {
		w.ExitWithPrint(exitcode.CmdStartIssue, "failed to install Go: binary not found after installation")
	}
}

func (w *WrappedLanguage) getGoPath() string {
	return w.InstallPath + string(os.PathSeparator) + "bin" + string(os.PathSeparator) + "go"
}

var _ wrapper.Interface = (*WrappedLanguage)(nil)
