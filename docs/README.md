# vmatch-golangci-lint

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

- It could be more secure (pin install script to a sha)
- It doesn't manage Go for you. As the Go version affects golangci-lint output, the golangci-lint version management isn't as automated as it could be.
  - One option would be to infer sane default from the Go version in `go.mod`
  - Another would be making a supporting wrapper for Go, `vmatch-go`
    - **But overall, a better approach is probably something Nix-based.**

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
   - What GitHub Apps can't do and where a service account may be appropriate
3. More about composite actions, as I created a few in my actions monorepo
