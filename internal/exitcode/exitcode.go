package exitcode

type Exitcode int

const (
	Success Exitcode = iota
	Interrupt
	CMDStartError
	CMDInstallError
	CMDFindError
	CMDWaitError
	InstallPathError
	VersionError
	CLIError
	ShimHomeError
	ShimCreateError
	ShimDirError
	DoctorError
)
