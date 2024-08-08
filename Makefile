SHELL := bash
.ONESHELL:
.SHELLFLAGS := -euo pipefail -c
MAKEFLAGS += --warn-undefined-variables

GOLANGCI-LINT_VERSION=$(shell cat .golangci-version)
GOLANGCI-LINT_INSTALL_DIR=$(shell pwd)/bin/v/$(GOLANGCI-LINT_VERSION)

APP_NAME=vmatch-golangci-lint

setup: install-hooks install-lint

install-hooks:
	@git config --local core.hooksPath .githooks/

install-lint:
	@VERSION=$(GOLANGCI-LINT_VERSION) INSTALL_DIR=$(GOLANGCI-LINT_INSTALL_DIR) scripts/install-lint.sh

ci: shellcheck lint

shellcheck:
	@scripts/shellcheck.sh

lint: install-lint
	@$(GOLANGCI-LINT_INSTALL_DIR)/golangci-lint run

lint-fix:
	@$(GOLANGCI-LINT_INSTALL_DIR)/golangci-lint run --fix

build:
	@APP_NAME=$(APP_NAME) scripts/build.sh

run: build rerun

rerun:
	@APP_NAME=$(APP_NAME) bin/$(APP_NAME) version

clean:
	@rm -rf bin/

copy-path:
	@echo -n "$(shell pwd)/bin/$(APP_NAME)" | pbcopy

simple-benchmark:
	@time /Users/antti/go/bin/golangci-lint version
	@time ./bin/$(APP_NAME) version

.PHONY: setup install-hooks install-lint ci shellcheck lint lint-fix build run rerun clean copy-path
