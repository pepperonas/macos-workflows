# Rename Tracks

Normalises music filenames in a folder to one convention: **`Artist - Title.ext`**.

Right-click a folder in Finder → **Quick Actions** → **Rename Tracks**. A dialog
shows exactly what would change; nothing is touched until you confirm.

![convention](https://img.shields.io/badge/convention-Artist%20--%20Title-blue?style=flat-square)

## What it fixes

| Before | After | Why |
|--------|-------|-----|
| `OutKast - Ms. Jackson (Official Video) [EUVo8epKwv0].m4a` | `OutKast - Ms. Jackson.m4a` | download clutter, YouTube ID |
| `ABC - The Look Of Love.m4a` | `ABC - The Look of Love.m4a` | title case (`of` is a small word) |
| `DRAGONFORCE - Through the Fire and Flames.m4a` | `DragonForce - Through the Fire and Flames.m4a` | shouting artist |
| `PINK FLOYD - Money.m4a` | `Pink Floyd - Money.m4a` | shouting artist, no word is an acronym |
| `Fergie - Glamorous ft. Ludacris.m4a` | `Fergie - Glamorous (feat. Ludacris).m4a` | feature notation |
| `Ede， Deckert - Immer.m4a` | `Ede & Deckert - Immer.m4a` | fullwidth comma (U+FF0C) from a download |
| `Modern Talking - You´re My Heart.m4a` | `Modern Talking - You're My Heart.m4a` | acute accent instead of apostrophe |

## The convention

1. Exactly one ` - ` between artist and title
2. English titles in title case; small words (`a, an, the, of, in, to, and, …`)
   stay lowercase — except as the first or last word, or right after `( [ : -`
3. Non-English titles keep their original spelling (`An Tagen wie diesen`,
   `Entre dos tierras`, `Ella, elle l'a`)
4. No download clutter: `(Official Video)`, `[dQw4w9WgXcQ]`, ` - Topic`
5. Features as `(feat. X)` at the end of the title
6. Remixes and versions in parentheses at the end
7. ASCII punctuation only; none of `? " * | < > / \ :` — these break
   Windows/Android sync
8. Artists in their official spelling; `ALL CAPS` is un-shouted
9. Words that are already mixed case (`OutKast`, `McCartney`) are left alone

## What it deliberately does not guess

A name with **more than one ` - `** is ambiguous — `Don't Let Me Be
Misunderstood - Santa Esmeralda - Kill Bill Vol. 1` could be parsed three ways.
Those are reported as `UNKLAR` and left untouched. Resolve them with an entry in
`MANUELL` in `rename-tracks.py`.

Two more limits, both honest rather than papered over:

- **Language detection** works on stop words that do not exist in English
  (`wie`, `dos`, `elle`, `och`). A foreign title made only of words that are
  also English (`Voyage voyage`) is not recognised — add it to
  `TITEL_AUSNAHMEN`.
- **An all-caps name of at most four letters** cannot be told apart from a real
  acronym (`TOTO` vs. `MGMT`). It stays as typed unless `KUENSTLER_MAP` says
  otherwise.

## Command line

The same logic runs standalone — no venv, no dependencies, only the Python
standard library, and it works with the `/usr/bin/python3` that macOS ships:

```bash
python3 rename-tracks.py --dir ~/Music     # preview, changes nothing
python3 rename-tracks.py --dir ~/Music --apply
python3 rename-tracks.py --undo .rename-log-20260830-012407.tsv
```

Every `--apply` writes a hidden `.rename-log-*.tsv` next to the files;
`--undo` replays it backwards.

`Tracks umbenennen.command` is a double-clickable Finder launcher for the same
flow — useful when you want the tool to live *next to* the music rather than in
the Services menu.

## Architecture

`rename-tracks.py` is the single source of truth. The `.wflow` carries a
byte-identical embedded copy so the Quick Action keeps working without this
repo. Regenerate after every change:

```bash
python3 build-wflow.py --write
```

`tests/test-rename-tracks.sh` pins the two copies against each other, so drift
turns the suite red.

## Testing

```bash
python3 test-rename-tracks.py     # ~100 assertions on the naming logic
./tests/run.sh                    # repo suite, includes the bundle tests
```

The Python suite covers title case, acronyms, language protection, feature
notation, character normalisation, idempotence, and real filesystem renames
(including case-only renames, which need a two-step rename on case-insensitive
volumes such as APFS and Google Drive).

⚠️ When mutation-testing this suite, always clear `__pycache__` or use
`python3 -B`. Stale bytecode makes the run report gaps that do not exist — that
happened three times while this was being built.
