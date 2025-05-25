package choose

import (
	"context"

	"github.com/anttiharju/vmatch/internal/inject"
	"github.com/anttiharju/vmatch/internal/language"
	"github.com/anttiharju/vmatch/internal/linter"
)

func firstArgIs(arg string, args []string) bool {
	return len(args) > 0 && args[0] == arg
}

func Wrapper(ctx context.Context, args []string) int {
	inject.Scripts()

	if firstArgIs("go", args) {
		wrappedLanguage := language.Wrap("go")
		exitCode := wrappedLanguage.Run(ctx, args[1:])

		return exitCode
	}

	if firstArgIs("golangci-lint", args) {
		wrappedLinter := linter.Wrap("golangci-lint")
		exitCode := wrappedLinter.Run(ctx, args[1:])

		return exitCode
	}

	return 1
}
