package main

import (
	"context"
	"fmt"
	"os"

	"github.com/anttiharju/vmatch/internal/choose"
	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/interrupt"
)

var (
	version string
	_       string
	_       string
)

func main() {
	go interrupt.Listen(exitcode.Interrupt, os.Interrupt)

	fmt.Println(version)

	ctx := context.Background()
	exitCode := choose.Wrapper(ctx, os.Args[1:])
	os.Exit(exitCode)
}
