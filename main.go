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
	version string
	time    string
	rev     string
)

func main() {
	go interrupt.Listen(exitcode.Interrupt, os.Interrupt)

	ctx := context.Background()
	exitCode := choose.Wrapper(ctx, buildinfo.New(version, time, rev), os.Args[1:])
	os.Exit(exitCode)
}
