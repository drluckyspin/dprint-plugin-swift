#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

if ! command -v dprint >/dev/null 2>&1; then
  log_error "dprint is not installed"
  exit 1
fi

log_section "Test plugin"
bash "$ROOT/scripts/create-for-testing.sh"

log_section "Test cases"
PLUGIN_JSON="$ROOT/build/test-plugin.json"
PLUGIN_CHECKSUM="$(cat "$ROOT/build/test-plugin.json.checksum")"
PLUGIN_REF="file://$PLUGIN_JSON@$PLUGIN_CHECKSUM"
FAILED=0

for CASE_DIR in "$ROOT"/testdata/*/; do
  CASE_NAME="$(basename "$CASE_DIR")"
  INPUT="$CASE_DIR/input.swift.txt"
  EXPECTED="$CASE_DIR/expected.swift"
  WORK="$CASE_DIR/test.swift"

  if [[ ! -f "$INPUT" || ! -f "$EXPECTED" ]]; then
    log_indent log_warning "Skipping $CASE_NAME — missing input or expected file"
    continue
  fi

  cp "$INPUT" "$WORK"

  cat > "$CASE_DIR/dprint.json" << EOF
{
  "swiftformat": {},
  "plugins": [
    "$PLUGIN_REF"
  ]
}
EOF

  if (cd "$CASE_DIR" && dprint fmt --incremental=false --log-level=silent test.swift); then
    if diff -u "$EXPECTED" "$WORK" >/dev/null; then
      log_indent log_success "$CASE_NAME"
    else
      log_error "$CASE_NAME failed — output differs from expected.swift"
      diff -u "$EXPECTED" "$WORK" || true
      FAILED=1
    fi
  else
    log_error "$CASE_NAME failed — dprint fmt errored"
    FAILED=1
  fi

  rm -f "$WORK" "$CASE_DIR/dprint.json"
done

if [[ "$FAILED" -ne 0 ]]; then
  exit 1
fi
