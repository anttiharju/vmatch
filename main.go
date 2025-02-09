package main

import (
	"context"
	"os"
	"os/signal"

	"github.com/anttiharju/vmatch/pkg/exitcode"
	"github.com/anttiharju/vmatch/pkg/linter"
	"github.com/anttiharju/vmatch/pkg/wrapper"
)

func main() {
	ctx := context.Background()

	wrappedLinter := linter.NewWrapper("vmatch-golangci-lint")
	go listenInterrupts(wrappedLinter)
	exitCode := wrappedLinter.Run(ctx)
	wrappedLinter.Exit(exitCode)
}

func listenInterrupts(w wrapper.Interface) {
	interruptCh := make(chan os.Signal, 1)
	signal.Notify(interruptCh, os.Interrupt)
	<-interruptCh
	w.ExitWithPrintln(exitcode.Interrupt, "Interrupted")
}
