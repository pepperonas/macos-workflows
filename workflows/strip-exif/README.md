# Strip EXIF

Finder Quick Action: right-click image(s) → **Strip EXIF** → a metadata-free
copy is saved next to each original. Removes GPS location, camera model,
serial numbers, and timestamps before you share a photo.

## Behavior

| Input | Output |
|-------|--------|
| JPG/JPEG | `<name>-stripped.jpg` (quality 100 re-encode) |
| PNG/GIF/BMP/TIFF/HEIC/WebP | `<name>-stripped.png` |

- The original is never modified
- Metadata is dropped by **re-encoding** through `sips` — the pixel data
  is written fresh without the EXIF/IPTC/XMP blocks
- Note: non-JPEG formats come out as PNG (lossless, but HEIC files will
  grow in size)

## Requirements

None (built-in `sips`).

## Install

```bash
open "Strip EXIF.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                             # commit first, restore with git checkout
```

> Verify the result: `sips -g all photo-stripped.jpg` should show no GPS
> or camera fields.
