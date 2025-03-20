# Introduction

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

## Lack of tests

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

## Star History

<a href="https://star-history.com/#anttiharju/vmatch&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=anttiharju/vmatch&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=anttiharju/vmatch&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=anttiharju/vmatch&type=Date" />
 </picture>
</a>
