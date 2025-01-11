#!/usr/bin/env dash

make install-lint
make build

./bin/vmatch-golangci-lint version
./bin/v/"$VERSION"/golangci-lint version

cd cmd/testdata || exit 1

direct_output=$(../../bin/vmatch-golangci-lint run)
wrapped_output=$(../../bin/v/"$VERSION"/golangci-lint run)

if [ "$direct_output" != "$wrapped_output" ]; then
	echo "Output about ./cmd/testdata/main.go differs"
	exit 1
else
	echo "Output about ./cmd/testdata/main.go is the same"
fi
