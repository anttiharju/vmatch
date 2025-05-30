# Homebrew distribution

This directory contains bash scripts:

- [`values.bash`](./values.bash) is required by the [render-template](https://github.com/anttiharju/actions/tree/v1/render-template) action which renders the final formula to https://github.com/anttiharju/homebrew-tap
- [`render.bash`](./render.bash) exists to enable faster iteration by being able to render the template locally. Provide `--quick` to use cached values to speed up iteration.

Templating is important for reducing the maintenance cost of the Brew formula.
