package main

import (
	"os"

	"github.com/anttiharju/vmatch/pkg/choose"
	"github.com/anttiharju/vmatch/pkg/interrupt"
)

func main() {
	go interrupt.Listen(os.Interrupt)

	exitCode := choose.Wrapper(os.Args[1:])
	os.Exit(exitCode)
}
