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

	defer func() {
		symlinks.Maintain()
	}()

	if firstArgIs(string(scripts.Golang), args) {
		wrappedLanguage := language.Wrap(scripts.Golang)

		return wrappedLanguage.Run(ctx, args[1:])
	}

	if firstArgIs(string(scripts.GolangCILint), args) {
		wrappedLinter := linter.Wrap(scripts.GolangCILint)

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
