# LoC

Finder Quick Action: right-click a folder → **LoC** → get the lines of code
as a macOS notification.

```
LoC — my-project
1.046 Zeilen · 10 Dateien
Shell 947 · Swift 99
```

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
- Multiple selected folders are summed into one notification.

## CLI

The same logic is available as a standalone script:

```bash
./loc.sh <folder>          # report on stdout, incl. per-language breakdown
./loc.sh notify <folder>   # what the Quick Action runs
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
