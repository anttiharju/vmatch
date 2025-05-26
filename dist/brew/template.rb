# frozen_string_literal: true

class ${class_name} < Formula
  desc '${description}'
  homepage '${homepage}'
  version '${version}'
  license 'GPL-3.0-only'

  on_macos do
    if Hardware::CPU.intel?
      url 'https://github.com/anttiharju/vmatch/releases/download/v${version}/vmatch-darwin-amd64.tar.gz'
      sha256 '${darwin_amd64_sha256}'

      def install
        bin.install "vmatch"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/anttiharju/vmatch/releases/download/v${version}/vmatch-darwin-arm64.tar.gz"
      sha256 '${darwin_arm64_sha256}'

      def install
        bin.install "vmatch"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        url "https://github.com/anttiharju/vmatch/releases/download/v${version}/vmatch-linux-amd64.tar.gz"
        sha256 '${linux_amd64_sha256}'

        def install
          bin.install "vmatch"
        end
      end
    end
    if Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        url "https://github.com/anttiharju/vmatch/releases/download/v${version}/vmatch-linux-arm64.tar.gz"
        sha256 '${linux_arm64_sha256}'

        def install
          bin.install "vmatch"
        end
      end
    end
  end

  test do
    system "#{bin}/vmatch doctor"
  end
end
