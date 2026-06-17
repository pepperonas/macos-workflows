# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] — 2026-06-17

### Added
- **Sleep Check** — new File & Utility Quick Action that diagnoses why the Mac
  won't sleep. Lists active power assertions with a human cause tag and finds
  orphaned Playwright/MCP automation browsers (`mcp-chrome`,
  `--remote-debugging-pipe`) that hold a `"Capturing"` display-sleep assertion
  for hours, offering to terminate them via a confirmation dialog. `caffeinate`
  and system daemons are reported but never killed.
- **Sleep Check**: standalone `sleepcheck.sh` CLI with `check` (default, read-only),
  `kill`, `version`, and `help` subcommands.
- 16 unit tests for Sleep Check (browser-match pattern, `parse_blockers` stdin
  filter against a `pmset` fixture, `classify_blocker` mapping, subcommands,
  plist validity) — suite now 38 tests.

## [1.1.1] — 2026-06-16

### Fixed
- **Resize to w1024px**: no longer fails with `Error 13: Cannot rename
  temporary file` when an output file already exists. The Automator sandbox
  only grants write access to selected and newly-created files, so `sips`
  could not overwrite a pre-existing `-w1024` file. The action now picks a
  free output name (`-w1024-1`, `-w1024-2`, …) instead of overwriting.

## [1.1.0] — 2026-05-16

### Added
- **Cleanup Caches**: pre-execution confirmation dialog with size preview
- **Cleanup Caches**: `sizes` mode — preview what would be cleaned without deleting
- **Cleanup Caches**: `version` and `help` subcommands on the CLI
- **Cleanup Caches**: `~/Library/Logs` and `~/.pm2/logs` as cleanup targets
- **Cleanup Caches**: `brew cleanup -s` and `npm cache clean --force` integration
- **Cleanup Caches**: macOS notification with freed bytes after completion
- Plain-bash unit test suite under `tests/` (22 tests, no external deps)
- `tests/run.sh` test runner with colored output
- `VERSION` file and this `CHANGELOG.md`
- `LC_NUMERIC=C` enforcement for locale-independent number formatting

### Changed
- **Cleanup Caches**: refactored into testable functions (`bytes_to_human`,
  `dir_size_bytes`, `cleanup_targets`, `free_disk_summary`, `cmd_*`)
- **Cleanup Caches**: removed `pipefail` to handle `du` permission errors gracefully
- **Cleanup Caches**: `dir_size_bytes` now uses `awk 'END{...}'` for resilience
  against partial `du` output

### Fixed
- **Cleanup Caches**: `du` permission errors on protected cache subfolders
  (e.g. `com.apple.HomeKit`) no longer cause size lookups to return `0`
- **Cleanup Caches**: German locale (comma decimal separator) no longer breaks
  `printf "%.1f"` for GB-sized values

## [1.0.0] — 2026-03-26

### Added
- Initial release with 17 Quick Actions:
  - **Image**: Remove Background, Remove Nano Banana Watermark, Optimize Image,
    Resize to w1024px, Strip EXIF, Add Rounded Corners, Add Drop Shadow, QR Code
  - **Text**: JSON Prettify, Convert Case, WhatsApp Line Wrap, Remove Vowels,
    Text Statistics
  - **File & Utility**: Copy File Path, Copy Metadata, Copy Folder Tree,
    New Textfile, Cleanup Caches

[Unreleased]: https://github.com/pepperonas/macos-workflows/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/pepperonas/macos-workflows/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/pepperonas/macos-workflows/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/pepperonas/macos-workflows/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pepperonas/macos-workflows/releases/tag/v1.0.0
