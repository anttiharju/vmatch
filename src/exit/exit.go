package exit

import (
	"fmt"
	"os"
)

//nolint:gochecknoglobals
var appName string // provided via build.sh

const infix = ": "

// os.Exit doesn't respect defers so it's kind of neat to wrap it in a package to avoid the footgun

func Now(exitCode int) {
	os.Exit(exitCode)
}

func WithNewlineMessage(exitCode int, message string) {
	fmt.Println("\n" + appName + infix + message)
	os.Exit(exitCode)
}

func WithMessage(exitCode int, message string) {
	fmt.Print(appName + infix + message)
	os.Exit(exitCode)
}
