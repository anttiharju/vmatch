# Introduction

[![Build](https://github.com/anttiharju/vmatch/actions/workflows/build.yml/badge.svg)](https://github.com/anttiharju/vmatch/actions/workflows/build.yml)

**NB! The project is currently in alpha**; things might not be fully functional just yet. Steady progress is being made. Things are taking a little bit longer because automating things that would make maintenance cumbersome will take some time. The idea is to commit to maintaining this project.

## The promise

With vmatch you or your coworkers will never have to think about what version of `golangci-lint`\* or `Go` you need to have installed when working on a given Go project. This is especially useful if you move around repositories as a DevOps engineer a lot, but even for people who work on the same project that goes through Go version bumps this project should eliminate a lot of toil. It also has access to old versions of Go, unlike `brew`, which only supports installing the recent ones. Sometimes one has to work on legacy software and get a fix in before committing to Go version upgrade.

> \* as long as the repository has the desired `golangci-lint` version in a `.golangci-version` file. The format looks like this:
>
> ```
> 2.1.6
> ```
>
> A `.golangci-version` file (or a single source of truth in general) is something one should do anyway so that people don't miss versions to bump during upgrades.
>
> For Go, no setup should be necessary as `go.mod` is used as the source of truth.

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

## Installation

### Brew

`macOS 14 or above with Apple Silicon` `x86_64 Linux`

```sh
brew install anttiharju/tap/vmatch
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
