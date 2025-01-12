# vmatch

## What is this?

A wrapper that automatically calls the golangci-lint version matching your project.

## How does it know the right version?

It read a file with the name `.golangci-version`. The version format is as follows:

```
1.63.4
```

A good place to place it is at your repo root. You could also have one at your home or file system root. It keeps traversing up to find one and errors out if it doesn't.

## Why did you make this?

To prevent people from being confused why their machines complain about different issues in code reviews.

The confusion stems from different versions of golangci-lint producing different errors.

## What caveats does it have?

It doesn't manage Go for you. Go version also affects golangci-lint output, the intention is to add a wrapper for Go as well.

It needs to be acknowledged that automatically managing tools is a bit spooky, so tools such as https://flox.dev may be better solutions to the problem I'm trying to solve. Although I haven't tested how dynamic flox environments are, do they need reactivation in case the manifest changes when switching between branches.

Also currently it's only built for Apple Silicon -based macOS. The homebrew formula might work for more operating systems, but I haven't tested that.

## How do I use it?

Install with

```sh
brew install anttiharju/app/vmatch-golangci-lint
```

Instead of calling golangci-lint, call vmatch-golangci-lint. And have a `.golangci-version` file as outlined above.

Main use case I was thinking about when developing this was VS Code integration. You can enable it as outlined [here](https://golangci-lint.run/welcome/integrations/#go-for-visual-studio-code). Although please don't commit the `.vscode/settings.json` into version control, people have individualised preferences.

A `.vscode/settings.json` for integrating vmatch-golangci-lint would have the following:

```json
{
  "go.lintTool": "golangci-lint",
  "go.lintFlags": ["--fast"],
  "go.alternateTools": {
    "golangci-lint": "/opt/homebrew/bin/vmatch-golangci-lint"
  }
}
```
