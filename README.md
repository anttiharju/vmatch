# vmatch

## What?

A wrapper that automatically calls the golangci-lint version matching your project.

## How?

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

## Why?

I saw mismatching linter versions causing confusion in a team so I thought to automate it.

## Todo

- doctor subcommand
  - To be able to include an actual test in the brew formula
- Work out implications of wrapping go binary
  - Setup aliases with the brew formula, use advice from [here](https://scriptingosx.com/2017/05/where-paths-come-from/)
  - Limit version management to only happen under $HOME to not collide with installation scripts (for example homebrew formulas)
- Distribute to winget (no idea on details)
- Simplify these docs, currently this is a collection of somewhat random thoughts.
- Automation to be able to do security hardening
- Dark mode for GitHub pages deployment

### Lack of tests

Currently there's not too much code and the overall direction of the project is still quite open.

Once the project is deemed feature-complete, writing automated tests (covering all platforms) would be essential for long-term maintenance.

## Usage?

Install with

```sh
brew install anttiharju/tap/vmatch
```

Instead of calling golangci-lint, call vmatch. And have a `.golangci-version` file as outlined above.

For VS Code, this can be done with a `.vscode/settings.json` file like the one below:

```json
{
  "go.lintTool": "golangci-lint",
  "go.lintFlags": ["--fast"],
  "go.alternateTools": {
    "golangci-lint": "/opt/homebrew/bin/vmatch"
  }
}
```

For more documentation on VS Code integration, refer to [golangci-lint docs](https://golangci-lint.run/welcome/integrations/#go-for-visual-studio-code).
