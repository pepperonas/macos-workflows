# macOS Workflows

<p align="center">
  <img src="banner.png" alt="macOS Workflows" width="800">
</p>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Automator](https://img.shields.io/badge/Automator-Quick%20Actions-8B5CF6?logo=apple&logoColor=white)](https://support.apple.com/guide/automator/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/pepperonas/macos-workflows?style=social)](https://github.com/pepperonas/macos-workflows)
[![GitHub issues](https://img.shields.io/github/issues/pepperonas/macos-workflows)](https://github.com/pepperonas/macos-workflows/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/pepperonas/macos-workflows)](https://github.com/pepperonas/macos-workflows/commits/main)
[![Maintenance](https://img.shields.io/badge/Maintained-yes-green.svg)](https://github.com/pepperonas/macos-workflows)

A collection of 17 macOS Finder Quick Actions (Automator workflows) for image processing, text transformation, and everyday file operations. Right-click any file or select text to use them.

## Image Workflows

Right-click any image in Finder → **Quick Actions** → select the workflow. A new file is created next to the original — the original is never modified.

| Workflow | Description | Output | Requirements |
|----------|-------------|--------|--------------|
| [Remove Background](workflows/remove-background/) | Removes the background using Apple Vision AI, keeping only the main subject with transparency | `*-free.png` | macOS 14+, Xcode CLI Tools |
| [Remove Nano Banana Watermark](workflows/remove-nano-banana-watermark/) | Removes the sparkle watermark from Nano Banana AI-generated images using distance-weighted interpolation with texture matching | `*_clean.*` | Python 3, Pillow |
| [Optimize Image](workflows/optimize-image/) | Reduces file size by re-encoding (JPG quality 82, PNG via pngquant). Shows before/after size in notification | `*-optimized.*` | None (optional: `pngquant`) |
| [Resize to w1024px](workflows/resize-to-w1024px/) | Resizes images to 1024px width while maintaining aspect ratio. Skips smaller images | `*-w1024.*` | None (built-in `sips`) |
| [Strip EXIF](workflows/strip-exif/) | Removes metadata (GPS location, camera info) from images for privacy | `*-stripped.*` | None (built-in `sips`) |
| [Add Rounded Corners](workflows/add-rounded-corners/) | Adds rounded corners with transparency — great for screenshots in presentations | `*-rounded.png` | Python 3, Pillow |
| [Add Drop Shadow](workflows/add-drop-shadow/) | Adds a soft drop shadow around images — ideal for blog posts and documentation | `*-shadow.png` | Python 3, Pillow |
| [QR Code](workflows/qr-code/) | Generates a QR code PNG from the file contents (if text) or the file path | `*-qr.png` | Xcode CLI Tools |

## Text Workflows

Select text in any app → right-click → **Services** → select the workflow. The result is copied to your clipboard.

| Workflow | Description | Requirements |
|----------|-------------|--------------|
| [JSON Prettify](workflows/json-prettify/) | Formats selected JSON text with proper indentation | Python 3 |
| [Convert Case](workflows/convert-case/) | Auto-detects and converts between `camelCase`, `snake_case`, and `kebab-case` | None |
| [WhatsApp Line Wrap](workflows/whatsapp-line-wrap/) | Wraps text to 40-char lines for WhatsApp readability. Converts ASCII tables to card format | Python 3 |
| [Remove Vowels](workflows/remove-vowels/) | Removes all vowels including German umlauts (äöü) from selected text | None (built-in `tr`) |
| [Text Statistics](workflows/text-statistics/) | Shows word, character, and line count as macOS notification | None |

## File & Utility Workflows

Right-click any file or folder in Finder → **Quick Actions** → select the workflow.

| Workflow | Description | Requirements |
|----------|-------------|--------------|
| [Copy File Path](workflows/copy-file-path/) | Copies the full path of selected file(s) to the clipboard | None |
| [Copy Metadata](workflows/copy-metadata/) | Copies file metadata (type, size, dates, image dimensions) to the clipboard | None |
| [Copy Folder Tree](workflows/copy-folder-tree/) | Copies the folder structure as a text tree to the clipboard | None (optional: `tree`) |
| [New Textfile](workflows/new-textfile/) | Creates `Untitled.txt` in the current folder and opens it in the default editor | None |
| [Cleanup Caches](workflows/cleanup-caches/) | Frees disk space by clearing macOS/npm/Gradle caches and flushing PM2 logs | None |

## Quick Install

1. Clone the repo:
   ```bash
   git clone https://github.com/pepperonas/macos-workflows.git
   cd macos-workflows
   ```

2. Double-click any `.workflow` file you want to install, then click **Install** when prompted.

3. For workflows that need compilation (Remove Background, QR Code):
   ```bash
   cd workflows/remove-background && ./build.sh
   cd ../qr-code && ./build.sh
   ```

4. Enable workflows under **System Settings > General > Login Items & Extensions > Finder**.

### Optional Dependencies

Most workflows use only built-in macOS tools. For the best experience with all workflows:

```bash
# Required for image effect workflows
pip3 install Pillow

# Optional: better PNG compression for Optimize Image
brew install pngquant

# Optional: nicer tree output for Copy Folder Tree
brew install tree
```

## Usage

| Type | How to trigger |
|------|---------------|
| **Image workflows** | Right-click file(s) in Finder → **Quick Actions** → select workflow |
| **Text workflows** | Select text → right-click → **Services** → select workflow |
| **File utilities** | Right-click file/folder in Finder → **Quick Actions** → select workflow |

## Contributing

Have a useful workflow? PRs are welcome! Place your workflow in `workflows/<name>/` with:

- `<Name>.workflow/` — the Automator workflow bundle
- `README.md` — description, requirements, and usage

## Author

**Martin Pfeffer** — [celox.io](https://celox.io) — [@pepperonas](https://github.com/pepperonas)

## License

[MIT](LICENSE)
