# Cleanup Caches

Frees disk space by clearing macOS / npm / Gradle caches, user logs and PM2
logs — with a confirmation dialog showing exact sizes beforehand and a
notification showing freed bytes afterwards.

[![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)](#)
[![Tests](https://img.shields.io/badge/tests-22%20passing-success?style=flat-square)](../../tests/)
[![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen?style=flat-square)](#)

## Features

- **Confirmation dialog** with per-target size preview before any deletion
- **Notification** with freed bytes and remaining free disk space afterwards
- **Sizes-only mode** to preview without deleting
- **Local + remote** PM2 log flushing (raspi3, raspi2 — skipped if unreachable)
- **Tooling integration**: `brew cleanup -s`, `npm cache clean --force`
- **Locale-safe** (`LC_NUMERIC=C` so German commas don't break `printf %.1f`)
- **Permission-resilient** (`du` errors on protected cache subfolders no
  longer return `0`)

## What it cleans

| Target | Contents |
|--------|----------|
| `~/Library/Caches/` | macOS application caches (Spotify, Chrome, WhatsApp, …) |
| `~/.npm/_cacache/` | npm package cache |
| `~/.gradle/caches/` | Gradle build caches |
| `~/Library/Logs/` | User application logs |
| `~/.pm2/logs/` | PM2 process log files |

Plus:
- `pm2 flush` — local PM2 log truncation
- `npm cache clean --force` — npm cache invalidation
- `brew cleanup -s` — old Homebrew formulae + cache
- `ssh raspi3 'pm2 flush'` — remote PM2 logs (skipped if host unreachable)
- `ssh raspi2 'sudo pm2 flush'` — remote PM2 logs (lichtwerk needs sudo)

**Never touched:** Browser logins, cookies, documents, mail, iCloud Drive,
`~/Documents`, `node_modules`, SSH keys, `/Library/` (system).

## Requirements

None — uses built-in tools (`du`, `df`, `rm`, `awk`, `bc`, `osascript`).
SSH aliases `raspi3` / `raspi2` are optional (cleanup degrades gracefully
when unreachable).

## Install

1. Commit any local changes (`open` will move the workflow files out of this dir).
2. Run:
   ```bash
   open "Cleanup Caches.workflow"
   ```
3. Click **Install** when macOS prompts.
4. Enable under **System Settings → General → Login Items & Extensions → Finder**.
5. Restore the source files: `git checkout workflows/cleanup-caches/`.

## Usage

### As Quick Action

- Apple menu → **Services → Cleanup Caches**
- Or assign a keyboard shortcut in *System Settings → Keyboard → Keyboard
  Shortcuts → Services → General* (e.g. `⌃⌥⌘ P`)

### As script

```bash
# Run with confirmation (same UX as Quick Action, but in terminal)
./cleanup-caches.sh

# Preview what would be cleaned, without deleting
./cleanup-caches.sh sizes

# Show version
./cleanup-caches.sh version

# Help
./cleanup-caches.sh help
```

### As library (for tests)

The script defines testable functions and only runs `main()` when invoked
directly. Source it to use the functions:

```bash
source cleanup-caches.sh
bytes_to_human 1073741824   # → "1.0 GB"
dir_size_bytes "$HOME/.npm/_cacache"
```

## Testing

```bash
# From repo root
./tests/run.sh
```

22 unit tests cover `bytes_to_human`, `dir_size_bytes`, target enumeration,
plist validity, and the `help`/`version`/`sizes` subcommands.

## Safety

- **No `sudo`** locally — user-scope only.
- **`rm -rf` of contents only** — the cache directories themselves stay so
  apps find their expected paths on next launch.
- **Open cache files** are handled by macOS POSIX semantics; nothing breaks
  in running apps.
- **SSH calls** use `ConnectTimeout=3` and ignore failures (`|| true`),
  so an offline Pi never blocks the cleanup.

## See also

- [CHANGELOG.md](../../CHANGELOG.md) — release history for this workflow
- [CLAUDE.md](../../CLAUDE.md) — repo-wide conventions
