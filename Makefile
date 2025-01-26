.PHONY: build

build:
	go build -C cmd/vmatch-golangci-lint -o "$(shell pwd)/vmatch-golangci-lint"
