# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-22

### Added

- Initial dprint process plugin wrapping SwiftFormat via stdin and `--stdinpath`
- Config schema for `swiftVersion`, `lineWidth`, `indentWidth`, `useTabs`, and SwiftFormat rule passthrough
- Makefile-driven build, test, lint, and release workflow with Code Red logging
- GitHub Actions CI on macOS and Linux (4 platforms) with tagged release publishing
- Bundled SwiftFormat 0.61.1 per platform zip
- testdata snapshot integration tests via `dprint fmt`

[Unreleased]: https://github.com/drluckyspin/dprint-plugin-swift/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/drluckyspin/dprint-plugin-swift/releases/tag/v0.1.0
