package version

import (
	"fmt"
	"runtime/debug"
)

func Print() int {
	if bi, ok := debug.ReadBuildInfo(); ok {
		version := bi.Main.Version[1:] // remove "v" prefix
		goVersion := bi.GoVersion

		var revision, buildTime string

		for _, setting := range bi.Settings {
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
