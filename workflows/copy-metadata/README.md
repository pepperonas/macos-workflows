# Copy Metadata

Finder Quick Action: right-click file(s) → **Copy Metadata** → type, size,
creation/modification dates — and for images the full `sips` property
dump (dimensions, DPI, color model, EXIF basics) — are copied to the
clipboard. A notification confirms how many files were processed.

```
=== screenshot.png ===
PNG image data, 1440 x 900, 8-bit/color RGBA, non-interlaced
Size: 482113 bytes
Created: Jun 16 10:41:02 2026
Modified: Jun 16 10:41:02 2026
  pixelWidth: 1440
  pixelHeight: 900
  ...
```

## How it works

`file -b` + `stat -f` per file; image extensions additionally get
`sips -g all`. Deliberately **not** `mdls`: Spotlight metadata is missing
for files in non-indexed locations (external volumes, excluded folders),
where `mdls` returns nothing — `file`/`stat`/`sips` always work.

## Requirements

None (built-in tools only).

## Install

```bash
open "Copy Metadata.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                # commit first, restore with git checkout
```
