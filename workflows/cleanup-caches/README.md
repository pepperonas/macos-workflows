# Cleanup Caches

Frees disk space by clearing caches and flushing PM2 logs. Available as Quick Action and standalone script.

## What it cleans

- `~/Library/Caches/` — macOS application caches
- `~/.npm/_cacache/` — npm package cache
- `~/.gradle/caches/` — Gradle build caches
- PM2 logs — local and on remote Raspberry Pis (via SSH, skipped if unreachable)

## Requirements

None — uses only built-in tools. SSH aliases (`raspi3`, `raspi2`) are optional for remote PM2 log flushing.

## Install

1. Double-click `Cleanup Caches.workflow`
2. Click **Install** when prompted
3. Enable under **System Settings > General > Login Items & Extensions > Finder**

## Usage

**As Quick Action:** Right-click in Finder → **Quick Actions** → **Cleanup Caches**

**As script (with colored terminal output):**
```bash
./workflows/cleanup-caches/cleanup-caches.sh
```
