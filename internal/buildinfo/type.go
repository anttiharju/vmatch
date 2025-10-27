package buildinfo

type BuildInfo struct {
	revision string
	version  string
	time     string
}

func (b BuildInfo) Revision() string {
	return b.revision
}

func (b BuildInfo) Version() string {
	return b.version
}

func (b BuildInfo) Time() string {
	return b.time
}

func New(revision, version, time string) BuildInfo {
	return BuildInfo{
		revision: revision,
		version:  version,
		time:     time,
	}
}
