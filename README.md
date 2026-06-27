# dprint-plugin-swift

A [dprint](https://dprint.dev/) **process plugin** that formats Swift using [SwiftFormat](https://github.com/nicklockwood/SwiftFormat).

Supported platforms: **macOS** (Apple Silicon + Intel) and **Linux** (x86_64 + aarch64). Windows is not supported in v1.

Requires **dprint 0.40+** (process plugin schema v5).

## Quick start (plugin)

Add to your `dprint.json`:

```jsonc
{
  "swiftformat": {
    "swiftVersion": "5.9"
  },
  "plugins": [
    "https://plugins.dprint.dev/drluckyspin/swiftformat-v0.1.0.json@<checksum>"
  ]
}
```

You can also keep a `.swiftformat` file in your project — the plugin passes `--stdinpath` so SwiftFormat discovers it automatically.

## Quick start (exec plugin MVP)

If you already have `swiftformat` on your PATH and want to try formatting before installing this plugin:

```jsonc
{
  "exec": {
    "commands": [
      {
        "command": "swiftformat stdin --stdinpath {{file_path}}",
        "exts": ["swift"],
        "cacheKeyFiles": [".swiftformat"]
      }
    ]
  },
  "plugins": [
    "https://plugins.dprint.dev/exec-0.6.2.json"
  ]
}
```

Smoke test:

```bash
echo 'struct Example{let x:Int}' | swiftformat stdin --stdinpath /tmp/Example.swift
```

## Configuration

See [metadata/schema.json](metadata/schema.json) for the full schema.

| Property       | Description                               |
| -------------- | ----------------------------------------- |
| `swiftVersion` | Swift language version (`--swiftversion`) |
| `configPath`   | Explicit `.swiftformat` path (`--config`) |
| `lineWidth`    | Max line width (`--maxwidth`)             |
| `indentWidth`  | Indent size (`--indent`)                  |
| `useTabs`      | Use tabs (`--tabs enabled`)               |
| `options`      | Passthrough SwiftFormat rule flags        |

dprint global settings (`lineWidth`, `indentWidth`, `useTabs`) are applied when not overridden in the plugin section.

## SwiftFormat version matrix

| Plugin version | Bundled SwiftFormat |
| -------------- | ------------------- |
| 0.1.0          | 0.61.1              |

## Development

All commands run through `make` (see `make help`).

```bash
make check              # verify Rust, dprint, swiftformat
make fetch-swiftformat  # download SwiftFormat for host platform
make build              # build release plugin
make test               # run testdata snapshot tests
make lint               # clippy + rustfmt
make bump-version       # sync VERSION → Cargo.toml, metadata, README
```

Pin the plugin version in the root `VERSION` file, then run `make bump-version`.

## License

MIT — see [LICENSE](LICENSE). SwiftFormat is MIT-licensed and bundled in platform releases.

<p align="center">
	<a href="https://github.com/catppuccin/catppuccin/blob/main/LICENSE"><img src="https://img.shields.io/static/v1.svg?style=for-the-badge&label=License&message=MIT&logoColor=d9e0ee&colorA=363a4f&colorB=b7bdf8"/></a>
</p>
