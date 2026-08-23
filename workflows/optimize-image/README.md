# Optimize Image

Finder Quick Action: right-click image(s) → **Optimize Image** → a
size-optimized copy is saved next to each original. A notification shows
the total before → after and the percentage saved.

```
Optimize Image
4.2MB → 1.1MB (73% smaller, 3 file(s))
```

## Behavior

| Input | Output | Method |
|-------|--------|--------|
| JPG/JPEG | `<name>-optimized.jpg` | `sips` re-encode, quality 82 |
| PNG | `<name>-optimized.png` | `pngquant --quality=70-90` if installed, else `sips` |
| HEIC | `<name>-optimized.jpg` | converted to JPEG quality 82 |
| GIF/BMP/TIFF/WebP | `<name>-optimized.png` | `sips` PNG re-encode |

- The original is never modified
- **Never larger:** if the "optimized" file would exceed the original,
  the original bytes are kept instead (the counter stays honest)

## Requirements

None (optional: `brew install pngquant` for much better PNG compression).

## Install

```bash
open "Optimize Image.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                 # commit first, restore with git checkout
```
