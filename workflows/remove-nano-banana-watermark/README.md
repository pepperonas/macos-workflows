# Remove Nano Banana Watermark

Removes the sparkle watermark that [Nano Banana](https://nano-banana.com) places in the bottom-right corner of generated images.

## How it works

- Detects the watermark position using percentage-based coordinates (works at any resolution)
- Fills the watermark area with the average surrounding background color
- Applies a slight Gaussian blur to blend edges seamlessly
- Saves a new file with `_clean` suffix — **original is never modified**

## Requirements

- **Python 3** — if not already installed:
  ```bash
  # via Homebrew (recommended)
  brew install python

  # or via Xcode Command Line Tools (includes Python 3)
  xcode-select --install
  ```
- **Pillow** (image processing library):
  ```bash
  pip3 install Pillow
  ```

## Install

1. Double-click `Remove Nano Banana Watermark.workflow`
2. Click **Install** when prompted
3. Enable under **System Settings > General > Login Items & Extensions > Finder**

## Usage

Right-click any image in Finder → **Quick Actions** → **Remove Nano Banana Watermark**
