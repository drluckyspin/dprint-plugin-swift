#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

BUILD_TYPE="${BUILD_TYPE:-release}"
if [[ "$BUILD_TYPE" == "debug" ]]; then
  PLUGIN_BIN="$ROOT/target/debug/dprint-plugin-swift"
else
  PLUGIN_BIN="$ROOT/target/release/dprint-plugin-swift"
fi

if [[ ! -f "$PLUGIN_BIN" ]]; then
  log_error "Plugin binary not found at $PLUGIN_BIN — run make build first"
  exit 1
fi

HOST_TARGET="$(rustc -vV 2>/dev/null | sed -n 's/^host: //p' || true)"
if [[ -z "$HOST_TARGET" ]]; then
  case "$(uname -s)-$(uname -m)" in
    Darwin-arm64) HOST_TARGET="aarch64-apple-darwin" ;;
    Darwin-x86_64) HOST_TARGET="x86_64-apple-darwin" ;;
    Linux-x86_64) HOST_TARGET="x86_64-unknown-linux-gnu" ;;
    Linux-aarch64) HOST_TARGET="aarch64-unknown-linux-gnu" ;;
    *) log_error "Could not determine host target"; exit 1 ;;
  esac
fi

case "$HOST_TARGET" in
  aarch64-apple-darwin) PLATFORM="darwin-aarch64" ;;
  x86_64-apple-darwin) PLATFORM="darwin-x86_64" ;;
  x86_64-unknown-linux-gnu) PLATFORM="linux-x86_64" ;;
  aarch64-unknown-linux-gnu) PLATFORM="linux-aarch64" ;;
  *) log_error "Unsupported host target: $HOST_TARGET"; exit 1 ;;
esac

STAGING="$ROOT/build/test-plugin"
rm -rf "$STAGING"
mkdir -p "$STAGING"

cp "$PLUGIN_BIN" "$STAGING/dprint-plugin-swift"

SF_BIN="$ROOT/vendor/swiftformat/$HOST_TARGET/swiftformat"
if [[ -f "$SF_BIN" ]]; then
  cp "$SF_BIN" "$STAGING/swiftformat"
else
  SF_PATH="$(command -v swiftformat || true)"
  if [[ -n "$SF_PATH" ]]; then
    cp "$SF_PATH" "$STAGING/swiftformat"
    log_indent log_warning "Using swiftformat from PATH ($SF_PATH) — run make fetch-swiftformat for bundled binary"
  else
    log_indent log_warning "No bundled swiftformat — plugin will require swiftformat on PATH or SWIFTFORMAT_PATH"
  fi
fi

ZIP_NAME="dprint-plugin-swift-${HOST_TARGET}.zip"
(cd "$STAGING" && zip -qr "$ROOT/build/$ZIP_NAME" .)

ZIP_CHECKSUM="$(shasum -a 256 "$ROOT/build/$ZIP_NAME" | awk '{print $1}')"

cat > "$ROOT/build/test-plugin.json" << EOF
{
  "schemaVersion": 2,
  "kind": "process",
  "name": "dprint-plugin-swift",
  "version": "$(tr -d ' \n\r' < "$ROOT/metadata/VERSION")",
  "$PLATFORM": {
    "reference": "file://$ROOT/build/$ZIP_NAME",
    "checksum": "$ZIP_CHECKSUM"
  }
}
EOF

PLUGIN_CHECKSUM="$(shasum -a 256 "$ROOT/build/test-plugin.json" | awk '{print $1}')"
echo "$PLUGIN_CHECKSUM" > "$ROOT/build/test-plugin.json.checksum"

log_indent log_success "Wrote build/test-plugin.json"
log_indent log_info_dim "Platform: $PLATFORM"
log_indent log_info_dim "Checksum: $PLUGIN_CHECKSUM"
