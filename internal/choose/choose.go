package choose

import (
	"context"

	"github.com/anttiharju/vmatch/internal/doctor"
	"github.com/anttiharju/vmatch/internal/language"
	"github.com/anttiharju/vmatch/internal/linter"
	"github.com/anttiharju/vmatch/internal/scripts"
	"github.com/anttiharju/vmatch/internal/symlinks"
	"github.com/anttiharju/vmatch/pkg/version"
)

func firstArgIs(arg string, args []string) bool {
	return len(args) > 0 && args[0] == arg
}

func Wrapper(ctx context.Context, args []string) int {
	exitCode := scripts.Inject()
	if exitCode != 0 {
		return exitCode
	}

	exitCode = symlinks.Maintain()
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

	if firstArgIs("version", args) {
		return version.Print()
	}

	if firstArgIs("doctor", args) {
		return doctor.Diagnose()
	}

	return 1
}
