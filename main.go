package main

import (
	"context"
	"os"

	"github.com/anttiharju/vmatch/pkg/choose"
	"github.com/anttiharju/vmatch/pkg/interrupt"
)

// dummy change
func main() {
	go interrupt.Listen(os.Interrupt)

	ctx := context.Background()
	exitCode := choose.Wrapper(ctx, os.Args[1:])
	os.Exit(exitCode)
}
