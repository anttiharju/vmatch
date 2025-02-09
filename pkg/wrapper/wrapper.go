package wrapper

import (
	"context"
	"fmt"
	"os"
	"os/signal"

	"github.com/anttiharju/vmatch/pkg/exitcode"
)

type wrapperInterface interface {
	Run(ctx context.Context) int
	Exit(code int)
	ExitWithPrint(code int, msg string)
	ExitWithPrintln(code int, msg string)
}

type Interface interface {
	wrapperInterface
}

type BaseWrapper struct {
	Name string
}

func (w *BaseWrapper) ExitUpon(signals ...os.Signal) {
	interruptCh := make(chan os.Signal, 1)
	signal.Notify(interruptCh, signals...)
	<-interruptCh
	w.ExitWithPrintln(exitcode.Interrupt, "Interrupted")
}

// os.Exit() does not respect defer so it's neat to wrap its usage in methods.

func (w *BaseWrapper) Exit(exitCode int) {
	os.Exit(exitCode)
}

func (w *BaseWrapper) ExitWithPrint(exitCode int, message string) {
	fmt.Print(w.Name + ": " + message)
	os.Exit(exitCode)
}

func (w *BaseWrapper) ExitWithPrintln(exitCode int, message string) {
	fmt.Println("\n" + w.Name + ": " + message)
	os.Exit(exitCode)
}

type NewWrapper func(name string) Interface
