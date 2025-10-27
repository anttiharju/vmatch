package buildinfo

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime/debug"
	"strings"

	"github.com/anttiharju/vmatch/internal/exitcode"
)

type BuildInfo struct {
	version string
	time    string
	rev     string
}

func (b BuildInfo) Version() string {
	return b.version
}

func (b BuildInfo) Time() string {
	return b.time
}

func (b BuildInfo) Rev() string {
	return b.rev
}

func New(version, time, rev string) BuildInfo {
	return BuildInfo{
		version: version,
		time:    time,
		rev:     rev,
	}
}

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

		infoVersion := info.Version()
		if infoVersion != "" {
			version = infoVersion
		}
		infoTime := info.Time()
		if infoTime != "" {
			buildTime = infoTime
		}
		infoRev := info.Rev()
		if infoRev != "" {
			revision = infoRev
		}

		revision = revision[:8]

		programName := filepath.Base(os.Args[0])
		fmt.Printf("%s has version %s built with %s from %s on %s\n", programName, version, goVersion, revision, buildTime)
	} else {
		return exitcode.VersionError
	}

	return exitcode.Success
}
