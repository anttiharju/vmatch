package install

import "testing"

func Test_getTargetPath(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string // description of this test case
		// Named input parameters for target function.
		headerName  string
		installPath string
		result      string
		shouldSkip  bool // true means success, false means skip/error
	}{
		{
			name:        "valid nested path",
			headerName:  "archive/src/main.go",
			installPath: "/tmp/install",
			result:      "/tmp/install/src/main.go",
			shouldSkip:  true,
		},
		{
			name:        "valid deeply nested path",
			headerName:  "project/lib/utils/helper.go",
			installPath: "/opt/myapp",
			result:      "/opt/myapp/lib/utils/helper.go",
			shouldSkip:  true,
		},
		{
			name:        "top-level directory only - should skip",
			headerName:  "archive",
			installPath: "/tmp/install",
			result:      "",
			shouldSkip:  false,
		},
		{
			name:        "top-level directory with slash - creates empty relPath",
			headerName:  "archive/",
			installPath: "/tmp/install",
			result:      "/tmp/install",
			shouldSkip:  true,
		},
		{
			name:        "absolute path in archive - should skip",
			headerName:  "archive//absolute/path",
			installPath: "/tmp/install",
			result:      "",
			shouldSkip:  false,
		},
		{
			name:        "path traversal with .. - should skip",
			headerName:  "archive/../../../etc/passwd",
			installPath: "/tmp/install",
			result:      "",
			shouldSkip:  false,
		},
		{
			name:        "path traversal in middle - should skip",
			headerName:  "archive/src/../../../sensitive",
			installPath: "/tmp/install",
			result:      "",
			shouldSkip:  false,
		},
		{
			name:        "relative path with single dot - filepath.Join cleans it",
			headerName:  "archive/./config.json",
			installPath: "/tmp/install",
			result:      "/tmp/install/config.json",
			shouldSkip:  true,
		},
		{
			name:        "empty header name - should skip",
			headerName:  "",
			installPath: "/tmp/install",
			result:      "",
			shouldSkip:  false,
		},
		{
			name:        "root install path - path safety check fails",
			headerName:  "archive/bin/app",
			installPath: "/",
			result:      "",
			shouldSkip:  false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			path, skip := getTargetPath(tt.headerName, tt.installPath)
			if path != tt.result {
				t.Errorf("getTargetPath() path = %v, want %v", path, tt.result)
			}

			if skip == tt.shouldSkip {
				t.Errorf("getTargetPath() skip = %v, want %v (expected valid = %v)", skip, !tt.shouldSkip, tt.shouldSkip)
			}
		})
	}
}
