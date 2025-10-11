package install

import "testing"

func Test_getTargetPath(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		headerName  string
		installPath string
		want        string
		valid       bool // true means success, false means skip/error
	}{
		{
			name:        "valid nested path",
			headerName:  "archive/src/main.go",
			installPath: "/tmp/install",
			want:        "/tmp/install/src/main.go",
			valid:       true,
		},
		{
			name:        "valid deeply nested path",
			headerName:  "project/lib/utils/helper.go",
			installPath: "/opt/myapp",
			want:        "/opt/myapp/lib/utils/helper.go",
			valid:       true,
		},
		{
			name:        "top-level directory only - should skip",
			headerName:  "archive",
			installPath: "/tmp/install",
			want:        "",
			valid:       false,
		},
		{
			name:        "top-level directory with slash - creates empty relPath",
			headerName:  "archive/",
			installPath: "/tmp/install",
			want:        "/tmp/install",
			valid:       true,
		},
		{
			name:        "absolute path in archive - should skip",
			headerName:  "archive//absolute/path",
			installPath: "/tmp/install",
			want:        "",
			valid:       false,
		},
		{
			name:        "path traversal with .. - should skip",
			headerName:  "archive/../../../etc/passwd",
			installPath: "/tmp/install",
			want:        "",
			valid:       false,
		},
		{
			name:        "path traversal in middle - should skip",
			headerName:  "archive/src/../../../sensitive",
			installPath: "/tmp/install",
			want:        "",
			valid:       false,
		},
		{
			name:        "relative path with single dot - filepath.Join cleans it",
			headerName:  "archive/./config.json",
			installPath: "/tmp/install",
			want:        "/tmp/install/config.json",
			valid:       true,
		},
		{
			name:        "empty header name - should skip",
			headerName:  "",
			installPath: "/tmp/install",
			want:        "",
			valid:       false,
		},
		{
			name:        "root install path - path safety check fails",
			headerName:  "archive/bin/app",
			installPath: "/",
			want:        "",
			valid:       false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, got2 := getTargetPath(tt.headerName, tt.installPath)
			if got != tt.want {
				t.Errorf("getTargetPath() path = %v, want %v", got, tt.want)
			}

			if got2 == tt.valid {
				t.Errorf("getTargetPath() skip = %v, want %v (expected valid = %v)", got2, !tt.valid, tt.valid)
			}
		})
	}
}
