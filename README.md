# macOS Workflows

<p align="center">
  <img src="banner.png" alt="macOS Workflows" width="800">
</p>

<p align="center">
  <strong>A curated collection of 17 macOS Finder Quick Actions for image, text, and file workflows.</strong><br>
  Right-click any file or select text — get useful actions in your Services menu.
</p>

<p align="center">

<!-- Release / status -->
<a href="https://github.com/pepperonas/macos-workflows/releases"><img alt="Release" src="https://img.shields.io/github/v/release/pepperonas/macos-workflows?style=flat-square&logo=github"></a>
<a href="VERSION"><img alt="Version" src="https://img.shields.io/badge/version-1.1.0-blue?style=flat-square"></a>
<a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square"></a>
<a href="CHANGELOG.md"><img alt="Changelog" src="https://img.shields.io/badge/changelog-keepachangelog-FF5733?style=flat-square"></a>

<!-- Platform -->
<a href="https://www.apple.com/macos/"><img alt="macOS" src="https://img.shields.io/badge/macOS-14%2B-000000?style=flat-square&logo=apple&logoColor=white"></a>
<img alt="Architecture" src="https://img.shields.io/badge/arch-Apple%20Silicon%20%7C%20Intel-success?style=flat-square">
<a href="https://support.apple.com/guide/automator/"><img alt="Automator" src="https://img.shields.io/badge/Automator-Quick%20Actions-8B5CF6?style=flat-square&logo=apple&logoColor=white"></a>

<!-- Languages / tooling -->
<a href="https://www.gnu.org/software/bash/"><img alt="Bash" src="https://img.shields.io/badge/Bash-5%2B-1f425f?style=flat-square&logo=gnu-bash&logoColor=white"></a>
<a href="https://swift.org/"><img alt="Swift" src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white"></a>
<a href="https://www.python.org/"><img alt="Python" src="https://img.shields.io/badge/Python-3.9%2B-3776AB?style=flat-square&logo=python&logoColor=white"></a>
<img alt="AppleScript" src="https://img.shields.io/badge/AppleScript-native-orange?style=flat-square">

<!-- Quality -->
<img alt="Tests" src="https://img.shields.io/badge/tests-22%20passing-success?style=flat-square">
<img alt="Workflows" src="https://img.shields.io/badge/workflows-17-blueviolet?style=flat-square">
<img alt="Dependencies" src="https://img.shields.io/badge/core%20deps-zero-brightgreen?style=flat-square">
<img alt="Telemetry" src="https://img.shields.io/badge/telemetry-none-success?style=flat-square">
<img alt="Privacy" src="https://img.shields.io/badge/privacy-100%25%20local-success?style=flat-square">

<!-- Community -->
<a href="https://github.com/pepperonas/macos-workflows/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/pepperonas/macos-workflows?style=flat-square"></a>
<a href="https://github.com/pepperonas/macos-workflows/network/members"><img alt="Forks" src="https://img.shields.io/github/forks/pepperonas/macos-workflows?style=flat-square"></a>
<a href="https://github.com/pepperonas/macos-workflows/issues"><img alt="Issues" src="https://img.shields.io/github/issues/pepperonas/macos-workflows?style=flat-square"></a>
<a href="https://github.com/pepperonas/macos-workflows/pulls"><img alt="PRs welcome" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square"></a>
<a href="https://github.com/pepperonas/macos-workflows/commits/main"><img alt="Last commit" src="https://img.shields.io/github/last-commit/pepperonas/macos-workflows?style=flat-square"></a>
<img alt="Maintained" src="https://img.shields.io/badge/Maintained-yes-green.svg?style=flat-square">
<img alt="Made with ♥" src="https://img.shields.io/badge/made%20with-%E2%99%A5-red?style=flat-square">

</p>

---

## Table of Contents

