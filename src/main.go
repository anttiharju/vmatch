package main

import (
	"context"
	"os"
	"os/signal"

	"github.com/anttiharju/vmatch-golangci-lint/src/app"
	"github.com/anttiharju/vmatch-golangci-lint/src/exit"
	"github.com/anttiharju/vmatch-golangci-lint/src/exit/exitcode"
)

func main() {
	ctx := context.Background()

	go listenInterrupts()

	app := app.NewApp(".golangci-version")
	exitCode := app.Run(ctx)
	exit.Now(exitCode)
}

func listenInterrupts() {
	interruptCh := make(chan os.Signal, 1)
	signal.Notify(interruptCh, os.Interrupt)
	<-interruptCh
	exit.WithNewlineMessage(exitcode.Interrupt, "Interrupted")
}
