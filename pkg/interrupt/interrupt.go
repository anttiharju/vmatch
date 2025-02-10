package interrupt

import (
	"fmt"
	"os"
	"os/signal"

	"github.com/anttiharju/vmatch/pkg/exitcode"
)

func Listen(signals ...os.Signal) {
	interruptCh := make(chan os.Signal, 1)
	signal.Notify(interruptCh, signals...)
	<-interruptCh
	fmt.Println("\nvmatch: interrupted") // leading \n to have ^C appear on its own line
	os.Exit(exitcode.Interrupt)
}
