package picker

import (
	"context"
	"fmt"
	"runtime"

	"github.com/anttiharju/vmatch/pkg/finder"
	"github.com/anttiharju/vmatch/pkg/linter"
)

func firstArgIsGo(args []string) bool {
	return len(args) > 0 && args[0] == "go"
}

func SelectWrapper(ctx context.Context, args []string) int {
	if firstArgIsGo(args) {
		version, _ := finder.GetLangVersion()
		fmt.Println("https://go.dev/dl/go" + version + "." + runtime.GOOS + "-" + runtime.GOARCH + ".tar.gz")

		return 0
	}

	wrappedLinter := linter.NewWrapper("vmatch-golangci-lint")
	exitCode := wrappedLinter.Run(ctx)

	return exitCode
}
