# Release Checklist

## Prerequisites

- Rust (stable), dprint 0.40+, `make`, `curl`, `unzip`, `zip`, `shasum`
- GitHub Actions secrets not required for v1 (no code signing)

## Standard release (CI — preferred)

1. Set version:

   ```bash
   echo "0.2.0" > VERSION
   make bump-version
   ```

2. Update [CHANGELOG.md](CHANGELOG.md) — move `[Unreleased]` entries to the new version section.

3. Verify locally:

   ```bash
   make check
   make lint
   make test
   make fmt-check
   ```

4. Commit version files (`VERSION`, `plugin/Cargo.toml`, `metadata/`, `README.md`, `CHANGELOG.md`).

5. Push tag:

   ```bash
   git tag v0.2.0
   git push origin v0.2.0
   ```

6. GitHub Actions (`.github/workflows/ci.yml`) runs the 4-platform matrix, uploads zips, and the `release` job publishes:
   - `plugin.json`
   - `latest.json`
   - `schema.json`
   - `dprint-plugin-swift-<target>.zip` (×4)

## CDN URLs

After release, assets are available at:

```text
https://plugins.dprint.dev/drluckyspin/swiftformat-v{version}.json@{plugin.json sha256}
https://plugins.dprint.dev/drluckyspin/swiftformat/{version}/asset/dprint-plugin-swift-{target}.zip
https://plugins.dprint.dev/drluckyspin/swiftformat/latest.json
```

## Local smoke test (no GitHub release)

```bash
make build
make fetch-swiftformat
make release-local
bash scripts/create-plugin-json.sh --test
```

## Troubleshooting

| Problem                                   | Fix                                                                                                 |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------- |
| `swiftformat binary not found` at runtime | Ensure zip contains sibling `swiftformat`; run `make fetch-swiftformat` before `make release-local` |
| dprint rejects plugin URL                 | Process plugins require `@<sha256>` suffix on the manifest URL                                      |
| Tests fail on Linux CI                    | Ensure `fetch-swiftformat.sh` downloaded the correct Linux asset                                    |
| Wrong SwiftFormat version                 | Update `vendor/swiftformat/VERSION` and re-run `make fetch-swiftformat`                             |

## What we do not ship

- Windows builds (macOS + Linux only)
- Wasm plugin artifact

Windows users can use the exec-plugin config documented in [README.md](README.md).
