# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.5.0] — 2026-08-23

### Added
- **LoC Chart** — new File & Utility Quick Action (folders only): same
  counting engine as LoC, but the result appears as a **floating HUD
  panel** (dark blur, rounded, slides in top-right) with an **animated
  per-language bar chart** in language brand colors (~28 mapped, fallback
  palette otherwise), big total, file count, and a gray "Sonstige"
  aggregate beyond the top 5. Click anywhere to dismiss (opens nothing);
  auto-closes after 30 s. The panel is a compiled AppKit binary
  (`loc_display.swift`, `./build.sh`, no third-party code) and runs
  detached via `nohup … &` so Finder's spinner stops immediately.
- **LoC Chart fallback**: without the compiled panel the Quick Action
  still works — self-dismissing dialog with Unicode block bars
  (`bar_of`, pure shell).
- **loc.sh**: new `chart` subcommand (`LOC_VERSION` 1.2.0); both bundles
  are generated from the same `QUICK ACTION CORE`, each pinned by its own
  byte-for-byte drift-guard test.
- 6 new tests (bar proportions/clamping, UI-free fallback rendering via
  stubbed `notify` + empty `$HOME`, panel-preference pin, chart bundle
  plists, chart drift guard) — suite now 81 tests.

## [1.4.0] — 2026-08-23

### Added
- **README.md for every workflow** — all 20 workflows now ship their own
  documentation (behavior, example output, how it works, requirements,
  install caveat). Previously only 6 had one.
- **Repo-wide invariants suite** `tests/test-repo.sh` (13 tests): every
  workflow dir has a `.workflow` bundle (catches the `open`-install
  move-out) and a README, all plists pass `plutil -lint`, service menu
  names are unique, every service declares input types, `python3` scripts
  export a Homebrew-aware PATH, Automator version is pinned, and the root
  README's workflow count, version badge, tests badge, and `CHANGELOG.md`
  all agree with reality — a stale badge fails the suite.
- **LoC**: contract test pinning the self-dismissing result dialog
  (checked against comment-free source).
- README: badges for Zsh, top language, code size, repo size,
  contributors, commit activity, per-workflow docs, and plist linting;
  Testing section now documents the three coverage layers.
- `tests/README.md`: test-layer overview and a "pitfalls" section
  (comment-free pins, mutate-every-new-pin, the double `COMMAND_STRING`
  in `.wflow` files).
- `CLAUDE.md`: LoC core-embedding pattern, bundle-recovery procedure,
  notification-vs-dialog rule, repo-invariant conventions.

### Changed
- **LoC**: result is now a **self-dismissing dialog** (30 s, single OK
  button) instead of `display notification` — macOS gives scripts no
  control over a banner's duration, its hover "Einblenden" button, or
  what a click opens (Script Editor). The dialog stays readable, and
  dismissing it opens nothing. (`LOC_VERSION` 1.1.0)

### Fixed
- README claimed 18 (then 19) workflows while the repo contains 20 — an
  off-by-one dating back to 1.0.0 ("17 Quick Actions" listing 18 items).
  `test_repo_readme_count_matches_dirs` now pins the claim to the actual
  directory count.
- **New Textfile**: the `.workflow` bundle was missing from the repo —
  a past `open`-install had *moved* it to `~/Library/Services/` and it
  was never restored. Recovered from the installed copy; the new
  `test_repo_every_workflow_has_bundle` guards against a repeat.

## [1.3.0] — 2026-08-23

### Added
- **LoC** — new File & Utility Quick Action (folders only) that counts
  source-code lines in the selected folder(s) and shows the result as a
  macOS notification: total non-empty lines, file count, and the top 3
  languages. Only files with a source-code extension count; VCS/dependency/
  build dirs (`.git`, `node_modules`, `venv`, `dist`, `build`, `vendor`, …)
  and minified/bundled files (`*.min.js`, `*.bundle.js`) are skipped.
  Comments count, blank lines don't. Zero dependencies (`find` + `awk`).
- **LoC**: standalone `loc.sh` CLI with a per-language breakdown report,
  plus `notify`, `version`, and `help` subcommands.
- **LoC**: the Quick Action script is embedded from a marked
  `QUICK ACTION CORE` block in `loc.sh` (bash 3.2 + zsh compatible);
  a drift-guard test re-derives the embedded script from `loc.sh` and
  fails if the two ever diverge.
- 23 unit tests for LoC (whitelist/prune lists, pure path filter, thousands
  formatting, top-language line, fixture-tree end-to-end counts, plist
  validity, wflow↔CLI drift guard) — suite now 61 tests.

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

[Unreleased]: https://github.com/pepperonas/macos-workflows/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/pepperonas/macos-workflows/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/pepperonas/macos-workflows/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/pepperonas/macos-workflows/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/pepperonas/macos-workflows/compare/v1.1.1...v1.2.0
[1.1.1]: https://github.com/pepperonas/macos-workflows/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/pepperonas/macos-workflows/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/pepperonas/macos-workflows/releases/tag/v1.0.0
