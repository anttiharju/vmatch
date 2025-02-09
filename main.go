package main

import (
	"context"
	"os"

	"github.com/anttiharju/vmatch/pkg/linter"
)

func main() {
	wrappedLinter := linter.NewWrapper("vmatch-golangci-lint")
	go wrappedLinter.ExitUpon(os.Interrupt)
	exitCode := wrappedLinter.Run(context.Background())
	wrappedLinter.Exit(exitCode)
}
