package wrapper

import (
	"context"
	"fmt"
	"os"

	"github.com/anttiharju/vmatch/pkg/locate"
)

type wrapperInterface interface {
	Run(ctx context.Context, args []string) int
	Exit(code int)
	ExitWithPrint(code int, msg string)
	ExitWithPrintln(code int, msg string)
	GenerateInstallPath(filename string, parse parser, validate validator) error
}

type Interface interface {
	wrapperInterface
}

type BaseWrapper struct {
	Name           string
	InstallPath    string
	DesiredVersion string
}

// os.Exit() does not respect defer so it's neat to wrap its usage in methods.

func (w *BaseWrapper) Exit(exitCode int) {
	os.Exit(exitCode)
}

func (w *BaseWrapper) ExitWithPrint(exitCode int, message string) {
	fmt.Print("vmatch-" + w.Name + ": " + message)
	os.Exit(exitCode)
}

func (w *BaseWrapper) ExitWithPrintln(exitCode int, message string) {
	fmt.Println("\n" + "vmatch-" + w.Name + ": " + message)
	os.Exit(exitCode)
}

type parser func(content []byte) (string, error)

type validator func(version string) (string, error)

func version(filename string, parse parser, validate validator) (string, error) {
	location, err := locate.File(filename)
	if err != nil {
		return "", fmt.Errorf("cannot find version file '%s': %w", filename, err)
	}

	content, err := os.ReadFile(location)
	if err != nil {
		return "", fmt.Errorf("cannot read version file '%s': %w", location, err)
	}

	version, err := parse(content)
	if err != nil {
		return "", fmt.Errorf("could not parse %s: %w", location, err)
	}

	return validate(version)
}

func (w *BaseWrapper) GenerateInstallPath(filename string, parse parser, validate validator) error {
	version, err := version(filename, parse, validate)
	if err != nil {
		return fmt.Errorf("failed to get version: %w", err)
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get install path: %w", err)
	}

	ps := string(os.PathSeparator)
	installPath := homeDir + ps + ".vmatch" + ps + w.Name + ps + "v" + version

	w.InstallPath = installPath
	w.DesiredVersion = version

	return nil
}

type NewWrapper func(name string) Interface
