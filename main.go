package main

import (
	"os"

	"github.com/anttiharju/vmatch/pkg/interrupt"
	"github.com/anttiharju/vmatch/pkg/picker"
)

func main() {
	go interrupt.Listen(os.Interrupt)

	exitCode := picker.SelectWrapper(os.Args[1:])
	os.Exit(exitCode)
}
