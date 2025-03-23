# Homebrew distribution

This directory contains bash scripts:

- [`values.sh`](./values.sh) is required by the [render-template](https://github.com/anttiharju/actions/tree/v0/render-template) action.
- [`preview.sh`](./render.sh) exists to enable faster iteration by being able to iterate locally.  
  Provide `--quick` to use cached values to speed up iteration.

Templating is important for reducing the maintenance burden of updating the Brew formula. While rendering out the final Formula in this repository is not strictly necessary (compared to just rendering it to [homebrew-tap](https://github.com/anttiharju/homebrew-tap)), it does enable running [Rubocop](https://rubocop.org) on the final template before release.
