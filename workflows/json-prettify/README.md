# JSON Prettify

Services menu action: select JSON text in any app → right-click →
**Services → JSON Prettify** → the formatted JSON (4-space indent, one
key per line) lands in the clipboard.

```
{"a":1,"b":[2,3]}   →   {
                            "a": 1,
                            "b": [
                                2,
                                3
                            ]
                        }
```

## How it works

The selected text is piped through `python3 -m json.tool`; the trailing
newline is stripped (`perl -pe 'chomp if eof'`) so pasting doesn't insert
a line break.

⚠️ **Invalid JSON yields an empty clipboard** — the parser error is
suppressed (`2>/dev/null`), so nothing is copied. If your paste is empty,
the selection wasn't valid JSON.

## Requirements

Python 3 (the system Python suffices — `json.tool` is stdlib; the PATH
export just prefers Homebrew's if present).

## Install

```bash
open "JSON Prettify.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                # commit first, restore with git checkout
```
