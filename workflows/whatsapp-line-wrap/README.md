# WhatsApp Line Wrap

Services menu action: select text → right-click →
**Services → WhatsApp Line Wrap** → the text re-wrapped to 40-character
lines lands in the clipboard, ready to paste into WhatsApp without the
unreadable mid-word breaks of narrow chat bubbles.

## Behavior

- Wraps every paragraph to **max 40 chars**, never breaking words or
  hyphenated compounds
- Preserves list markers (`-`, `*`, `1.`, `#` headings) with hanging
  indent on continuation lines
- **Converts ASCII/box-drawing tables to card format** — a table pasted
  from a terminal or Markdown becomes readable per-row cards:

```
│ Name  │ Port │            Name: disco
│ disco │ 5007 │     →      Port: 5007
│ fog   │ 5003 │
                            Name: fog
                            Port: 5003
```

## How it works

An inline Python script (stdlib only: `textwrap`, `re`) detects
box-drawing characters, parses header/body rows, and emits `Header: cell`
lines; everything else goes through `textwrap.fill`.

## Requirements

Python 3 (stdlib only — no pip packages).

## Install

```bash
open "WhatsApp Line Wrap.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                     # commit first, restore with git checkout
```
