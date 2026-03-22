# Cleanup Caches

Shell script to free disk space by clearing caches and flushing PM2 logs.

## What it cleans

- `~/Library/Caches/` — macOS application caches
- `~/.npm/_cacache/` — npm package cache
- `~/.gradle/caches/` — Gradle build caches
- PM2 logs — local and on remote Raspberry Pis (via SSH, skipped if unreachable)

## Requirements

None — uses only built-in tools. SSH aliases (`raspi3`, `raspi2`) are optional for remote PM2 log flushing.

## Usage

```bash
./workflows/cleanup-caches/cleanup-caches.sh
```

Shows freed space per category and total disk usage summary.
