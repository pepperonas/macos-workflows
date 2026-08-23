# LoC Chart

Finder Quick Action: right-click a folder → **LoC Chart** → a floating
HUD panel slides in top-right with the total line count and an **animated
per-language bar chart** in language brand colors.

```
╭──────────────────────────────────╮
│ LoC — my-project                 │
│ 24.512  Zeilen · 312 Dateien     │
│                                  │
│ JavaScript                 6.234 │
│ ████████████████████████████     │
│ Python                     3.123 │
│ ██████████████                   │
│ Shell                      1.240 │
│ ██████                           │
│                                  │
│  Klicken zum Schließen           │
╰──────────────────────────────────╯
```

- Dark blur panel (`NSVisualEffectView`), rounded corners, slides/fades in
- Bars animate to their share of the largest language, staggered
- Brand colors for ~28 known languages (Python blue, JS yellow, Swift
  orange, …), pleasant fallback palette for the rest; top 5 languages
  plus a gray "Sonstige" aggregate
- **Click anywhere** on the panel → it fades out, nothing opens; after
  30 s it dismisses itself
- The panel is detached (`nohup … &`) so Finder's gear spinner stops
  immediately while the panel stays

Counting is identical to [LoC](../loc/) — same engine (`../loc/loc.sh`),
same whitelist and exclusions, same drift-guard: this bundle embeds the
`QUICK ACTION CORE` of `loc.sh` with the `chart` entry point, pinned by
`test_chart_wflow_embeds_core_verbatim`.

## Build (for the panel)

```bash
cd workflows/loc-chart && ./build.sh
```

Compiles `loc_display.swift` (AppKit, no third-party code) and installs
the binary to `~/Library/Services/loc_display`. Needs the Xcode Command
Line Tools once. The compiled binary is git-ignored.

**Without the binary the Quick Action still works** — it falls back to a
self-dismissing dialog with Unicode block bars:

```
9 Zeilen · 4 Dateien
██████████  JavaScript  6
█████░░░░░  Python  3
```

## CLI

```bash
../loc/loc.sh chart <folder>    # what the Quick Action runs
../loc/loc.sh <folder>          # plain report on stdout
```

## Install

```bash
./build.sh
open "LoC Chart.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                            # commit first, restore with: git checkout -- workflows/loc-chart
```

## Requirements

None at runtime for the fallback; Xcode Command Line Tools once for the
chart panel.
