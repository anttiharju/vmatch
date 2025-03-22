class ${class_name} < Formula
  desc "${description}"
  homepage "${homepage}"

  url "${url}"
  sha256 "${sha256}"
  head "https://${repository}"

  depends_on "go@${go_version}" => :build

  def install
    ENV["GOPATH"] = buildpath

    bin_path = buildpath/"src/${repository}"
    bin_path.install Dir["*"]
    cd bin_path do
      system "go", "build", "-ldflags", "-s -w -buildid=brew-${version}"
      bin.install "${app_name}"
    end
  end

  test do
    system "true"
  end
end
