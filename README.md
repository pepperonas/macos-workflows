# macOS Workflows

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-15%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Automator](https://img.shields.io/badge/Automator-Quick%20Actions-8B5CF6?logo=apple&logoColor=white)](https://support.apple.com/guide/automator/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)
[![GitHub stars](https://img.shields.io/github/stars/pepperonas/macos-workflows?style=social)](https://github.com/pepperonas/macos-workflows)
[![GitHub issues](https://img.shields.io/github/issues/pepperonas/macos-workflows)](https://github.com/pepperonas/macos-workflows/issues)
[![GitHub last commit](https://img.shields.io/github/last-commit/pepperonas/macos-workflows)](https://github.com/pepperonas/macos-workflows/commits/main)
[![Maintenance](https://img.shields.io/badge/Maintained-yes-green.svg)](https://github.com/pepperonas/macos-workflows)

A collection of useful macOS Finder Quick Actions (Automator workflows) that are easy to install and use.

## Available Workflows

| Workflow | Description | Requirements |
|----------|-------------|--------------|
| [Remove Nano Banana Watermark](workflows/remove-nano-banana-watermark/) | Removes the sparkle watermark from Nano Banana AI-generated images | Python 3, Pillow |

## Quick Install

1. Clone the repo or download the `.workflow` you need
2. Double-click the `.workflow` file
3. Click **Install** when prompted
4. Enable under **System Settings > General > Login Items & Extensions > Finder**

```bash
git clone https://github.com/pepperonas/macos-workflows.git
open "macos-workflows/workflows/remove-nano-banana-watermark/Remove Nano Banana Watermark.workflow"
```

## Usage

After installing, right-click any file in Finder → **Quick Actions** → select the workflow.

## Contributing

Have a useful workflow? PRs are welcome! Place your workflow in `workflows/<name>/` with:

- `<Name>.workflow/` — the Automator workflow bundle
- `README.md` — description, requirements, and usage

## Author

**Martin Pfeffer** — [celox.io](https://celox.io) — [@pepperonas](https://github.com/pepperonas)

## License

[MIT](LICENSE)
