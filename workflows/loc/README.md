# LoC

Finder Quick Action: right-click a folder → **LoC** → get the lines of code
in a small self-dismissing result window.

> Want it fancier? [**LoC Chart**](../loc-chart/) shows the same numbers
> as a floating HUD panel with an animated per-language bar chart. Both
> share the counting engine in this directory's `loc.sh`.

```
LoC — my-project
1.046 Zeilen · 10 Dateien

Shell 947 · Swift 99
```

## Why a dialog, not a notification

The result is shown via `display dialog … giving up after 30`, **not**
`display notification` — deliberately. macOS gives scripts zero control
over a notification banner: it disappears after ~5 s, hovering shows an
"Einblenden"/Options button, and clicking it opens Script Editor. The
dialog stays for 30 seconds (or until you click OK), has a single OK
button, and clicking it opens nothing.

## What counts

- **Only source files** — extension whitelist (Python, JavaScript/TypeScript,
  Swift, Shell, Go, Rust, Java, Kotlin, C/C++, Obj-C, Ruby, PHP, HTML, CSS,
  Vue, Svelte, SQL, Lua, Perl, Dart, Scala, Haskell, Elixir, Erlang,
  Clojure, R). Extension-based: files without an extension (`Makefile`,
  `Dockerfile`) are not counted.
- **Non-empty lines** — a line counts if it contains at least one
  non-whitespace character. Comments count, blank lines don't.
- **Skipped entirely**: VCS/dependency/build directories (`.git`,
  `node_modules`, `venv`, `.venv`, `__pycache__`, `dist`, `build`, `out`,
  `target`, `vendor`, `Pods`, `DerivedData`, `.next`, coverage dirs, …)
  and minified/bundled files (`*.min.js`, `*.min.css`, `*.bundle.js`).
- Multiple selected folders are summed into one result.

## CLI

The same logic is available as a standalone script:

```bash
./loc.sh <folder>          # report on stdout, incl. per-language breakdown
./loc.sh notify <folder>   # what the "LoC" Quick Action runs
./loc.sh chart <folder>    # what the "LoC Chart" Quick Action runs
./loc.sh help
```

## Architecture note

The block between the `QUICK ACTION CORE` markers in `loc.sh` is embedded
verbatim (XML-escaped) in `LoC.workflow/Contents/document.wflow` and is
written to run under both bash 3.2 and zsh (Automator uses `/bin/zsh`).
A unit test (`test_wflow_embeds_core_verbatim`) re-derives the embedded
script from `loc.sh` and fails on any drift. After editing the core,
regenerate the `.wflow` (escape `&`, `<`, `>` and append
`cmd_count notify "$@"`).

## Install

```bash
open "LoC.workflow"   # ⚠️ moves the bundle into ~/Library/Services — commit first,
                      # then restore with: git checkout -- workflows/loc
```

Then enable under **System Settings → General → Login Items & Extensions →
Finder** if it doesn't appear in the context menu.

## Requirements

None — uses only built-in tools (`find`, `awk`, `xargs`, `osascript`).

## Tests

Covered by `tests/test-loc.sh` (30 tests): whitelist/prune lists, the pure
path filter, thousands formatting, the top-language line, Unicode fallback
bars, a fixture-tree end-to-end count, the self-dismissing-dialog contract,
plist validity, and the wflow↔CLI drift guards for **both** bundles (LoC
and LoC Chart). Run `./tests/run.sh` from the repo root.
