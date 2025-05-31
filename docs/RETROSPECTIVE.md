# Sideproject retrospective

While developing `vmatch`, I learned a lot about Go, `brew`, GitHub Actions, Git pre-commit hooks, and developer tooling. There's a surprising amount of detail that has to be accommodated in many places.

I think this project could be pushed a lot further, especially in terms of where it is distributed, and adding new features like always being on the latest patch of `Go`. Unfortunately life is too short, and the project is at a state where it is very usable for my personal use.

Long-term, `Nix` (see [nixos.org](https://nixos.org)), would likely be the generic solution for managing your development environment. Rolling it out to an entire team might have a relatively high barrier, even with projects like `Flox` (see [flox.dev](https://flox.dev)), so `vmatch` attempts to be a low-barrier-of-entry solution.

If you find bugs, issue reports are very much appreciated and PRs are welcome. If you plan to push the project a lot further (for example managing `node` in a similar fashion), I'd recommend you to maintain a fork, say, `vmatch-node`.

During the project a lot of supporting infrastructure was set up:

- [github.com/anttiharju/homebrew-tap](https://github.com/anttiharju/homebrew-tap/tree/299612d532b3a676f5bfea84c3115ff562c9e23a) (whopping 174 commits, corresponding roughly to the same number of releases!)
- [github.com/anttiharju/actions@v1](https://github.com/anttiharju/actions/tree/v1) (whopping 20 composite actions!)
- [github.com/anttiharju/check-relative-markdown-links](https://github.com/anttiharju/check-relative-markdown-links/tree/f79dc07684109baed16d10dd8ff2ade9bb94ce22) (a bash prototype for a tool that's more generally applicable and therefore useful than `vmatch`)
- [github.com/anttiharju/editorconfig](https://github.com/anttiharju/editorconfig/tree/9fa1679fcb6d55ed841a2ad36d142afd2d7cf30f) (a centrally managed editorconfig distributed via GitHub Actions to my repositories!)

all of which make it easier for me to build new tools, on-demand, with minimal effort spent on trivial things like tooling automation. With [Go rewrite of `check-relative-markdown-links`](https://github.com/anttiharju/check-relative-markdown-links/issues/5) being the first!
