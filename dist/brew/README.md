# Homebrew distribution

<!--meaningless change-->

This directory contains bash scripts:

- [`values.bash`](./values.bash) is required by the [render-template](https://github.com/anttiharju/actions/tree/v0/render-template) action.
- [`render.bash`](./render.bash) exists to enable faster iteration by being able to render the template locally. Provide `--quick` to use cached values to speed up iteration.

Templating is important for reducing the maintenance burden of updating the Brew formula. While rendering out the final Formula in this repository is not strictly necessary (compared to just rendering it to [homebrew-tap](https://github.com/anttiharju/homebrew-tap)), it does enable running [Rubocop](https://rubocop.org) on the final template before release.
