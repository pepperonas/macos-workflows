# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of macOS Finder Quick Actions (Automator `.workflow` bundles) for image and text processing. Each workflow lives in `workflows/<name>/` with a `.workflow` bundle and optionally a README, build script, or source files.

## Workflow Architecture

Every workflow is an Automator service bundle containing a `document.wflow` (plist XML) that wraps a shell script action. Two workflow types exist:

- **File workflows** — Accept `com.apple.Automator.fileSystemObject` / `public.item`. Process images and save new files with a suffix (e.g. `-w1024`, `-free`, `_clean`) next to the original. Never modify the original.
- **Text workflows** — Accept `public.utf8-plain-text` via stdin (`inputMethod: 0`). Pipe result to `pbcopy` (clipboard).

Scripts are either embedded directly in the `.wflow` XML or call an external compiled binary (remove-background, qr-code).

## Adding a New Workflow

Follow the existing pattern:
1. Create `workflows/<name>/` with a `<Name>.workflow/Contents/` bundle containing `document.wflow` and `Info.plist`
2. Use an existing workflow as template — copy the plist XML structure, change UUIDs, script content, and service name
3. Shell is `/bin/zsh`, input passed as arguments (`inputMethod: 1`) for file workflows or stdin (`inputMethod: 0`) for text workflows
4. In `.wflow` XML, `>` must be escaped as `&gt;` (e.g. `2&gt;/dev/null` for stderr redirect)
5. Scripts using `python3` must set `export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"` at the top — Automator uses a stripped PATH that only finds `/usr/bin/python3` (system Python without pip packages)
6. Add entry to the appropriate table (Image / Text / File & Utility) in root `README.md`, and give the workflow its own `README.md` — `tests/test-repo.sh` fails on undocumented or unlinked workflows
7. For workflows with a standalone CLI script, follow the LoC pattern: keep the shared logic in a marked `QUICK ACTION CORE` block in the `.sh`, generate the `.wflow`'s `COMMAND_STRING` from it (XML-escape `&`, `<`, `>`, append the entry-point call), and pin both sides with a byte-for-byte drift-guard test. Write the core bash-3.2 AND zsh compatible (Automator runs `/bin/zsh`): no `${var,,}`, no array index arithmetic, quote everything.

## Installing Workflows

**Important:** Do NOT manually copy `.workflow` bundles into `~/Library/Services/`. Manually copied workflows are not properly registered by macOS and will not appear in Finder Quick Actions. Always install by either:
- Double-clicking the `.workflow` file (triggers Automator install dialog), or
- `open "Name.workflow"` from the terminal

**Caveat:** `open "Name.workflow"` moves (not copies) the files from the source directory into `~/Library/Services/`. This means the original files in the repo disappear. Always commit before running `open` to install, or restore with `git checkout` afterwards.

**If a bundle is already lost** (empty `workflows/<name>/` dir, nothing tracked in git — happened to new-textfile): the installed copy in `~/Library/Services/<Name>.workflow` IS the bundle. Copy it back with `cp -R` + `xattr -cr` and commit. `tests/test-repo.sh` (`test_repo_every_workflow_has_bundle`) now turns red when a bundle goes missing.

After installation, enable under **System Settings > General > Login Items & Extensions > Finder**.

## Build

Two workflows require compilation (Swift binaries):

```bash
cd workflows/remove-background && ./build.sh
cd workflows/qr-code && ./build.sh
```

Each compiles a Swift source file and installs the binary to `~/Library/Services/`. All other workflows have no build step.

## Testing

Plain-bash test suite under `tests/`. No external deps. Run with `./tests/run.sh`.

- Tests source the script under test (`source "$REPO_ROOT/workflows/<name>/<name>.sh"`)
- For scripts that need to be source-safe, guard `main()` with
  `if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then main "$@"; fi`
- Test files: `tests/test-<workflow>.sh` — each `test_*` function is auto-discovered
- Helpers exported from `tests/run.sh`: `assert_equal`, `assert_contains`, `assert_success`
- Always include `plutil -lint` checks for `Info.plist` and `document.wflow`
- `tests/test-repo.sh` holds repo-wide invariants (every workflow has bundle + README + root-README link, plists lint, menu names unique, README badges match `VERSION`/CHANGELOG/suite size) — after adding a workflow or bumping the version, run the suite; a stale badge fails it
- Helper functions in test files must not start with `test_` (the runner executes every `test_*` function); prefix with `_`
- Pin behavior against comment-free source (a comment quoting the old code satisfies a naive substring check) and mutate every new pin once to see it red
- See `tests/README.md` for the test authoring guide

## Versioning

- Repo version in `VERSION` (Semantic Versioning)
- Release notes in `CHANGELOG.md` (Keep a Changelog format)
- Tag releases as `vMAJOR.MINOR.PATCH`
- When changing a workflow, bump `VERSION` and add a `CHANGELOG.md` entry

## Key Technical Details

- All `.workflow` bundles use Automator version 2.10 (build 534), `AMDocumentVersion` 2
- The `Info.plist` defines the service name, input types (`NSSendFileTypes` or `NSSendTypes`), and icon
- Python-based workflows embed the full Python script inline in the `.wflow` via heredoc (`<<'PYEOF'`)
- Compiled Swift binaries (`remove_background`, `qr_code`) are git-ignored; only `.swift` sources are tracked
- For metadata reading, use `file` + `stat` + `sips -g all` instead of `mdls` — `mdls` fails on files not indexed by Spotlight
- `open "Name.workflow"` for installation moves files out of the repo — always commit first or restore with `git checkout` after
- File workflows that don't process specific file types (e.g. Cleanup Caches, Sleep Check) must still accept `fileSystemObject` input to appear in Finder Quick Actions — `com.apple.Automator.nothing` input types won't show up in the context menu; restrict `NSSendFileTypes` to `public.folder` for folder-only actions (LoC)
- `COMMAND_STRING` appears TWICE in a `document.wflow` — an empty `AMParameterProperties` declaration first, the real script under `ActionParameters`. Any extraction (tests, tooling) must anchor on the `ActionParameters` block
- Result popups: `display notification` gives scripts NO control over banner duration, the hover "Einblenden" button, or what a click opens (Script Editor). When those matter, use `display dialog … giving up after N` with a single OK button instead (LoC does; Cleanup Caches/Sleep Check use dialogs for confirmation)
- Shell scripts that format numbers (`printf %.1f`, `bc`) MUST `export LC_NUMERIC=C` to avoid German locale comma decimal separators breaking `printf`
- Avoid `set -o pipefail` in scripts that pipe `du`/other potentially-partial commands — use `var=$(cmd) || true` plus `awk 'END{...}'` for robustness instead
