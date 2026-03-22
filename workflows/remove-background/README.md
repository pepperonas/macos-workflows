# Remove Background

Removes the background from images, keeping only the main subject with a transparent background. Uses Apple's Vision framework for on-device AI subject detection.

## How it works

- Uses macOS Vision framework (`VNGenerateForegroundInstanceMaskRequest`) — no external dependencies
- Detects the foreground subject and masks out the background
- Saves a new PNG with `-free` suffix and transparent background — **original is never modified**
- Supports: JPG, JPEG, PNG, GIF, BMP, TIFF, HEIC, WebP, SVG

## Requirements

- **macOS 14 Sonoma** or later (uses Vision framework subject isolation API)
- Xcode Command Line Tools (`xcode-select --install`)

## Install

1. Build the tool:
   ```bash
   cd workflows/remove-background
   chmod +x build.sh && ./build.sh
   ```
2. Double-click `Remove Background.workflow`
3. Click **Install** when prompted
4. Enable under **System Settings > General > Login Items & Extensions > Finder**

## Usage

Right-click any image (or multiple images) in Finder → **Quick Actions** → **Remove Background**

The result is saved as `<filename>-free.png` next to the original file.
