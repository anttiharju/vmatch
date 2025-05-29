package wrapper

import (
	"context"
	"fmt"
	"os"
)

type wrapperInterface interface {
	Run(ctx context.Context, args []string) int
	Exit(code int)
	ExitWithPrint(code int, msg string)
	ExitWithPrintln(code int, msg string)
	GenerateInstallPath(version string) error
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

func (w *BaseWrapper) GenerateInstallPath(version string) error {
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
