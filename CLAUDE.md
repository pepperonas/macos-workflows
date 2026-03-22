# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of macOS Finder Quick Actions (Automator `.workflow` bundles) for image and text processing. Each workflow lives in `workflows/<name>/` with a `.workflow` bundle and optionally a README, build script, or source files.

## Workflow Architecture

Every workflow is an Automator service bundle containing a `document.wflow` (plist XML) that wraps a shell script action. Two workflow types exist:

- **File workflows** — Accept `com.apple.Automator.fileSystemObject` / `public.item`. Process images and save new files with a suffix (e.g. `-w1024`, `-free`, `_clean`) next to the original. Never modify the original.
- **Text workflows** — Accept `public.utf8-plain-text` via stdin (`inputMethod: 0`). Pipe result to `pbcopy` (clipboard).

Scripts are either embedded directly in the `.wflow` XML or call an external compiled binary (remove-background).

## Adding a New Workflow

Follow the existing pattern:
1. Create `workflows/<name>/` with a `<Name>.workflow/Contents/` bundle containing `document.wflow` and `Info.plist`
2. Use an existing workflow as template — copy the plist XML structure, change UUIDs, script content, and service name
3. Shell is `/bin/zsh`, input passed as arguments (`inputMethod: 1`) for file workflows or stdin (`inputMethod: 0`) for text workflows
4. In `.wflow` XML, `>` must be escaped as `&gt;` (e.g. `2&gt;/dev/null` for stderr redirect)
5. Add entry to the table in root `README.md`

## Installing Workflows

**Important:** Do NOT manually copy `.workflow` bundles into `~/Library/Services/`. Manually copied workflows are not properly registered by macOS and will not appear in Finder Quick Actions. Always install by either:
- Double-clicking the `.workflow` file (triggers Automator install dialog), or
- `open "Name.workflow"` from the terminal

After installation, enable under **System Settings > General > Login Items & Extensions > Finder**.

## Build

Only `remove-background` requires compilation:

```bash
cd workflows/remove-background && ./build.sh
```

This compiles `remove_background.swift` and installs the binary to `~/Library/Services/remove_background`. All other workflows have no build step.

## Key Technical Details

- All `.workflow` bundles use Automator version 2.10 (build 534), `AMDocumentVersion` 2
- The `Info.plist` defines the service name, input types (`NSSendFileTypes` or `NSSendTypes`), and icon
- Python-based workflows embed the full Python script inline in the `.wflow` via heredoc (`<<'PYEOF'`)
- The compiled `remove_background` binary is git-ignored; only the `.swift` source is tracked
