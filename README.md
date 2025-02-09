# vmatch

## What?

A wrapper that automatically calls the golangci-lint version matching your project.

## How?

It traverses filesystem upwards until it finds the file `.golangci-version` with the following format:

```
1.63.4
```

Good place to have the version file is your git repo root.

It installs the right golangci-lint version using the [Binaries](https://golangci-lint.run/welcome/install/#binaries) install method. Binaries are stored under `~` like this:

```
.vmatch
└── golangci-lint
    └── v1.63.4
        └── golangci-lint
```

## Why?

I saw mismatching linter versions causing confusion in a team so I thought to automate it.

## Caveats?

### Go version is unmanaged

`vmatch-golangci-lint` does not manage Go versions. As the installed Go version affects golangci-lint output, the golangci-lint version matching is not as automated as it could be.

A solution to this could be to implement another wrapper for Go, `vmatch-go`. But this bring up another issue:

### vmatch does not want to cause visible changes in repositories that use it

Currently, integrating `vmatch-golangci-lint` into for example VS Code should not end up in version control. But should `vmatch-go` be implemented, it would definitely be visible in tracked files with the current wrapping approach.

There are better ways to "replace" binaries, one way is for example to "use bash aliases or functions in your profile" as described [\[1\]](https://scriptingosx.com/2017/05/where-paths-come-from/), which further refers to [\[2\]](https://scriptingosx.com/2017/05/configuring-bash-with-aliases-and-functions/)

The problem with said approach is, that it introduces additional complexity [managing shell aliases/functions], which is somewhat undesired. TBD

## Todo

- Wrapper-specific cli (with --, and use an actual library)
  - Include an actual test in the brew formula
- Also manage Go versions
- For now focus is on Apple Silicon macbooks but cross-platform is more or less required for more serious usage.
- Providing a Docker image might be worthwhile, similar to https://golangci-lint.run/welcome/install/#docker
- Simplify these docs, currently this is a collection of somewhat random thoughts.

### Lack of tests

Currently there's not too much code and the overall direction of the project is still quite open.

Once the project is defined feature-complete, writing automated tests (covering all platforms) would be essential for long-term maintenance.

## Usage?

Install with

```sh
brew install anttiharju/tap/vmatch-golangci-lint
```

Instead of calling golangci-lint, call vmatch-golangci-lint. And have a `.golangci-version` file as outlined above.

For VS Code, this can be done with a `.vscode/settings.json` file like the one below:

```json
{
  "go.lintTool": "golangci-lint",
  "go.lintFlags": ["--fast"],
  "go.alternateTools": {
    "golangci-lint": "/opt/homebrew/bin/vmatch-golangci-lint"
  }
}
```

For more documentation on VS Code integration, refer here [here](https://golangci-lint.run/welcome/integrations/#go-for-visual-studio-code).

## Learnings

1. How to distribute software via Homebrew
2. How to automate the release process with GitHub App tokens
   - Also learned that GitHub Apps can't enable automerge, and this is the place where service accounts would be appropriate.
3. More about composite actions, as I created a few in my actions monorepo
