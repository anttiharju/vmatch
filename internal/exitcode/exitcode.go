package exitcode

type Exitcode int

const (
	Success Exitcode = iota
	Interrupt
	NoGo
	GoPathIssue
	BinPathIssue
	WorkDirIssue
	VersionReadFileIssue
	VersionIssue
	VersionValidationIssue
	CMDStartIssue
	CMDFindIssue
	CMDWaitIssue
	UserHomeDirIssue
	InstallPathIssue
	VersionError
	CLIError
	ShimHomeError
	ShimCreateError
	ShimDirError
	DoctorError
)
