#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

if [[ ! -f "$ROOT/VERSION" ]]; then
  log_error "VERSION file not found"
  exit 1
fi

V="$(tr -d ' \n\r' < "$ROOT/VERSION")"
V="${V#v}"

if [[ -z "$V" ]]; then
  log_error "VERSION file is empty"
  exit 1
fi

log_indent log_info_dim "Setting version to $V"

sed -i '' "s/^version = \".*\"/version = \"$V\"/" "$ROOT/plugin/Cargo.toml"
log_indent log_success "Updated plugin/Cargo.toml"

echo "$V" > "$ROOT/metadata/VERSION"
log_indent log_success "Updated metadata/VERSION"

if [[ -f "$ROOT/README.md" ]]; then
  sed -i '' "s|swiftformat-v[0-9.]*\.json|swiftformat-v${V}.json|g" "$ROOT/README.md"
  log_indent log_success "Updated README.md plugin URL"
fi
