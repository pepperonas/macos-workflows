# Copy File Path

Finder Quick Action: right-click file(s) or folder(s) → **Copy File Path**
→ the full POSIX path of every selected item is copied to the clipboard,
one per line. A notification confirms how many paths were copied.

```
/Users/martin/Projects/app/config.json
/Users/martin/Projects/app/src
```

## How it works

`printf '%s\n' "$@" | pbcopy` — the selected items arrive as arguments,
so paths with spaces and umlauts survive untouched.

## Requirements

None.

## Install

```bash
open "Copy File Path.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                 # commit first, restore with git checkout
```

> Tip: Finder also offers ⌥-right-click → "Copy as Pathname", but only
> for a single item and without the multi-selection newline list.
