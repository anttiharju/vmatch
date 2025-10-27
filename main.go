package main

import (
	"context"
	"os"

	"github.com/anttiharju/vmatch/internal/buildinfo"
	"github.com/anttiharju/vmatch/internal/choose"
	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/interrupt"
)

var (
	revision string
	version  string
	time     string
)

func main() {
	go interrupt.Listen(exitcode.Interrupt, os.Interrupt)

	ctx := context.Background()
	exitCode := choose.Wrapper(ctx, buildinfo.New(revision, version, time), os.Args[1:])
	os.Exit(exitCode)
}
