# Introduction

[![Build](https://github.com/anttiharju/vmatch/actions/workflows/build.yml/badge.svg)](https://github.com/anttiharju/vmatch/actions/workflows/build.yml)

## FAQ

**Q:** What about https://go.dev/blog/toolchain?

**A:** It is about forward-compatibility, `vmatch` installs the Go version specified in your project.

**Q:** What about `go run` (post Go 1.24, where its calls are cached)?

**A:** It is probably the easy thing to introduce to your team and is a fine addition to Go.

## Why

I saw mismatching linter versions causing confusion in a team so I thought to automate it. Different versions of `golangci-lint` may give different warnings. Even the same version of `golangci-lint` may give different warnings if the version of `Go` used is different.

vmatch also works when switching between branches that have a different version of Go. This makes it easier to play with a changeset with the intended version of Go, and even if the branch does not get merged just yet, you can still keep working on the current version of Go without having to tinker with your local setup.

Tool version management is something that can be automated; therefore it should be automated.

## Usage

The target state is that the `go` that you call is actually a shell script that wraps vmatch with right settings, the project hasn't gotten quite there yet so in the meanwhile use

```sh
vmatch go (any args you would give to go)
```

or

```sh
vmatch golangci-lint (any args you would give to golangci-lint)
```

## Integrations

### VS Code

Follow guidance at https://golangci-lint.run/welcome/integrations/#visual-studio-code but specify the full path of your ~/.vmatch/bin/golangci-lint as an alternate lint tool, like this:

```json
  "go.alternateTools": {
    "lintTool": "/Users/antti/.vmatch/bin/golangci-lint",
  },
```

### Renovate

I _think_ you configure Renovate to maintain the `.golangci-version` file for you, see https://www.jvt.me/posts/2022/12/15/renovate-golangci-lint/ for an example.

### VS Code

Visual Studio Code integration relies on the editor being launched from the right directory with `code .`

## Installation

### Brew

`macOS arm64` `Linux amd64` `Linux arm64` `macOS amd64`

```sh
brew install anttiharju/tap/vmatch
```

This distribution channel is recommended because it simplifies access to updates. Update with

```sh
brew update && brew upgrade vmatch
```

### Pre-built binaries

`macOS arm64`

```sh
curl -LsSf https://github.com/anttiharju/vmatch/releases/latest/download/vmatch-darwin-arm64.tar.gz | sudo tar -xz --strip-components=0 vmatch -C /usr/local/bin && vmatch doctor
```

`Linux amd64`

```sh
curl -LsSf https://github.com/anttiharju/vmatch/releases/latest/download/vmatch-linux-amd64.tar.gz | sudo tar -xz --strip-components=0 vmatch -C /usr/local/bin && vmatch doctor
```

`Linux arm64`

```sh
curl -LsSf https://github.com/anttiharju/vmatch/releases/latest/download/vmatch-linux-arm64.tar.gz | sudo tar -xz --strip-components=0 vmatch -C /usr/local/bin && vmatch doctor
```

`macOS amd64`

```sh
curl -LsSf https://github.com/anttiharju/vmatch/releases/latest/download/vmatch-darwin-amd64.tar.gz | sudo tar -xz --strip-components=0 vmatch -C /usr/local/bin && vmatch doctor
```

### Manual

`most unix-like operating systems`

Clone the git repository and run `go build` on a version of Go that supports the one specified in `go.mod`. No support will be provided for this installation method.

## How

It traverses filesystem upwards until it finds the file `.golangci-version`. A good place to have the version file is your git repo root.

It installs the right golangci-lint version using the [Binaries](https://golangci-lint.run/welcome/install/#binaries) install method. Binaries are stored under your `$HOME` like this:

```
.vmatch
└── golangci-lint
    └── v2.1.6
        └── golangci-lint
```

Go binaries are stored in a similar fashion.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/anttiharju/vmatch.svg?variant=adaptive)](https://starchart.cc/anttiharju/vmatch)

Starring the project helps to get it eventually distributed via homebrew/core :)
