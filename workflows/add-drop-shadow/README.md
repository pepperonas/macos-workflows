# Add Drop Shadow

Finder Quick Action: right-click image(s) → **Add Drop Shadow** → a copy
with a soft drop shadow is saved next to the original. Ideal for blog
posts, documentation, and presentations.

## Behavior

- Input: `jpg jpeg png gif bmp tiff tif heic webp` (other files are skipped)
- Output: `<name>-shadow.png` next to the original (always PNG — the
  shadow needs transparency); the original is never modified
- Shadow geometry scales with the image: padding is
  `max(40, min(w, h) / 15)` px, the offset a quarter of that, blurred
  with a Gaussian of half the padding

## How it works

A zsh loop filters by extension, then an inline Python script (Pillow)
pastes a translucent black rectangle onto an enlarged transparent canvas,
blurs it, and composites the original image on top.

## Requirements

- Python 3 with **Pillow** (`pip3 install Pillow`)
- The script exports `PATH="/opt/homebrew/bin:..."` so the Homebrew
  Python (with pip packages) is found — Automator's default PATH only
  contains the system Python

## Install

```bash
open "Add Drop Shadow.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                  # commit first, restore with git checkout
```
