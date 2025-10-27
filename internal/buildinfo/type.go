package buildinfo

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
