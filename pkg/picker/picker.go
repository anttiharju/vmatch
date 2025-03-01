package picker

import (
	"github.com/anttiharju/vmatch/pkg/wrapper/language"
	"github.com/anttiharju/vmatch/pkg/wrapper/linter"
)

func firstArgIs(arg string, args []string) bool {
	return len(args) > 0 && args[0] == arg
}

func SelectWrapper(args []string) int {
	if firstArgIs("go", args) {
		wrappedLanguage := language.Wrap("go")
		exitCode := wrappedLanguage.Run(args[1:])

		return exitCode
	}

	if firstArgIs("golangci-lint", args) {
		wrappedLinter := linter.Wrap("golangci-lint")
		exitCode := wrappedLinter.Run(args)

		return exitCode
	}

	return 1
}
