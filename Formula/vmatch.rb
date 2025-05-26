# frozen_string_literal: true

class Vmatch < Formula
  desc 'Go & golangci-lint version automation'
  homepage 'https://anttiharju.dev/vmatch'
  version '0.1.7'
  license 'GPL-3.0-only'

  on_macos do
    if Hardware::CPU.intel?
      url 'https://github.com/anttiharju/vmatch/releases/download/v0.1.7/vmatch-darwin-amd64.tar.gz'
      sha256 'baa54968eb91c7aa94baad10f62b44b3f486f4e51eddd041509e964a601c008e'

      def install
        bin.install "vmatch"
      end
    end
    if Hardware::CPU.arm?
      url "https://github.com/anttiharju/vmatch/releases/download/v0.1.7/vmatch-darwin-arm64.tar.gz"
      sha256 '498bfaa5ceb05cacc3e3301155d50fa08c9e5102237411e31ff0890a8dcbbab4'

      def install
        bin.install "vmatch"
      end
    end
  end

  on_linux do
    if Hardware::CPU.intel?
      if Hardware::CPU.is_64_bit?
        url "https://github.com/anttiharju/vmatch/releases/download/v0.1.7/vmatch-linux-amd64.tar.gz"
        sha256 '48070848b54afd1d01553ab6138fc3d06a9716335b30d7a000fcb25ba844e41f'

        def install
          bin.install "vmatch"
        end
      end
    end
    if Hardware::CPU.arm?
      if Hardware::CPU.is_64_bit?
        url "https://github.com/anttiharju/vmatch/releases/download/v0.1.7/vmatch-linux-arm64.tar.gz"
        sha256 'a7f839261146f7bfce66063f7597016ce77b91c3a24838ab3184354ff76245ab'

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
