# Copy Folder Tree

Finder Quick Action: right-click a folder → **Copy Folder Tree** → the
folder structure is copied to the clipboard as a text tree. Right-clicking
a file uses its parent folder.

```
my-project
├── src
│   ├── app.py
│   └── utils.py
└── README.md
```

## Behavior

- Uses **`tree -a --dirsfirst`** when installed (`brew install tree`) for
  the pretty box-drawing output above
- Falls back to a built-in `find | sort | sed` indent tree when `tree`
  is missing — no dependency required
- `.git/`, `node_modules/`, and `.DS_Store` are always excluded
- A notification confirms the copy

## Requirements

None (optional: `brew install tree` for nicer output).

## Install

```bash
open "Copy Folder Tree.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                   # commit first, restore with git checkout
```
