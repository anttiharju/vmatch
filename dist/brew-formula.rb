# tmp change to trigger release
class $CLASS_NAME < Formula
    desc "$DESCRIPTION"
    homepage "$HOMEPAGE"

    url "$URL"
    sha256 "$SHA256"
    head "https://$REPOSITORY"

    depends_on "go@$GO_VERSION" => :build

    def install
        ENV["GOPATH"] = buildpath

        bin_path = buildpath/"src/$REPOSITORY"
        bin_path.install Dir["*"]
        cd bin_path do
          system "go", "build", "-ldflags", "-s -w -buildid=brew-$VERSION"
          bin.install "$APP_NAME"
        end
    end

    test do
        system "true"
    end
end
