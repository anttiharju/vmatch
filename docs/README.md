# Introduction

[![Build](https://github.com/anttiharju/vmatch/actions/workflows/build.yml/badge.svg)](https://github.com/anttiharju/vmatch/actions/workflows/build.yml)

## FAQ

**Q:** What about https://go.dev/blog/toolchain?

**A:** It is about forward-compatibility, `vmatch` installs the Go version specified in your project.

**Q:** What about `go run` (Go 1.24 and after `go run` calls are cached)?

**A:** It is probably the easy thing to introduce to your team and is a fine addition to Go.

## Why

Collaborators using different versions of `golangci-lint` may get different output, leading to confusion and wasted time in code reviews. Ideally, a team would agree to use `vmatch` as their source for `go` and `golangci-lint`. That way, they would always have the right version installed.

## Installation

```sh
brew install anttiharju/tap/vmatch
```

and afterwards for further instructions run

```sh
vmatch doctor
```

Mainly, you should have `~/.vmatch/bin` in your PATH.

## Updating

```sh
brew update && brew upgrade vmatch
```

### Note on expectations

When the specified Go version is downloaded for the first time, it may take a while.

## Integrations

### VS Code

#### Go

Open your project via `code .` or similar from your shell where `vmatch doctor` reports the installation as healthy to ensure a vmatch-managed version of Go is available.

#### golangci-lint

Follow guidance at https://golangci-lint.run/welcome/integrations/#visual-studio-code but specify the full path of your ~/.vmatch/bin/golangci-lint as an alternate lint tool, like this:

```json
  "go.alternateTools": {
    "lintTool": "/Users/antti/.vmatch/bin/golangci-lint",
  },
```

### Renovate

I _think_ one can configure Renovate to maintain the `.golangci-version` file for you, see https://www.jvt.me/posts/2022/12/15/renovate-golangci-lint/ for an example.

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

If your `go.mod` does not specify the full version, for example `1.24` instead of `1.24.3`, `vmatch` defaults to `1.24.0` for simplicity, surprisingly, sometimes there is a Go 1.minor and sometimes a Go 1.minor.0 version released. https://dl.google.com/go/go1.20.darwin-amd64.pkg and https://dl.google.com/go/go1.21.0.darwin-amd64.pkg are examples.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/anttiharju/vmatch.svg?variant=adaptive)](https://starchart.cc/anttiharju/vmatch)

## Retrospective on the project

While developing `vmatch`, I learned a lot about Go, `brew`, GitHub Actions, Git pre-commit hooks, and developer tooling. There's a surprising amount of detail that has to be accommodated in many places.

I think this project could be pushed a lot further, especially in terms of where it is distributed, and adding new features like always being on the latest patch of `Go`. Unfortunately life is too short, and the project is at a state where it is very usable for my personal use.

Long-term, `Nix` (see https://nixos.org), would likely be the generic solution for managing your development environment. Rolling it out to an entire team might have a relatively high barrier, even with projects like `Flox` (see https://flox.dev), so `vmatch` attempts to be a low-barrier-of-entry solution.

If you find bugs, issue reports are very much appreciated and PRs are welcome. If you plan to push the project a lot further (for example managing `node` in a similar fashion), I'd recommend you to maintain a fork, say, `vmatch-node`.

During the project a lot of supporting infrastructure was set up:

- https://github.com/anttiharju/homebrew-tap/tree/fe24baf82fb570b6ec74694750080789742750e7 (whopping 174 commits, corresponding roughly to the same number of releases!)
- https://github.com/anttiharju/actions/tree/v1 (whopping 20 composite actions!)
- https://github.com/anttiharju/check-relative-markdown-links/tree/f79dc07684109baed16d10dd8ff2ade9bb94ce22 (a bash prototype for a tool that's more generally applicable and therefore useful than `vmatch`)
- https://github.com/anttiharju/editorconfig/tree/9fa1679fcb6d55ed841a2ad36d142afd2d7cf30f (a centrally managed editorconfig distributed via GitHub Actions to my repositories!)

all of which make it easier for me to build new tools, on-demand, with minimal effort spent on trivial things like tooling automation. With [Go rewrite of `check-relative-markdown-links`](https://github.com/anttiharju/check-relative-markdown-links/issues/5) being the first!
