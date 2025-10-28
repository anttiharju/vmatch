package cli

import (
	"context"

	"github.com/anttiharju/vmatch/internal/buildinfo"
	"github.com/anttiharju/vmatch/internal/doctor"
	"github.com/anttiharju/vmatch/internal/exitcode"
	"github.com/anttiharju/vmatch/internal/language"
	"github.com/anttiharju/vmatch/internal/linter"
	"github.com/anttiharju/vmatch/internal/shims"
	"github.com/anttiharju/vmatch/internal/symlinks"
)

func firstArgIs(arg string, args []string) bool {
	return len(args) > 0 && args[0] == arg
}

func Start(ctx context.Context, info buildinfo.BuildInfo, args []string) exitcode.Exitcode {
	exitCode := shims.Inject()
	if exitCode != 0 {
		return exitCode
	}

	defer func() {
		symlinks.Sync()
	}()

	if firstArgIs(string(shims.Golang), args) {
		wrappedLanguage := language.Wrap(shims.Golang)

		return exitcode.Exitcode(wrappedLanguage.Run(ctx, args[1:]))
	}

	if firstArgIs(string(shims.GolangCILint), args) {
		wrappedLinter := linter.Wrap(shims.GolangCILint)

		return exitcode.Exitcode(wrappedLinter.Run(ctx, args[1:]))
	}

	if firstArgIs("version", args) {
		return buildinfo.Print(info)
	}

	if firstArgIs("doctor", args) {
		return doctor.Diagnose()
	}

	return exitcode.CLIError
}
