# Resize to w1024px

Resizes images to 1024 pixels width while maintaining aspect ratio. Ideal for creating web-ready thumbnails or reducing file sizes.

## How it works

- Uses macOS built-in `sips` — no dependencies required
- Skips images that are already 1024px wide or smaller
- Saves a new file with `-w1024` suffix — **original is never modified**
- Supports: JPG, JPEG, PNG, GIF, BMP, TIFF, HEIC, WebP

## Requirements

None — uses only built-in macOS tools.

## Install

1. Double-click `Resize to w1024px.workflow`
2. Click **Install** when prompted
3. Enable under **System Settings > General > Login Items & Extensions > Finder**

## Usage

Right-click any image (or multiple images) in Finder → **Quick Actions** → **Resize to w1024px**
