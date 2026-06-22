# -----------------------------------------------------------------------------------------------------------
# dprint-plugin-swift Makefile
# -----------------------------------------------------------------------------------------------------------
# dprint process plugin wrapping SwiftFormat for Swift files.
#
# Usage:
#   make <command>
#
# Available Commands:
#   help               : Show this help message
#   check              : Verify developer dependencies
#   fetch-swiftformat  : Download SwiftFormat for host platform
#   metadata           : Generate metadata/schema.json
#   build              : Build release plugin binary
#   build-debug        : Build debug plugin binary
#   test               : Run testdata snapshot tests
#   fmt                : Format repo with dprint
#   fmt-check          : Check repo formatting
#   lint               : Run cargo clippy and fmt check
#   plugin-json        : Generate plugin.json from build zips
#   release-local      : Create local platform zip
#   bump-version       : Sync VERSION into Cargo.toml and metadata
#   clean              : Remove build artifacts
# -----------------------------------------------------------------------------------------------------------

all: help

SHELL := /bin/bash

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
LOGGER := source $(MAKEFILE_DIR)scripts/log.bash &&
STEPS := bash "$(MAKEFILE_DIR)scripts/make-steps.sh"
RESET := \033[0m
DIM := \033[2m

PLUGIN_BIN := $(MAKEFILE_DIR)target/release/dprint-plugin-swift
PLUGIN_BIN_DEBUG := $(MAKEFILE_DIR)target/debug/dprint-plugin-swift
BUILD_OUTPUT_DIR := $(MAKEFILE_DIR)build
export CARGO_TARGET_DIR := $(MAKEFILE_DIR)target

.PHONY: help check check_rust check_dprint check_swiftformat check_node _check_deps \
	build build-debug test clean fmt fmt-check lint metadata fetch-swiftformat \
	plugin-json release-local bump-version

help: ## Show this help message
	@$(LOGGER) log_banner
	@$(LOGGER) log_info "Available make targets:"
	@echo ""
	@(grep -E '^[[:space:]]*help:.*## .*$$' $(MAKEFILE_LIST) 2>/dev/null; grep -E '^[[:space:]]*[a-zA-Z0-9][a-zA-Z0-9_ -]*:.*## .*$$' $(MAKEFILE_LIST) | grep -v '^[[:space:]]*help:.*##' | sort) | \
		awk -F' ## ' '{ n = index($$1, ":"); target = substr($$1, 1, n-1); gsub(/^[ \t]+|[ \t]+$$/, "", target); desc = $$2; gsub(/^[ \t]+|[ \t]+$$/, "", desc); printf " %-22s$(RESET) $(DIM)- %s$(RESET)\n", target, desc }'
	@echo ""

_check_deps:
	@$(MAKE) --no-print-directory check_rust check_dprint check_swiftformat

check: ## Verify all developer dependencies
	@$(LOGGER) log_target "Checking developer dependencies"
	@$(MAKE) --no-print-directory _check_deps
	@$(LOGGER) log_success "All dependencies OK"

check_rust:
	@if ! command -v cargo >/dev/null 2>&1; then \
		$(LOGGER) log_error "Rust/cargo is not installed. Install from https://rustup.rs"; \
		exit 1; \
	else \
		$(LOGGER) log_indent log_info_dim "$$(cargo --version)"; \
	fi

check_dprint:
	@if ! command -v dprint >/dev/null 2>&1; then \
		$(LOGGER) log_error "dprint is not installed. Install with: curl -fsSL https://dprint.dev/install.sh | sh"; \
		exit 1; \
	else \
		$(LOGGER) log_indent log_info_dim "$$(dprint --version)"; \
	fi

check_swiftformat:
	@if ! command -v swiftformat >/dev/null 2>&1 && [ ! -f "$(MAKEFILE_DIR)vendor/swiftformat/$$(uname -m)-apple-darwin/swiftformat" ] 2>/dev/null; then \
		$(LOGGER) log_indent log_warning "swiftformat not on PATH — run make fetch-swiftformat or install via Homebrew"; \
	else \
		$(LOGGER) log_indent log_info_dim "swiftformat available"; \
	fi

check_node:
	@if ! command -v node >/dev/null 2>&1; then \
		$(LOGGER) log_error "node is not installed (optional unless using npm scripts)"; \
		exit 1; \
	else \
		$(LOGGER) log_indent log_info_dim "$$(node --version)"; \
	fi

metadata: ## Generate metadata/schema.json from VERSION
	@$(LOGGER) log_target "Generating metadata"
	@bash "$(MAKEFILE_DIR)scripts/generate-metadata.sh"
	@$(LOGGER) log_success "Metadata complete"

fetch-swiftformat: ## Download pinned SwiftFormat for host platform
	@$(LOGGER) log_target "Fetching SwiftFormat"
	@bash "$(MAKEFILE_DIR)scripts/fetch-swiftformat.sh"
	@$(LOGGER) log_success "SwiftFormat fetched"

build: ## Build release plugin binary
	@$(LOGGER) log_target "Building dprint-plugin-swift (release)"
	@$(STEPS) build-release

build-debug: ## Build debug plugin binary
	@$(LOGGER) log_target "Building dprint-plugin-swift (debug)"
	@$(STEPS) build-debug

test: ## Run testdata snapshot tests via dprint
	@$(LOGGER) log_target "Running tests"
	@$(STEPS) build-release
	@bash "$(MAKEFILE_DIR)scripts/run-tests.sh"
	@$(LOGGER) log_success "Tests complete"

fmt: ## Format repo with dprint
	@$(LOGGER) log_target "Formatting repository"
	@set -o pipefail; $(LOGGER) log_run_dim dprint fmt
	@$(LOGGER) log_success "Format complete"

fmt-check: ## Check repo formatting (CI)
	@$(LOGGER) log_target "Checking formatting"
	@set -o pipefail; $(LOGGER) log_run_dim dprint check
	@$(LOGGER) log_success "Format check passed"

lint: ## Run cargo clippy and rustfmt check
	@$(LOGGER) log_target "Running lints"
	@$(LOGGER) log_section "Clippy"
	@set -o pipefail; $(LOGGER) log_run_dim cargo clippy -p dprint-plugin-swift -- -D warnings
	@$(LOGGER) log_success "Clippy passed"
	@$(LOGGER) log_section "Rustfmt"
	@set -o pipefail; $(LOGGER) log_run_dim cargo fmt --check
	@$(LOGGER) log_success "Rustfmt passed"

release-local: ## Create local platform zip with bundled swiftformat
	@$(LOGGER) log_target "Creating local release zip"
	@$(STEPS) build-release
	@$(LOGGER) log_section "Packaging"
	@bash "$(MAKEFILE_DIR)scripts/release-local-zip.sh"
	@$(LOGGER) log_success "Release zip created under build/"

plugin-json: ## Generate local test plugin manifest (single platform)
	@$(LOGGER) log_target "Generating local test plugin manifest"
	@$(STEPS) build-release
	@$(LOGGER) log_section "Packaging"
	@bash "$(MAKEFILE_DIR)scripts/release-local-zip.sh"
	@$(LOGGER) log_section "Plugin manifest"
	@bash "$(MAKEFILE_DIR)scripts/create-for-testing.sh"
	@$(LOGGER) log_success "See build/test-plugin.json"

bump-version: ## Sync VERSION into Cargo.toml, metadata/, and README
	@if [ ! -f "$(MAKEFILE_DIR)VERSION" ]; then \
		$(LOGGER) log_error "VERSION file not found. Create it with the desired version (e.g. 0.1.0)"; \
		exit 1; \
	fi
	@$(LOGGER) log_target "Syncing version from VERSION file"
	@$(LOGGER) log_section "Version files"
	@bash "$(MAKEFILE_DIR)scripts/bump-version.sh"
	@$(STEPS) metadata
	@$(LOGGER) log_success "Version bump complete"

clean: ## Remove build artifacts
	@$(LOGGER) log_target "Cleaning build artifacts"
	@$(LOGGER) log_section "Cargo"
	@if command -v cargo >/dev/null 2>&1; then \
		set -o pipefail; $(LOGGER) log_run_dim cargo clean; \
	fi
	@$(LOGGER) log_section "Build output"
	@rm -rf "$(BUILD_OUTPUT_DIR)" "$(MAKEFILE_DIR)plugin.json" "$(MAKEFILE_DIR)latest.json"
	@$(LOGGER) log_indent log_info_dim "Removed build/ and plugin manifests"
	@$(LOGGER) log_success "Clean complete"
