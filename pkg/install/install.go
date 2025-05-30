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

func FromURL(ctx context.Context, version, url, installPath string) error {
	// Ensure install directory exists
	err := os.MkdirAll(installPath, 0o755)
	if err != nil {
		return errors.New("failed to create install directory: " + err.Error())
	}

	// Download the file
	body, err := downloadFile(ctx, url)
	if err != nil {
		// If download fails and version ends with ".0", try without it
		if strings.HasSuffix(version, ".0") {
			altVersion := strings.TrimSuffix(version, ".0")
			altURL := strings.Replace(url, version, altVersion, 1)

			body, err = downloadFile(ctx, altURL)
			if err != nil {
				return errors.New("failed to download (also tried without .0 suffix): " + err.Error())
			}
		} else {
			return errors.New("failed to download: " + err.Error())
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

	return filepath.Join(installPath, parts[1]), false
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
