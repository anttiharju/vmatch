package exitcode

type Exitcode int

const (
	Success Exitcode = iota
	Interrupt
	NoGoError
	GoPathError
	BinPathError
	WorkDirError
	VersionReadFileError
	VersionValidationError
	CMDStartError
	CMDFindError
	CMDWaitError
	UserHomeDirError
	InstallPathError
	VersionError
	CLIError
	ShimHomeError
	ShimCreateError
	ShimDirError
	DoctorError
)
