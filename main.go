package main

import (
	"context"
	"os"

	"github.com/anttiharju/vmatch/pkg/interrupt"
	"github.com/anttiharju/vmatch/pkg/picker"
)

func main() {
	go interrupt.Listen(os.Interrupt)

	ctx := context.Background()
	exitCode := picker.SelectWrapper(ctx, os.Args[1:])

	os.Exit(exitCode)
}
