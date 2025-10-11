package install

import "testing"

func Test_getTargetPath(t *testing.T) {
	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		headerName  string
		installPath string
		want        string
		want2       bool // true means skip/error, false means success
	}{
		{
			name:        "valid nested path",
			headerName:  "archive/src/main.go",
			installPath: "/tmp/install",
			want:        "/tmp/install/src/main.go",
			want2:       false,
		},
		{
			name:        "valid deeply nested path",
			headerName:  "project/lib/utils/helper.go",
			installPath: "/opt/myapp",
			want:        "/opt/myapp/lib/utils/helper.go",
			want2:       false,
		},
		{
			name:        "top-level directory only - should skip",
			headerName:  "archive",
			installPath: "/tmp/install",
			want:        "",
			want2:       true,
		},
		{
			name:        "top-level directory with slash - creates empty relPath",
			headerName:  "archive/",
			installPath: "/tmp/install",
			want:        "/tmp/install",
			want2:       false,
		},
		{
			name:        "absolute path in archive - should skip",
			headerName:  "archive//absolute/path",
			installPath: "/tmp/install",
			want:        "",
			want2:       true,
		},
		{
			name:        "path traversal with .. - should skip",
			headerName:  "archive/../../../etc/passwd",
			installPath: "/tmp/install",
			want:        "",
			want2:       true,
		},
		{
			name:        "path traversal in middle - should skip",
			headerName:  "archive/src/../../../sensitive",
			installPath: "/tmp/install",
			want:        "",
			want2:       true,
		},
		{
			name:        "relative path with single dot - filepath.Join cleans it",
			headerName:  "archive/./config.json",
			installPath: "/tmp/install",
			want:        "/tmp/install/config.json",
			want2:       false,
		},
		{
			name:        "empty header name - should skip",
			headerName:  "",
			installPath: "/tmp/install",
			want:        "",
			want2:       true,
		},
		{
			name:        "root install path - path safety check fails",
			headerName:  "archive/bin/app",
			installPath: "/",
			want:        "",
			want2:       true,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, got2 := getTargetPath(tt.headerName, tt.installPath)
			if got != tt.want {
				t.Errorf("getTargetPath() path = %v, want %v", got, tt.want)
			}
			if got2 != tt.want2 {
				t.Errorf("getTargetPath() skip = %v, want %v", got2, tt.want2)
			}
		})
	}
}
