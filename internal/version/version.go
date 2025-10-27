package version

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
)

func Print() exitcode.Exitcode {
	if buildInfo, ok := debug.ReadBuildInfo(); ok {
		version := strings.TrimPrefix(buildInfo.Main.Version, "v")
		goVersion := buildInfo.GoVersion

		var revision, buildTime string

		for _, setting := range buildInfo.Settings {
			switch setting.Key {
			case "vcs.revision":
				if len(setting.Value) >= 8 {
					revision = setting.Value[:8]
				}
			case "vcs.time":
				buildTime = setting.Value
			}
		}

		if buildTime == "" {
			buildTime = "1970-01-01T00:00:00Z"
		}

		programName := filepath.Base(os.Args[0])
		fmt.Printf("%s has version %s built with %s from %s on %s\n", programName, version, goVersion, revision, buildTime)
	} else {
		return exitcode.VersionError
	}

	return exitcode.Success
}
