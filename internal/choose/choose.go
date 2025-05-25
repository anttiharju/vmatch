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
	exitCode := inject.Scripts()
	if exitCode != 0 {
		return exitCode
	}

	if firstArgIs("go", args) {
		wrappedLanguage := language.Wrap("go")

		return wrappedLanguage.Run(ctx, args[1:])
	}

	if firstArgIs("golangci-lint", args) {
		wrappedLinter := linter.Wrap("golangci-lint")

		return wrappedLinter.Run(ctx, args[1:])
	}

	return 1
}
