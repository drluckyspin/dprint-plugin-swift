#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

VERSION="$(tr -d ' \n\r' < "$ROOT/metadata/VERSION")"
VERSION="${VERSION#v}"
IS_TEST=false
OUTPUT="$ROOT/plugin.json"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)
      IS_TEST=true
      OUTPUT="$ROOT/build/plugin.json"
      shift
      ;;
    *)
      log_error "Unknown argument: $1"
      exit 1
      ;;
  esac
done

target_for_platform() {
  case "$1" in
    darwin-x86_64) echo "x86_64-apple-darwin" ;;
    darwin-aarch64) echo "aarch64-apple-darwin" ;;
    linux-x86_64) echo "x86_64-unknown-linux-gnu" ;;
    linux-aarch64) echo "aarch64-unknown-linux-gnu" ;;
    *) return 1 ;;
  esac
}

mkdir -p "$(dirname "$OUTPUT")"

{
  printf '{\n'
  printf '  "schemaVersion": 2,\n'
  printf '  "kind": "process",\n'
  printf '  "name": "dprint-plugin-swift",\n'
  printf '  "version": "%s"' "$VERSION"

  FIRST=true
  for PLATFORM in darwin-x86_64 darwin-aarch64 linux-x86_64 linux-aarch64; do
    TARGET="$(target_for_platform "$PLATFORM")"
    ZIP="$ROOT/build/dprint-plugin-swift-${TARGET}.zip"

    if [[ ! -f "$ZIP" ]]; then
      log_error "Missing zip: $ZIP"
      exit 1
    fi

    CHECKSUM="$(shasum -a 256 "$ZIP" | awk '{print $1}')"
    if [[ "$IS_TEST" == true ]]; then
      REF="file://$ZIP"
    else
      REF="https://plugins.dprint.dev/drluckyspin/swiftformat/${VERSION}/asset/dprint-plugin-swift-${TARGET}.zip"
    fi

    if [[ "$FIRST" == true ]]; then
      FIRST=false
    else
      printf ',\n'
    fi

    printf '  "%s": {\n' "$PLATFORM"
    printf '    "reference": "%s",\n' "$REF"
    printf '    "checksum": "%s"\n' "$CHECKSUM"
    printf '  }'
  done

  printf '\n}\n'
} > "$OUTPUT"

log_success "Wrote $OUTPUT"

if [[ "$IS_TEST" == false ]]; then
  PLUGIN_CHECKSUM="$(shasum -a 256 "$OUTPUT" | awk '{print $1}')"
  cat > "$ROOT/latest.json" << EOF
{
  "schemaVersion": 1,
  "url": "https://plugins.dprint.dev/drluckyspin/swiftformat-v${VERSION}.json",
  "version": "${VERSION}",
  "checksum": "${PLUGIN_CHECKSUM}"
}
EOF
  log_success "Wrote latest.json"
fi
