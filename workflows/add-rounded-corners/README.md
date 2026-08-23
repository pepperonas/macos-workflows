# Add Rounded Corners

Finder Quick Action: right-click image(s) → **Add Rounded Corners** → a
copy with rounded, transparent corners is saved next to the original.
Great for screenshots in presentations and app-store style imagery.

## Behavior

- Input: `jpg jpeg png gif bmp tiff tif heic webp` (other files are skipped)
- Output: `<name>-rounded.png` next to the original (always PNG — the
  corners need transparency); the original is never modified
- Corner radius scales with the image: `max(20, min(w, h) / 20)` px

## How it works

A zsh loop filters by extension, then an inline Python script (Pillow)
draws a rounded-rectangle mask and pastes the image through it onto a
transparent canvas.

## Requirements

- Python 3 with **Pillow** (`pip3 install Pillow`)
- The script exports `PATH="/opt/homebrew/bin:..."` so the Homebrew
  Python (with pip packages) is found

## Install

```bash
open "Add Rounded Corners.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                      # commit first, restore with git checkout
```
