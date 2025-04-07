# Introduction

[![Release](https://github.com/anttiharju/vmatch/actions/workflows/release.yml/badge.svg)](https://github.com/anttiharju/vmatch/actions/workflows/release.yml)

## What

A wrapper that automatically calls the golangci-lint version matching your project.

## How

It traverses filesystem upwards until it finds the file `.golangci-version` with the following format:

```
1.63.4
```

Good place to have the version file is your git repo root.

It installs the right golangci-lint version using the [Binaries](https://golangci-lint.run/welcome/install/#binaries) install method. Binaries are stored under `$HOME` like this:

```
.vmatch
└── golangci-lint
    └── v1.63.4
        └── golangci-lint
```

## Why

I saw mismatching linter versions causing confusion in a team so I thought to automate it.

## Lack of tests

Currently there's not too much code and the overall direction of the project is still quite open.

Once the project is deemed feature-complete, writing automated tests (covering all platforms) would be essential for long-term maintenance.

## Usage

The target state is that the `go` that you call is actually a shell script that wraps vmatch with right settings, the project hasn't gotten quite there yet so in the meanwhile use

```sh
vmatch go (any args you would give to go)
```

or

```sh
vmatch golangci-lint (any args you would give to golangci-lint)
```

Remember that you need to have `go.mod` with Go version for go usage and respectively `.golangci-version` for golangci-lint.

## Stargazers over time

[![Stargazers over time](https://starchart.cc/anttiharju/vmatch.svg?variant=adaptive)](https://starchart.cc/anttiharju/vmatch)

Starring the project helps to get it eventually distributed via homebrew/core :)
