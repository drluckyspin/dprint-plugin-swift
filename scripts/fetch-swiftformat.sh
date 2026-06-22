#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

VERSION_FILE="$ROOT/vendor/swiftformat/VERSION"
if [[ ! -f "$VERSION_FILE" ]]; then
  log_error "Missing $VERSION_FILE — pin a SwiftFormat release version first"
  exit 1
fi

SF_VERSION="$(tr -d ' \n\r' < "$VERSION_FILE")"
SF_VERSION="${SF_VERSION#v}"

TARGET="${1:-$(uname -m)-$(uname -s | tr '[:upper:]' '[:lower:]')}"
case "$(uname -s)" in
  Darwin)
    case "$(uname -m)" in
      arm64) TARGET="aarch64-apple-darwin" ;;
      x86_64) TARGET="x86_64-apple-darwin" ;;
    esac
    ASSET="swiftformat.zip"
    ;;
  Linux)
    case "$(uname -m)" in
      aarch64|arm64) TARGET="aarch64-unknown-linux-gnu"; ASSET="swiftformat_linux_aarch64.zip" ;;
      x86_64|amd64) TARGET="x86_64-unknown-linux-gnu"; ASSET="swiftformat_linux.zip" ;;
      *) log_error "Unsupported Linux architecture: $(uname -m)"; exit 1 ;;
    esac
    ;;
  *)
    log_error "Unsupported OS: $(uname -s)"
    exit 1
    ;;
esac

if [[ $# -ge 1 ]]; then
  TARGET="$1"
  case "$TARGET" in
    aarch64-apple-darwin|x86_64-apple-darwin) ASSET="swiftformat.zip" ;;
    x86_64-unknown-linux-gnu) ASSET="swiftformat_linux.zip" ;;
    aarch64-unknown-linux-gnu) ASSET="swiftformat_linux_aarch64.zip" ;;
    *)
      log_error "Unsupported target: $TARGET"
      exit 1
      ;;
  esac
fi

DEST_DIR="$ROOT/vendor/swiftformat/$TARGET"
DEST_BIN="$DEST_DIR/swiftformat"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

URL="https://github.com/nicklockwood/SwiftFormat/releases/download/$SF_VERSION/$ASSET"

log_indent log_info_dim "SwiftFormat $SF_VERSION for $TARGET"
log_indent log_info_dim "$URL"

mkdir -p "$DEST_DIR"
curl -fsSL "$URL" -o "$TMP_DIR/asset.zip"
unzip -qo "$TMP_DIR/asset.zip" -d "$TMP_DIR/extract"

FOUND="$(find "$TMP_DIR/extract" -type f \( -name swiftformat -o -name SwiftFormat \) | head -1)"
if [[ -z "$FOUND" ]]; then
  log_error "Could not find swiftformat binary in $ASSET"
  exit 1
fi

cp "$FOUND" "$DEST_BIN"
chmod +x "$DEST_BIN"
log_indent log_success "Installed $DEST_BIN"
