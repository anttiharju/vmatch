# frozen_string_literal: true

class ${class_name} < Formula
  desc '${description}'
  homepage '${homepage}'
  version '${version}'
  license 'GPL-3.0-only'

  on_macos do
    if Hardware::CPU.intel?
      url '${darwin_amd64}'
      sha256 '${darwin_amd64_sha256}'

      def install
        bin.install "vmatch"
      end
    end
    if Hardware::CPU.arm?
      url '${darwin_arm64}'
      sha256 '${darwin_arm64_sha256}'

      def install
        bin.install "vmatch"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        url '${linux_amd64}'
        sha256 '${linux_amd64_sha256}'

        def install
          bin.install "vmatch"
        end
      end
    end
    if Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        url '${linux_arm64}'
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
