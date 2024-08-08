package exitcode

const (
	Success = iota
	Interrupt
	NoGo
	GoPathIssue
	BinPathIssue
	WorkDirIssue
	VersionReadFileIssue
	VersionIssue
	VersionValidationIssue
	CmdStartIssue
	CmdWaitIssue
)
