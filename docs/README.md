# Introduction

[![Build](https://github.com/anttiharju/vmatch/actions/workflows/build.yml/badge.svg)](https://github.com/anttiharju/vmatch/actions/workflows/build.yml)

## FAQ

**Q:** What about https://go.dev/blog/toolchain?

**A:** It is about forward-compatibility, `vmatch` installs the Go version specified in your project.

**Q:** What about `go run` (Go 1.24 and after `go run` calls are cached)?

**A:** It is probably the easy thing to introduce to your team and is a fine addition to Go.

## Why

Collaborators using different versions of `golangci-lint` may get different output, leading to confusion and wasted time in code reviews. Ideally, a team would agree to use `vmatch` as their `go` and `golangci-lint` manager. That way, they would always have the right version installed.

## Installation

```sh
brew install anttiharju/tap/vmatch
```

and afterwards run

```sh
vmatch doctor
```

for further instructions. Mainly, you should have `~/.vmatch/bin` in your PATH.

## Integrations

### VS Code

#### go

Open your project via `code .` or similar from your shell where `vmatch doctor` reports the installation as healthy to ensure a vmatch-managed version of Go is available.

#### golangci-lint

Follow guidance at https://golangci-lint.run/welcome/integrations/#visual-studio-code but specify the full path of your ~/.vmatch/bin/golangci-lint as an alternate lint tool, like this:

```json
  "go.alternateTools": {
    "lintTool": "/Users/antti/.vmatch/bin/golangci-lint",
  },
```

### Renovate

I _think_ you configure Renovate to maintain the `.golangci-version` file for you, see https://www.jvt.me/posts/2022/12/15/renovate-golangci-lint/ for an example.

## How

`vmatch` traverses the filesystem upwards until it finds the file `.golangci-version` and `go.mod`. These files should be in the same directory, but it is not enforced.

Go versions are downloaded from Google servers and stored under `~/.vmatch`, like this:

```tree
.vmatch
├── bin
│   ├── go
│   ├── golangci-lint
│   └── gopls -> /Users/antti/go/bin/gopls
├── go
│   ├── v1.21.0
│   ├── v1.23.0
│   ├── v1.23.5
│   ├── v1.24.2
│   └── v1.24.3
└── golangci-lint
    ├── v1.63.4
    └── v2.1.6

11 directories, 3 files
```

Contents of `~/.vmatch/bin` are symlinked from `$(go env GOPATH)/bin`, expect for `go` or `golangci-lint`, because those are shell scripts that wrap `vmatch`.

If your `go.mod` does not specify the full version, for example `1.24` instead of `1.24.3`, `vmatch` defaults to `1.24.0` for simplicity.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/anttiharju/vmatch.svg?variant=adaptive)](https://starchart.cc/anttiharju/vmatch)
