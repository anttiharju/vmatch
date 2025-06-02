package interrupt

import (
	"fmt"
	"os"
	"os/signal"
	"path/filepath"

	"github.com/anttiharju/vmatch/internal/exitcode"
)

func Listen(exitcode exitcode.Exitcode, signals ...os.Signal) {
	interruptCh := make(chan os.Signal, 1)
	signal.Notify(interruptCh, signals...)
	<-interruptCh

	programName := filepath.Base(os.Args[0])
	fmt.Printf("\n%s: interrupted\n", programName) // leading \n to have ^C appear on its own line
	os.Exit(int(exitcode))
}
