#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/log.bash
source "$ROOT/scripts/log.bash"

VERSION="$(tr -d ' \n\r' < "$ROOT/metadata/VERSION")"
VERSION="${VERSION#v}"

if [[ -z "$VERSION" ]]; then
  log_error "metadata/VERSION is empty — run make bump-version first"
  exit 1
fi

log_indent log_info_dim "Version $VERSION"

cat > "$ROOT/metadata/schema.json" << EOF
{
  "\$schema": "http://json-schema.org/draft-07/schema#",
  "\$id": "https://plugins.dprint.dev/drluckyspin/swiftformat/v${VERSION}/schema.json",
  "title": "SwiftFormat Plugin Configuration",
  "type": "object",
  "properties": {
    "swiftVersion": {
      "type": "string",
      "description": "Swift language version passed to SwiftFormat (--swiftversion)."
    },
    "configPath": {
      "type": "string",
      "description": "Optional path to a .swiftformat config file (--config)."
    },
    "lineWidth": {
      "type": "integer",
      "description": "Maximum line width (--maxwidth). Defaults to dprint global lineWidth."
    },
    "indentWidth": {
      "type": "integer",
      "description": "Indent size in spaces (--indent). Defaults to dprint global indentWidth."
    },
    "useTabs": {
      "type": "boolean",
      "description": "Use tabs for indentation (--tabs enabled). Defaults to dprint global useTabs."
    },
    "options": {
      "type": "object",
      "description": "Passthrough SwiftFormat rule flags as key/value pairs (e.g. semicolons: inline).",
      "additionalProperties": true
    }
  },
  "additionalProperties": false
}
EOF

log_indent log_success "Wrote metadata/schema.json"

if [[ ! -f "$ROOT/metadata/LICENSES" ]]; then
  log_error "metadata/LICENSES is missing"
  exit 1
fi

log_indent log_info_dim "metadata/LICENSES present"
