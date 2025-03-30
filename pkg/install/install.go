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
	"time"
)

func FromURL(ctx context.Context, url, installPath string) error {
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	// Ensure install directory exists
	err := os.MkdirAll(installPath, 0o755)
	if err != nil {
		return errors.New("failed to create install directory: " + err.Error())
	}

	// Download the file
	body, err := downloadFile(ctx, url)
	if err != nil {
		return errors.New("failed to download: " + err.Error())
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

func extractTarGz(gzipStream io.Reader, installPath string) error {
	// Decompress and extract tar.gz
	gzr, err := gzip.NewReader(gzipStream)
	if err != nil {
		return errors.New("failed to create gzip reader: " + err.Error())
	}
	defer gzr.Close()

	tarReader := tar.NewReader(gzr)

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
			file, err := createFileHandle(target, header.Mode)
			if err != nil {
				return err
			}

			if _, err := io.Copy(file, tarReader); err != nil {
				file.Close()

				return errors.New("failed to write file: " + err.Error())
			}

			file.Close()
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

	f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(mode))
	if err != nil {
		return nil, errors.New("failed to create file: " + err.Error())
	}

	return f, nil
}
