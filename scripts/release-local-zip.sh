#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

TARGET="${1:-$(rustc -vV 2>/dev/null | sed -n 's/^host: //p')}"
if [[ -z "$TARGET" ]]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) TARGET="aarch64-apple-darwin" ;;
    Darwin-x86_64) TARGET="x86_64-apple-darwin" ;;
    Linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
    Linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
  esac
fi

PLUGIN_BIN="$ROOT/target/release/dprint-plugin-swift"
SF_BIN="$ROOT/vendor/swiftformat/$TARGET/swiftformat"

if [[ ! -f "$PLUGIN_BIN" ]]; then
  log_error "Missing $PLUGIN_BIN"
  exit 1
fi

STAGING="$ROOT/build/release-local/$TARGET"
ZIP="$ROOT/build/dprint-plugin-swift-${TARGET}.zip"
rm -rf "$STAGING" "$ZIP"
mkdir -p "$STAGING"

cp "$PLUGIN_BIN" "$STAGING/dprint-plugin-swift"
if [[ -f "$SF_BIN" ]]; then
  cp "$SF_BIN" "$STAGING/swiftformat"
elif command -v swiftformat >/dev/null 2>&1; then
  cp "$(command -v swiftformat)" "$STAGING/swiftformat"
else
  log_error "No swiftformat binary for $TARGET"
  exit 1
fi

(cd "$STAGING" && zip -qr "$ZIP" .)
log_indent log_success "Created $ZIP"
