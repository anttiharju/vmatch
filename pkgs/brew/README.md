# Homebrew tap

This directory contains bash scripts:

- [`values.sh`](./values.sh) is required by the [render-template](https://github.com/anttiharju/actions/tree/v1/render-template) action which renders the final formula to https://github.com/anttiharju/homebrew-tap
- [`render.sh`](./render.sh) exists to enable faster iteration by being able to render the template locally. Provide `--quick` to use cached values to speed up iteration.

Templating is important for reducing the maintenance cost of the Brew formula. I'm aware of solutions like https://goreleaser.com/, but opted for something custom because I may want to distribute things other than Go too and wanted to reduce dependencies.