- [Image Workflows](#image-workflows)
- [Text Workflows](#text-workflows)
- [File & Utility Workflows](#file--utility-workflows)
- [Quick Install](#quick-install)
- [Optional Dependencies](#optional-dependencies)
- [Usage](#usage)
- [Testing](#testing)
- [Versioning](#versioning)
- [Project Structure](#project-structure)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

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
| [Cleanup Caches](workflows/cleanup-caches/) | Frees disk space with a confirmation dialog: clears macOS/npm/Gradle caches, user logs, PM2 logs (local + Raspis), runs `brew cleanup` & `npm cache clean`. Shows freed bytes as notification | None |

## Quick Install

```bash
git clone https://github.com/pepperonas/macos-workflows.git
cd macos-workflows
```

Then for each workflow you want, double-click its `.workflow` file (or use `open`):

```bash
open "workflows/cleanup-caches/Cleanup Caches.workflow"
```

For workflows that need compilation (Remove Background, QR Code):

```bash
cd workflows/remove-background && ./build.sh
cd ../qr-code && ./build.sh
```

Enable Quick Actions under **System Settings → General → Login Items & Extensions → Finder**.

> ⚠️ **Caveat:** `open Name.workflow` *moves* (not copies) the files from the
> source dir into `~/Library/Services/`. Commit your repo first, then install,
> then restore the source via `git checkout` if you want both locally available.

## Optional Dependencies

Most workflows use only built-in macOS tools. For the best experience:

```bash
# Required for image effect workflows (rounded corners, drop shadow, watermark removal)
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
| **Keyboard shortcuts** | Assign in *System Settings → Keyboard → Keyboard Shortcuts → Services* |

## Testing

A plain-bash test suite lives under `tests/`. No external dependencies (no
bats, no shellcheck required).

```bash
./tests/run.sh
```

```
Running tests...

test-cleanup-caches
  ✓ test_bytes_to_human_zero
  ✓ test_bytes_to_human_1kb
  ✓ test_bytes_to_human_1gb
  ...
─────────────────────────
All 22 tests passed.
```

The runner discovers every `tests/test-*.sh` file and executes each
`test_*` function defined inside. Helpers `assert_equal`, `assert_contains`,
and `assert_success` are exported from `tests/run.sh`.

Workflows are tested by sourcing their shell script (the `cleanup-caches.sh`
file uses a `BASH_SOURCE != $0` guard to suppress its `main` when sourced).
Plist files are validated via `plutil -lint`.

## Versioning

This project follows [Semantic Versioning](https://semver.org/).

- **MAJOR** — breaking changes to workflow output formats or required env
- **MINOR** — new workflows or new features in existing workflows
- **PATCH** — bug fixes, doc updates, internal refactors

The current version is in [`VERSION`](VERSION); release history is in
[`CHANGELOG.md`](CHANGELOG.md). Tags are pushed as `vMAJOR.MINOR.PATCH`.

## Project Structure

```
macos-workflows/
├── workflows/
│   ├── <name>/
│   │   ├── <Name>.workflow/        # Automator bundle
│   │   │   └── Contents/
│   │   │       ├── Info.plist
│   │   │       └── document.wflow
│   │   ├── <name>.sh               # Standalone CLI script (some workflows)
│   │   ├── *.swift                 # Swift sources (compiled workflows)
│   │   ├── build.sh                # If compilation needed
│   │   └── README.md
│   └── ...
├── tests/
│   ├── run.sh                      # Test runner
│   └── test-*.sh                   # Test files
├── CHANGELOG.md
├── CLAUDE.md                       # Guidance for AI assistants
├── LICENSE
├── README.md
└── VERSION
```

## Contributing

PRs are welcome. Please:

1. Place new workflows in `workflows/<name>/` with at minimum a
   `<Name>.workflow/` bundle and a `README.md`.
2. Use an existing workflow as a template — copy its plist structure, change
   UUIDs, service name, and script content.
3. Add an entry to the relevant table in this README.
4. If you add CLI-callable scripts, add unit tests to `tests/test-*.sh`.
5. Bump `VERSION` and add a `CHANGELOG.md` entry.

See [CLAUDE.md](CLAUDE.md) for technical details on `.wflow` XML conventions
(input types, PATH handling, escaping, install caveats).

## Author

**Martin Pfeffer** — [celox.io](https://celox.io) — [@pepperonas](https://github.com/pepperonas)

## License

[MIT](LICENSE)
