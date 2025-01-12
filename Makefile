SHELL := sh
.ONESHELL:
.SHELLFLAGS := -eu -c
MAKEFLAGS += --warn-undefined-variables

GOLANGCI-LINT_VERSION=$(shell cat .golangci-version)
GOLANGCI-LINT_INSTALL_DIR=~/.vmatch/golangci-lint/v$(GOLANGCI-LINT_VERSION)

setup: install_hooks install_lint

install_hooks:
	@git config --local core.hooksPath .githooks/

install_lint:
	@VERSION=$(GOLANGCI-LINT_VERSION) INSTALL_DIR=$(GOLANGCI-LINT_INSTALL_DIR) scripts/install-lint.sh

lint: install_lint
	@$(GOLANGCI-LINT_INSTALL_DIR)/golangci-lint run

lint-fix:
	@$(GOLANGCI-LINT_INSTALL_DIR)/golangci-lint run --fix

shellcheck:
	@./scripts/shellcheck.sh

build:
	@BUILD_PREFIX=make APP_NAME=vmatch-golangci-lint scripts/build.sh

.PHONY: setup install_hooks install_lint lint lint-fix shellcheck build
