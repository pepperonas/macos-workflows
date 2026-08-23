# Convert Case

Services menu action: select an identifier in any app → right-click →
**Services → Convert Case** → the converted identifier lands in the
clipboard.

## Behavior

Auto-detects the current naming style and converts:

| Input contains | Detected as | Converted to |
|----------------|-------------|--------------|
| `_` | `snake_case` | `camelCase` |
| `-` (no `_`) | `kebab-case` | `camelCase` |
| neither | `camelCase` | `snake_case` |

```
user_name      → userName
font-size      → fontSize
backgroundColor → background_color
```

The result is copied to the clipboard (`pbcopy`); the trailing newline is
stripped so pasting doesn't insert a line break.

## How it works

Pure zsh + perl one-liners — `s/_([a-z])/uc($1)/ge` and friends. No
Python, no dependencies.

## Requirements

None (built-in `perl`).

## Install

```bash
open "Convert Case.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                               # commit first, restore with git checkout
```
