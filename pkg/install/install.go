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
	err := downloadAndExtract(ctx, url, installPath)
	if err != nil {
		return errors.New("failed to download or extract: " + err.Error())
	}
	/*
		err = extract(installPath)
		if err != nil {
			return errors.New("failed to extract: " + err.Error())
		}
	*/
	return nil
}

func downloadAndExtract(ctx context.Context, url, installPath string) error {
	// Ensure install directory exists
	err := os.MkdirAll(installPath, 0o755)
	if err != nil {
		//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create install directory: "+err.Error())
	}

	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		//w.ExitWithPrint(exitcode.CmdStartIssue, "creating request: "+err.Error())
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to download Go: "+err.Error())
	}

	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		//msg := fmt.Sprintf("failed to download Go: received status code %d", resp.StatusCode)
		//w.ExitWithPrint(exitcode.CmdStartIssue, msg)
	}

	// Decompress and extract tar.gz
	gzr, err := gzip.NewReader(resp.Body)
	if err != nil {
		//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create gzip reader: "+err.Error())
	}
	defer gzr.Close()

	tarReader := tar.NewReader(gzr)

	// Extract files, stripping the top-level directory
	for {
		header, err := tarReader.Next()
		if errors.Is(err, io.EOF) {
			break
		}

		if err != nil {
			//w.ExitWithPrint(exitcode.CmdStartIssue, "error extracting tar archive: "+err.Error())
		}

		// Skip the top-level directory by removing the first path component
		parts := strings.SplitN(header.Name, "/", 2)
		if len(parts) < 2 {
			continue // Skip if there's no second part (top-level directory itself)
		}

		target := filepath.Join(installPath, parts[1])

		switch header.Typeflag {
		case tar.TypeDir:
			// Create directory
			err = os.MkdirAll(target, 0o755)
			if err != nil {
				//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create directory: "+err.Error())
			}
		case tar.TypeReg:
			// Create file
			dir := filepath.Dir(target)
			if err := os.MkdirAll(dir, 0o755); err != nil {
				//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create file directory: "+err.Error())
			}

			f, err := os.OpenFile(target, os.O_CREATE|os.O_RDWR, os.FileMode(header.Mode))
			if err != nil {
				//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to create file: "+err.Error())
			}

			if _, err := io.Copy(f, tarReader); err != nil {
				f.Close()
				//w.ExitWithPrint(exitcode.CmdStartIssue, "failed to write file: "+err.Error())
			}

			f.Close()
		}
	}
	return nil
}
