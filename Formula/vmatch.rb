# frozen_string_literal: true

# Homebrew formula for vmatch - a tool that automates
# matching golangci-lint and Go versions to your project.
#
# This formula installs the vmatch binary and its dependencies.
class Vmatch < Formula
  desc 'golangci-lint + Go version automation'
  homepage 'https://anttiharju.dev/vmatch'

  url 'https://api.github.com/repos/anttiharju/vmatch/tarball/build102'
  sha256 '74936e1f5b1695c071f6953ea5399aacb4238c3c08ea49b0fda16cf5443d5eb0'
  head 'https://github.com/anttiharju/vmatch'
  license 'GPL-3.0-only'

  depends_on 'go@1.23' => :build

  bottle do
    root_url 'https://github.com/anttiharju/vmatch/releases/download/build102'
    rebuild 1
    sha256 cellar: :any, arm64_sonoma: 'a9a8bf4915c020acf579f96f59d0ebf1fc27742e8979ada188d4352d9969f44a'
    sha256 cellar: :any, arm64_sequoia: '81c4aa1255440c92f5233dbcbc9d9b8b60585090128754b13b2ebc91229dd5e7'
    sha256 cellar: :any, x86_64_linux: '75a681ef45406a10fe475c3eb8eb85548a5732b69d8260e6d6a3aa650607a5f7'
  end

  def install
    ENV['GOPATH'] = buildpath

    bin_path = buildpath / 'src/github.com/anttiharju/vmatch'
    bin_path.install Dir['*']
    cd bin_path do
      system 'go', 'build', '-ldflags', '-s -w -buildid=brew-build102'
      bin.install 'vmatch'
    end
  end

  test do
    system 'true'
  end
end
