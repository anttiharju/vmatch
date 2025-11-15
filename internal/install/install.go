package install

import (
	"archive/tar"
	"compress/gzip"
	"context"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func FromURL(ctx context.Context, url, installPath string) error {
	// Ensure install directory exists
	err := os.MkdirAll(installPath, 0o755)
	if err != nil {
		return errors.New("failed to create install directory: " + err.Error())
	}

	// Download the file
	body, err := downloadFile(ctx, url)
	if err != nil {
		// Try with .0 patch version if download fails with 404
		if strings.Contains(err.Error(), "Not Found") {
			retryURL := tryAddPatchVersion(url)
			if retryURL != url {
				body, err = downloadFile(ctx, retryURL)
				if err != nil {
					return errors.New("failed to download to " + installPath + ": " + err.Error())
				}
			} else {
				return errors.New("failed to download to " + installPath + ": " + err.Error())
			}
		} else {
			return errors.New("failed to download to " + installPath + ": " + err.Error())
		}
	}
	defer body.Close()

	// Extract the archive
	err = extractTarGz(body, installPath)
	if err != nil {
		return errors.New("failed to extract: " + err.Error())
	}

	return nil
}

func tryAddPatchVersion(url string) string {
	// Look for patterns like "go1.24.darwin" or "go1.24-darwin"
	// and convert to "go1.24.0.darwin" or "go1.24.0-darwin"

	// Find the version part (e.g., "go1.24")
	if !strings.Contains(url, "/go") {
		return url
	}

	parts := strings.Split(url, "/")
	for i, part := range parts {
		if strings.HasPrefix(part, "go") && len(part) > 2 {
			// Check if it's a version without patch (e.g., "go1.24.darwin-arm64.tar.gz")
			versionPart := part[2:] // Remove "go" prefix

			// Find where the version ends (first non-digit, non-dot character, or a dot followed by non-digit)
			var versionEnd int
			for j := 0; j < len(versionPart); j++ {
				ch := versionPart[j]
				if ch == '.' {
					// Check if next character is a digit
					if j+1 < len(versionPart) && versionPart[j+1] >= '0' && versionPart[j+1] <= '9' {
						continue
					}
					// Dot followed by non-digit (like .darwin), this is the end
					versionEnd = j
					break
				} else if ch < '0' || ch > '9' {
					// Non-digit, non-dot character
					versionEnd = j
					break
				}
			}

			if versionEnd > 0 {
				version := versionPart[:versionEnd]
				remainder := versionPart[versionEnd:]

				// Count dots in version
				dotCount := strings.Count(version, ".")
				if dotCount == 1 {
					// Only major.minor, add .0
					parts[i] = "go" + version + ".0" + remainder
					return strings.Join(parts, "/")
				}
			}
		}
	}

	return url
}

func downloadFile(ctx context.Context, url string) (io.ReadCloser, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return nil, errors.New("failed to create request: " + err.Error())
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, errors.New("failed to fulfill request: " + err.Error())
	}

	if resp.StatusCode != http.StatusOK {
		resp.Body.Close()

		return nil, errors.New("failed with status " + http.StatusText(resp.StatusCode))
	}

	return resp.Body, nil
}

//nolint:cyclop // tar.NewReader and io.Copy have to stay in same function so gosec analysis works
func extractTarGz(gzipStream io.Reader, installPath string) error {
	// Decompress and extract tar.gz
	gzr, err := gzip.NewReader(gzipStream)
	if err != nil {
		return errors.New("failed to create gzip reader: " + err.Error())
	}
	defer gzr.Close()

	tarReader := tar.NewReader(gzr)

	const gigabyte = 1024 * 1024 * 1024

	// TODO: Configurable via an option
	const maxFileSize int64 = gigabyte

	const maxTotalSize int64 = gigabyte

	var totalExtracted int64

	// Extract files, stripping the top-level directory
	for {
		header, done, err := readNextHeader(tarReader)
		if done {
			break // EOF reached
		}

		if err != nil {
			return err
		}

		target, skip := getTargetPath(header.Name, installPath)
		if skip {
			continue
		}

		switch header.Typeflag {
		case tar.TypeDir:
			if err := makeDirectory(target); err != nil {
				return err
			}
		case tar.TypeReg:
			bytesWritten, err := extractLimitedFile(tarReader, target, header.Mode, maxFileSize)
			if err != nil {
				return err
			}

			totalExtracted += bytesWritten
			if totalExtracted > maxTotalSize {
				return errors.New("extraction aborted: total size limit exceeded")
			}
		}
	}

	return nil
}

func extractLimitedFile(reader *tar.Reader, target string, mode int64, maxSize int64) (int64, error) {
	file, err := createFileHandle(target, mode)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	written, err := io.CopyN(file, reader, maxSize)

	err = handleCopyError(err, target)
	if err != nil {
		return 0, err
	}

	err = checkSizeLimitExceeded(written, maxSize, reader, target)
	if err != nil {
		return 0, err
	}

	return written, nil
}

func handleCopyError(err error, target string) error {
	if err != nil && !errors.Is(err, io.EOF) {
		os.Remove(target)

		return errors.New("failed to write file: " + err.Error())
	}

	return nil
}

func checkSizeLimitExceeded(written int64, maxSize int64, reader *tar.Reader, target string) error {
	if written == maxSize {
		buf := make([]byte, 1)

		n, _ := reader.Read(buf)
		if n > 0 {
			os.Remove(target)

			return errors.New("file extraction aborted: size limit exceeded")
		}
	}

	return nil
}

func readNextHeader(tarReader *tar.Reader) (*tar.Header, bool, error) {
	header, err := tarReader.Next()
	if errors.Is(err, io.EOF) {
		return nil, true, nil
	}

	if err != nil {
		return nil, false, errors.New("failed to read tar archive: " + err.Error())
	}

	return header, false, nil
}

func getTargetPath(headerName string, installPath string) (string, bool) {
	// Skip the top-level directory by removing the first path component
	parts := strings.SplitN(headerName, "/", 2)
	if len(parts) < 2 {
		return "", true // Skip if there's no second part (top-level directory itself)
	}

	relPath := parts[1]
	// Disallow absolute archive paths & traversal elements
	if strings.HasPrefix(relPath, "/") || strings.Contains(relPath, "..") {
		return "", true
	}

	joined := filepath.Join(installPath, relPath)

	absInstall, err := filepath.Abs(installPath)
	if err != nil {
		return "", true
	}

	absTarget, err := filepath.Abs(joined)
	if err != nil {
		return "", true
	}
	// Confirm absTarget is strictly under absInstall
	if !strings.HasPrefix(absTarget, absInstall+string(os.PathSeparator)) && absTarget != absInstall {
		return "", true
	}

	return absTarget, false
}

func makeDirectory(path string) error {
	if err := os.MkdirAll(path, 0o755); err != nil {
		return errors.New("failed to create directory: " + err.Error())
	}

	return nil
}

func createFileHandle(target string, mode int64) (*os.File, error) {
	// Create parent directory
	dir := filepath.Dir(target)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, errors.New("failed to create file directory: " + err.Error())
	}

	// Convert mode to os.FileMode with bounds checking
	var fileMode os.FileMode

	switch {
	case mode < 0:
		fileMode = 0o600 // Default if negative
	case mode > 0x7FFFFFFF:
		fileMode = os.FileMode(0o777) // Cap at maximum permission if too large
	default:
		fileMode = os.FileMode(mode)
	}

	f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, fileMode)
	if err != nil {
		return nil, errors.New("failed to create file: " + err.Error())
	}

	return f, nil
}
