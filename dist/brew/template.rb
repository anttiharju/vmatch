# frozen_string_literal: true

# Homebrew formula for vmatch - a tool that automates
# matching golangci-lint and Go versions to your project.
#
# This formula installs the vmatch binary and its dependencies.
class ${class_name} < Formula
  desc '${description}'
  homepage '${homepage}'

  url '${url}'
  sha256 '${sha256}'
  head 'https://${repository}'
  license 'GPL-3.0-only'

  depends_on 'go@${go_version}' => :build
  ${bottle}
  def install
    ENV['GOPATH'] = buildpath

    bin_path = buildpath / 'src/${repository}'
    bin_path.install Dir['*']
    cd bin_path do
      system 'go', 'build', '-ldflags', '-s -w -buildid=brew-${version}'
      bin.install '${app_name}'
    end
  end

  test do
    system 'true'
  end
end
