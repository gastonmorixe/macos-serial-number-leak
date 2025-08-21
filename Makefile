# Makefile for serial-number (Swift Package)
#
# Usage: `make <target>`
#
# Conventions:
# - Short, memorable targets for common dev tasks
# - Safe defaults; no sudo by default

SHELL := /bin/bash

# Tools
SWIFT ?= swift
XCRUN ?= xcrun
LLVM_COV := $(XCRUN) llvm-cov

# Products
PRODUCT := serial-number
BUILD_DIR := .build
DEBUG_DIR := $(BUILD_DIR)/debug
RELEASE_DIR := $(BUILD_DIR)/release
TEST_BIN := $(DEBUG_DIR)/$(PRODUCT)PackageTests.xctest/Contents/MacOS/$(PRODUCT)PackageTests
PROFILE := $(DEBUG_DIR)/codecov/default.profdata

.PHONY: help build release run run-release test test-coverage coverage coverage-show clean format lint install-local

help: ## Show this help
	@awk -F':.*## ' '/^[a-zA-Z_-]+:.*##/ { printf "\t- %-18s %s\n", $$1, $$2 }' $(MAKEFILE_LIST) | sort

build: ## Build in debug configuration
	$(SWIFT) build

release: ## Build in release configuration
	$(SWIFT) build -c release

run: ## Run the CLI (debug)
	$(SWIFT) run $(PRODUCT)

run-release: release ## Run the CLI (release)
	$(RELEASE_DIR)/$(PRODUCT)

clean: ## Clean build artifacts
	$(SWIFT) package clean || true
	rm -rf $(BUILD_DIR)

# Testing & Coverage

test: ## Run tests
	$(SWIFT) test

test-coverage: ## Run tests with coverage enabled
	$(SWIFT) test --enable-code-coverage

coverage: test-coverage ## Generate a line coverage summary in the terminal
	@echo "Generating coverage report..."
	$(LLVM_COV) report $(TEST_BIN) -instr-profile=$(PROFILE) -use-color=false || \
	  (echo "\nHint: If this fails, run 'make test-coverage' first." && false)

coverage-show: test-coverage ## Show per-line annotated coverage for Sources in terminal
	$(LLVM_COV) show $(TEST_BIN) -instr-profile=$(PROFILE) Sources --ignore-filename-regex=Tests --use-color

# Formatting & Linting (best-effort if tools are installed)

format: ## Run swift-format if available
	@if command -v swift-format >/dev/null 2>&1; then \
	  swift-format format --in-place --recursive .; \
	else \
	  echo "swift-format not installed. Install: 'brew install swift-format'"; \
	fi

lint: ## Run swiftlint if available
	@if command -v swiftlint >/dev/null 2>&1; then \
	  swiftlint; \
	else \
	  echo "SwiftLint not installed. Install: 'brew install swiftlint'"; \
	fi

install-local: release ## Install the CLI into ~/.local/bin (creates directory if needed)
	@mkdir -p $$HOME/.local/bin
	cp $(RELEASE_DIR)/$(PRODUCT) $$HOME/.local/bin/$(PRODUCT)
	@echo "Installed to $$HOME/.local/bin/$(PRODUCT)"