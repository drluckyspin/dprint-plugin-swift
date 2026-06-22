# AGENTS.md — dprint-plugin-swift

Guidance for coding agents working in this repository.

## What This Is

**dprint-plugin-swift** is a dprint **process plugin** (schema v5) that formats Swift by spawning the **SwiftFormat** CLI (`swiftformat stdin --stdinpath <path>`).

- **Not a Wasm plugin** — SwiftFormat cannot be compiled to dprint's Wasm sandbox.
- **Repository:** [github.com/drluckyspin/dprint-plugin-swift](https://github.com/drluckyspin/dprint-plugin-swift)
- **License:** MIT
- **Current version:** see root `VERSION` (synced via `make bump-version`)

### Naming

| Name                 | Value                 | Where used                              |
| -------------------- | --------------------- | --------------------------------------- |
| Repo / Cargo package | `dprint-plugin-swift` | GitHub, binary, `plugin.json` name      |
| dprint config key    | `swiftformat`         | `"swiftformat": { ... }` in dprint.json |
| Process binary       | `dprint-plugin-swift` | Inside platform zip                     |

### Supported platforms (no Windows)

- `darwin-aarch64`, `darwin-x86_64`
- `linux-x86_64`, `linux-aarch64`

## Architecture

```
dprint CLI  ←stdio v5→  dprint-plugin-swift (Rust)  ←subprocess→  swiftformat
```

```text
plugin/src/
  main.rs              # Tokio current-thread + handle_process_stdio_messages
  handler.rs           # AsyncPluginHandler
  config.rs            # Config resolution + CLI arg mapping
  formatter/
    mod.rs
    command.rs         # Build swiftformat argv
    swiftformat.rs     # Subprocess + binary discovery

scripts/               # Bash tooling (source log.bash)
metadata/              # VERSION, schema.json, LICENSES (embedded in plugin)
testdata/              # Snapshot integration tests
vendor/swiftformat/    # Downloaded SwiftFormat binaries (gitignored)
```

### Binary discovery (runtime)

1. `SWIFTFORMAT_PATH` env override (dev)
2. Sibling `swiftformat` next to plugin executable (bundled in zip)
3. `swiftformat` on `PATH`

## Tech Stack

| Item       | Value                                   |
| ---------- | --------------------------------------- |
| Language   | Rust 2021                               |
| dprint API | `dprint-core` 0.68.x, `process` feature |
| Formatter  | SwiftFormat CLI (bundled per platform)  |
| Build      | Cargo workspace + Makefile              |
| Logging    | `scripts/log.bash` (Glide pattern)      |
| Tests      | testdata snapshots via `dprint fmt`     |
| CI         | GitHub Actions, 4-platform matrix       |

## Development Commands

Run from repo root. **`make` is the only entry point** — do not suggest raw `cargo` or `dprint` commands.

```bash
make help               # list targets
make check              # verify Rust, dprint, swiftformat
make fetch-swiftformat  # download SwiftFormat for host
make build              # release build
make build-debug        # debug build
make test               # testdata snapshot tests
make lint               # clippy + rustfmt --check
make fmt                # dprint fmt repo
make fmt-check          # dprint fmt --check (CI)
make bump-version       # sync VERSION → Cargo.toml, metadata, README
make release-local      # zip plugin + swiftformat for host
make plugin-json        # generate test plugin.json
make clean              # remove artifacts
```

Set `VERBOSE=true` for unfiltered command output.

**Note:** Makefile sets `CARGO_TARGET_DIR=./target` so builds land in the repo even when the environment overrides the default.

## Testing

Each `testdata/<case>/` directory contains:

- `input.swift.txt` — source before formatting
- `expected.swift` — golden output
- `dprint.json` — generated at test time pointing at local plugin

`make test` runs `scripts/run-tests.sh` which:

1. Builds plugin via `make build`
2. Creates `build/test-plugin.json` with checksum via `create-for-testing.sh`
3. Runs `dprint fmt` per case and diffs against `expected.swift`

To add a case: create a new folder under `testdata/`, add input/expected (use `swiftformat` to generate expected), run `make test`.

## Version / Release

| File                         | Role                                  |
| ---------------------------- | ------------------------------------- |
| `VERSION`                    | Source of truth for plugin semver     |
| `plugin/Cargo.toml`          | Synced by `make bump-version`         |
| `metadata/VERSION`           | Embedded in plugin info               |
| `vendor/swiftformat/VERSION` | Pinned SwiftFormat release (separate) |

Always run `make bump-version` after editing `VERSION`.

See [RELEASE.md](RELEASE.md) for the full release checklist.

## Agent Guidelines

### Do

- Use **`make`** targets for all build/test/format operations
- Run **`make test`** after Rust changes
- Source **`scripts/log.bash`** in new bash scripts
- Keep changes minimal and focused
- Match existing Rust and Makefile style

### Do not

- Commit `target/`, `build/`, `vendor/swiftformat/**/swiftformat`, or `*.zip`
- Create git commits or PRs unless explicitly requested
- Use branch prefixes other than `feature/`, `fix/`, `chore/`
- Add Windows support (out of scope for v1)
- Suggest compiling SwiftFormat to Wasm

### Common edit locations

| Task                | Files                                              |
| ------------------- | -------------------------------------------------- |
| Formatting behavior | `plugin/src/formatter/swiftformat.rs`              |
| CLI flag mapping    | `plugin/src/config.rs`, `formatter/command.rs`     |
| dprint protocol     | `plugin/src/handler.rs`, `plugin/src/main.rs`      |
| Config schema       | `scripts/generate-metadata.sh`, `metadata/`        |
| Integration tests   | `testdata/`, `scripts/run-tests.sh`                |
| Build / release     | `Makefile`, `scripts/`, `.github/workflows/ci.yml` |
| Version bump        | `VERSION`, `make bump-version`                     |

## Quick Reference

```bash
# Daily dev loop
make fetch-swiftformat && make build && make test

# Before a release
echo "X.Y.Z" > VERSION && make bump-version
make lint && make test && make fmt-check
git tag vX.Y.Z && git push origin vX.Y.Z
```
