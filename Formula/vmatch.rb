# frozen_string_literal: true

# Homebrew formula for vmatch - a tool that automates
# matching golangci-lint and Go versions to your project.
#
# This formula installs the vmatch binary and its dependencies.
class Vmatch < Formula
  desc 'golangci-lint + Go version automation'
  homepage 'https://anttiharju.dev/vmatch'

  url 'https://api.github.com/repos/anttiharju/vmatch/tarball/build100'
  sha256 'c9322ada7784bc83890bafbd0ec277339ac0279632c05e574536776b765a0b36'
  head 'https://github.com/anttiharju/vmatch'
  license "GPL-3.0-only"

  depends_on 'go@1.23' => :build

  bottle do
    root_url "https://github.com/anttiharju/vmatch/releases/download/build100"
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: "37f1d0b0485bf8e60bd49344e72d96aa1767c78d406ba1e6f72de6d752c35282"
    sha256 cellar: :any, arm64_sequoia: "d3bbc2ea3f6d4f2b581cff69e64981638cb66e7e0974a44546703ad60833ad16"
  end

  def install
    ENV['GOPATH'] = buildpath

    bin_path = buildpath / 'src/github.com/anttiharju/vmatch'
    bin_path.install Dir['*']
    cd bin_path do
      system 'go', 'build', '-ldflags', '-s -w -buildid=brew-build100'
      bin.install 'vmatch'
    end
  end

  test do
    system 'true'
  end
end
