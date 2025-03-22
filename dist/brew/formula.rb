# frozen_string_literal: true

# Homebrew formula for vmatch - a tool that automates
# matching golangci-lint and Go versions to your project.
#
# This formula installs the vmatch binary and its dependencies.
class Vmatch < Formula
  desc 'golangci-lint + Go version automation'
  homepage 'https://anttiharju.dev/vmatch'

  url 'https://api.github.com/repos/anttiharju/vmatch/tarball/build62'
  sha256 'f707f3e8f7bd9d221c6fb3ec654ce6505f3f6632e8cd5ca445a68dbb1882c8b1'
  head 'https://github.com/anttiharju/vmatch'

  depends_on 'go@1.23' => :build

  def install
    ENV['GOPATH'] = buildpath

    bin_path = buildpath / 'src/github.com/anttiharju/vmatch'
    bin_path.install Dir['*']
    cd bin_path do
      system 'go', 'build', '-ldflags', '-s -w -buildid=brew-build62'
      bin.install 'vmatch'
    end
  end

  test do
    system 'true'
  end
end
