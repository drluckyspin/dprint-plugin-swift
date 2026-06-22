#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

MAKE=(make --no-print-directory -C "$ROOT")

run_check_deps() {
  log_section "Checking developer dependencies"
  "${MAKE[@]}" _check_deps
  log_success "All dependencies OK"
}

run_metadata() {
  log_section "Generating metadata"
  bash "$ROOT/scripts/generate-metadata.sh"
  log_success "Metadata complete"
}

run_compile_release() {
  log_section "Compiling"
  set -o pipefail
  log_run_dim cargo build --release -p dprint-plugin-swift
  log_success "Build complete"
}

run_compile_debug() {
  log_section "Compiling"
  set -o pipefail
  log_run_dim cargo build -p dprint-plugin-swift
  log_success "Debug build complete"
}

run_build_release() {
  run_check_deps
  run_metadata
  run_compile_release
}

run_build_debug() {
  run_check_deps
  run_metadata
  run_compile_debug
}

case "${1:-}" in
  check-deps) run_check_deps ;;
  metadata) run_metadata ;;
  compile-release) run_compile_release ;;
  compile-debug) run_compile_debug ;;
  build-release) run_build_release ;;
  build-debug) run_build_debug ;;
  *)
    log_error "Unknown make step: ${1:-}"
    exit 1
    ;;
esac
