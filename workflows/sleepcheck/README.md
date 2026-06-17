# Sleep Check

Diagnoses why your Mac won't go to sleep and cleans up the usual culprit:
an orphaned **Playwright / MCP automation browser** that holds a `"Capturing"`
display-sleep assertion for hours. Shows a confirmation dialog before killing
anything and reports the result as a notification.

[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)](#)
[![Tests](https://img.shields.io/badge/tests-16%20passing-success?style=flat-square)](../../tests/)
[![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen?style=flat-square)](#)

## Why

macOS exposes "power assertions" — flags that keep the system or display
awake. A leftover headless/automation Chrome (started by Playwright or an MCP
browser tool and never closed) keeps a `NoDisplaySleepAssertion "Capturing"`
alive, so the display — and often the whole machine — never sleeps. It can sit
there for 18+ hours unnoticed. This Quick Action finds it and offers to end it.

## Features

- **Lists active sleep blockers** with a human cause tag (caffeinate vs.
  `Capturing` vs. `powerd` vs. background app), so you see *what* is holding
  sleep open
- **Finds orphaned automation browsers** by matching the Playwright/MCP
  signature (`mcp-chrome` user-data-dir, `--remote-debugging-pipe`) — your
  normal browser is never matched
- **Confirmation dialog** listing each process and its runtime before any kill
- **Notification** with the result
- **Read-only by default** on the CLI — `kill` is opt-in
- **Zero dependencies** — `pmset`, `pgrep`, `ps`, `osascript` only

## What it reports (and leaves alone)

| Assertion owner | Treatment |
|-----------------|-----------|
| `caffeinate` (e.g. Claude Code) | Reported, **never killed** — clears when the session ends |
| `powerd "…while display is on"` | Reported as normal |
| `sharingd` (Handoff), background app tasks | Reported as temporary |
| Playwright/MCP Chrome with `"Capturing"` | **Offered for termination** |

**Never touched:** your everyday Chrome/Safari/Firefox, any browser without the
Playwright/MCP automation signature.

## Requirements

None — all built-in macOS tools.

## Install

1. Commit any local changes (`open` will move the workflow files out of this dir).
2. Run:
   ```bash
   open "Sleep Check.workflow"
   ```
3. Click **Install** when macOS prompts.
4. Enable under **System Settings → General → Login Items & Extensions → Finder**.
5. Restore the source files: `git checkout workflows/sleepcheck/`.

## Usage

### As Quick Action

- Right-click any file/folder in Finder → **Quick Actions → Sleep Check**, or
- Assign a keyboard shortcut in *System Settings → Keyboard → Keyboard
  Shortcuts → Services → General*.

It scans, and if it finds orphaned automation browsers it asks whether to end
them; otherwise it just notifies that everything is normal.

### As script

```bash
# Show sleep blockers + orphaned automation browsers (read-only)
./sleepcheck.sh

# Also terminate orphaned Playwright/MCP browsers
./sleepcheck.sh kill

# Version / help
./sleepcheck.sh version
./sleepcheck.sh help
```

### As library (for tests)

The script defines testable functions and only runs `main()` when invoked
directly. Source it to use them:

```bash
source sleepcheck.sh
browser_match_pattern                       # the pgrep ERE
pmset -g assertions | parse_blockers        # filter to real blocker lines
classify_blocker "pid 67577(Google Chrome): … \"Capturing\""
```

## Testing

```bash
# From repo root
./tests/run.sh
```

16 unit tests cover the browser-match pattern, the `parse_blockers` stdin
filter (against a sample `pmset` fixture), `classify_blocker` mapping, the
`help`/`version`/`check` subcommands, and plist validity.

## Safety

- **No `sudo`** — user-scope only.
- **Default is read-only** — nothing is killed unless you choose `kill` (CLI)
  or confirm the dialog (Quick Action).
- **Narrow match** — only processes carrying the Playwright/MCP automation
  signature are candidates; `caffeinate` and system daemons are reported but
  never killed.

## See also

- [CHANGELOG.md](../../CHANGELOG.md) — release history
- [CLAUDE.md](../../CLAUDE.md) — repo-wide conventions
