package find

import (
	"fmt"
	"os"

	"github.com/anttiharju/vmatch/pkg/locate"
)

type parser func(content []byte) (string, error)

type validator func(version string) (string, error)

func Version(filename string, parse parser, validate validator) (string, error) {
	location, err := locate.File(filename)
	if err != nil {
		return "", fmt.Errorf("cannot find version file '%s': %w", filename, err)
	}

	content, err := os.ReadFile(location)
	if err != nil {
		return "", fmt.Errorf("cannot read version file '%s': %w", location, err)
	}

	version, err := parse(content)
	if err != nil {
		return "", fmt.Errorf("could not parse %s: %w", location, err)
	}

	return validate(version)
}
