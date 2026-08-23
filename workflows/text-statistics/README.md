# Text Statistics

Services menu action: select text in any app → right-click →
**Services → Text Statistics** → word, character, and line count appear
as a macOS notification. The clipboard and the selection stay untouched.

```
Text Statistics
142 words, 987 chars, 12 lines
```

## How it works

The selection arrives on stdin; `wc -w` / `wc -c` / `wc -l` count it.
The line count is `wc -l + 1` because a selection usually has no trailing
newline — `wc -l` counts newline characters, not lines.

## Requirements

None (built-in `wc`).

## Install

```bash
open "Text Statistics.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                  # commit first, restore with git checkout
```
