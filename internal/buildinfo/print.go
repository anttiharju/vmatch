package buildinfo

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
)

func Print(info BuildInfo) exitcode.Exitcode {
	if buildInfo, ok := debug.ReadBuildInfo(); ok {
		version := strings.TrimPrefix(buildInfo.Main.Version, "v")
		goVersion := buildInfo.GoVersion

		var revision, buildTime string

		for _, setting := range buildInfo.Settings {
			switch setting.Key {
			case "vcs.revision":
				revision = setting.Value
			case "vcs.time":
				buildTime = setting.Value
			}
		}

		infoRev := info.Revision()
		if infoRev != "" {
			revision = infoRev
		}

		infoVersion := info.Version()
		if infoVersion != "" {
			version = infoVersion
		}

		infoTime := info.Time()
		if infoTime != "" {
			buildTime = infoTime
		}

		const maxLength = 8
		if len(revision) > maxLength {
			revision = revision[:maxLength]
		}

		programName := filepath.Base(os.Args[0])
		fmt.Printf("%s has version %s built with %s from %s on %s\n", programName, version, goVersion, revision, buildTime)
	} else {
		return exitcode.VersionError
	}

	return exitcode.Success
}
