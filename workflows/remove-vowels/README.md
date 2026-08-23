# Remove Vowels

Services menu action: select text in any app → right-click →
**Services → Remove Vowels** → the text minus all vowels lands in the
clipboard. Handy for abbreviation-style identifiers and just plain fun.

```
Betriebssystemadministration → Btrbssystmdmnstrtn
```

## Behavior

- Removes `aeiou`, `AEIOU`, **and the German umlauts** `äöüÄÖÜ`
- The trailing newline is stripped so pasting doesn't insert a line break
- Result goes to the clipboard; the selection itself is untouched

## How it works

One pipeline: `tr -d 'aeiouAEIOUäöüÄÖÜ' | perl -pe 'chomp if eof' | pbcopy`.

## Requirements

None (built-in `tr`).

## Install

```bash
open "Remove Vowels.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                                # commit first, restore with git checkout
```
