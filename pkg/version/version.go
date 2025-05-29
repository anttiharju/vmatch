package version

import (
	"fmt"
	"runtime/debug"
	"strings"
)

func Print() int {
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

		fmt.Printf("vmatch has version %s built with %s from %s on %s\n", version, goVersion, revision, buildTime)
	}

	return 0
}
