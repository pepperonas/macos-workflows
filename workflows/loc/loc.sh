#!/bin/bash
# loc.sh — Count source-code lines in folders (Finder Quick Action "LoC").
#
# Usage:
#   loc.sh <folder-or-file> [...]   Print a report to stdout
#   loc.sh notify <folder> [...]    Count + show a macOS notification
#   loc.sh version | help
#
# What counts:
#   - Only files with a source-code extension (py, js, ts, swift, go, rs, ...)
#   - A "line" is a non-empty line (at least one non-whitespace character);
#     comments count, blank lines do not.
#   - Dependency/build/VCS dirs (.git, node_modules, venv, dist, build, ...)
#     and minified/bundled files (*.min.js, *.bundle.js, ...) are skipped.
#
# The block between the CORE markers below is embedded verbatim (XML-escaped)
# in LoC.workflow/Contents/document.wflow. A unit test derives the embedded
# script from this file and fails on any drift — edit here, then regenerate.
# The core is written to run under bash 3.2 AND zsh (Automator uses /bin/zsh):
# no ${var,,}, no array index arithmetic, everything quoted.

# --- BEGIN QUICK ACTION CORE ---
set -u

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export LC_NUMERIC=C

LOC_VERSION="1.0.0"

# Directory names that never contain hand-written source (find -name globs).
prune_dir_names() {
    printf '%s\n' \
        .git .svn .hg \
        node_modules bower_components \
        venv .venv env __pycache__ .mypy_cache .pytest_cache .ruff_cache .tox \
        '*.egg-info' site-packages htmlcov coverage \
        dist build out target vendor Pods DerivedData .build .gradle \
        .next .nuxt .svelte-kit .cache
}

# Generated/minified files are not hand-written source.
is_excluded_file() {
    case "$1" in
        *.min.js|*.min.css|*.min.mjs|*.bundle.js) return 0 ;;
        *) return 1 ;;
    esac
}

# Sets REPLY_EXT to the extension of the given path ('' if none).
# Deliberately fork-free — this runs once per file.
ext_of() {
    local base="${1##*/}"
    case "$base" in
        *.*) REPLY_EXT="${base##*.}" ;;
        *)   REPLY_EXT="" ;;
    esac
}

# Sets REPLY_LANG to the display language for an extension ('' = not source).
# Single source of truth for the whitelist. Fork-free.
lang_for_ext() {
    case "$1" in
        py)                 REPLY_LANG="Python" ;;
        js|jsx|mjs|cjs)     REPLY_LANG="JavaScript" ;;
        ts|tsx)             REPLY_LANG="TypeScript" ;;
        swift)              REPLY_LANG="Swift" ;;
        sh|bash|zsh)        REPLY_LANG="Shell" ;;
        go)                 REPLY_LANG="Go" ;;
        rs)                 REPLY_LANG="Rust" ;;
        java)               REPLY_LANG="Java" ;;
        kt|kts)             REPLY_LANG="Kotlin" ;;
        c|h)                REPLY_LANG="C" ;;
        cpp|cc|cxx|hpp|hh)  REPLY_LANG="C++" ;;
        m|mm)               REPLY_LANG="Obj-C" ;;
        rb)                 REPLY_LANG="Ruby" ;;
        php)                REPLY_LANG="PHP" ;;
        html|htm)           REPLY_LANG="HTML" ;;
        css|scss|sass|less) REPLY_LANG="CSS" ;;
        vue)                REPLY_LANG="Vue" ;;
        svelte)             REPLY_LANG="Svelte" ;;
        sql)                REPLY_LANG="SQL" ;;
        lua)                REPLY_LANG="Lua" ;;
        pl|pm)              REPLY_LANG="Perl" ;;
        dart)               REPLY_LANG="Dart" ;;
        scala)              REPLY_LANG="Scala" ;;
        hs)                 REPLY_LANG="Haskell" ;;
        ex|exs)             REPLY_LANG="Elixir" ;;
        erl)                REPLY_LANG="Erlang" ;;
        clj|cljs)           REPLY_LANG="Clojure" ;;
        r|R)                REPLY_LANG="R" ;;
        *)                  REPLY_LANG="" ;;
    esac
}

# stdin: file paths (one per line) -> stdout: only source-code paths.
# Pure filter, unit-testable.
filter_source_paths() {
    local f
    while IFS= read -r f; do
        if is_excluded_file "$f"; then continue; fi
        ext_of "$f"
        [ -n "$REPLY_EXT" ] || continue
        lang_for_ext "$REPLY_EXT"
        [ -n "$REPLY_LANG" ] || continue
        printf '%s\n' "$f"
    done
}

# List all source files under the given folders/files, pruned + filtered.
# -mindepth 1 keeps a top-level folder that happens to be NAMED like a
# pruned dir (e.g. right-clicking a folder called "build") traversable.
list_source_files() {
    local name t first=1
    local -a expr
    while IFS= read -r name; do
        if [ "$first" = 1 ]; then
            expr=(-name "$name")
            first=0
        else
            expr+=(-o -name "$name")
        fi
    done < <(prune_dir_names)
    for t in "$@"; do
        if [ -d "$t" ]; then
            find "$t" -mindepth 1 \( -type d \( "${expr[@]}" \) -prune \) -o -type f -print 2>/dev/null
        elif [ -f "$t" ]; then
            printf '%s\n' "$t"
        fi
    done | filter_source_paths
}

# stdin: source file paths -> stdout: "<nonempty-lines>\t<path>" per file.
# One awk per xargs batch instead of one grep per file (fast on big trees).
# Files with zero non-empty lines produce no row — the file COUNT therefore
# comes from the input list, never from this output.
count_nonempty_batch() {
    tr '\n' '\0' | xargs -0 awk '
        FNR == 1       { if (f != "") print c "\t" f; f = FILENAME; c = 0 }
        /[^[:space:]]/ { c++ }
        END            { if (f != "") print c "\t" f }
    ' 2>/dev/null
}

# stdin: "<lines>\t<path>" -> stdout: "<lines>\t<language>" summed, sorted
# descending. Groups by extension first (cheap), maps to language names via
# lang_for_ext only once per unique extension.
aggregate_by_lang() {
    awk -F'\t' '{
        p = $2
        n = split(p, seg, "/"); base = seg[n]
        k = split(base, dot, "."); ext = (k > 1) ? dot[k] : ""
        if (ext != "") sum[ext] += $1
    } END { for (e in sum) print sum[e] "\t" e }' \
    | while IFS=$'\t' read -r n name; do
        lang_for_ext "$name"
        [ -n "$REPLY_LANG" ] && printf '%s\t%s\n' "$n" "$REPLY_LANG"
    done \
    | awk -F'\t' '{ s[$2] += $1 } END { for (l in s) print s[l] "\t" l }' \
    | sort -rn
}

# Thousands separator with dots (German style): 1234567 -> 1.234.567.
# Manual grouping — printf "%'"'"'d" would need a locale, and LC_NUMERIC=C
# is mandatory here (see repo CLAUDE.md).
format_number() {
    awk -v n="${1:-0}" 'BEGIN {
        s = sprintf("%d", n)
        out = ""
        while (length(s) > 3) {
            out = "." substr(s, length(s) - 2) out
            s = substr(s, 1, length(s) - 3)
        }
        print s out
    }'
}

# stdin: "<lines>\t<language>" sorted desc; $1 = max entries.
# stdout: "Lang1 1.234 · Lang2 567 · ..."
top_langs_line() {
    local max="${1:-3}" out="" n name i=0
    while IFS=$'\t' read -r n name; do
        [ "$i" -ge "$max" ] && break
        [ -n "$name" ] || continue
        if [ -n "$out" ]; then
            out="${out} · ${name} $(format_number "$n")"
        else
            out="${name} $(format_number "$n")"
        fi
        i=$((i + 1))
    done
    printf '%s' "$out"
}

# notify <title> <subtitle> <message> — args go through AppleScript argv,
# so folder names with quotes/backslashes need no escaping.
notify() {
    osascript \
        -e 'on run argv' \
        -e 'display notification (item 3 of argv) with title (item 1 of argv) subtitle (item 2 of argv) sound name "Glass"' \
        -e 'end run' \
        "$1" "$2" "$3" >/dev/null 2>&1 || true
}

# cmd_count <report|notify> <targets...>
cmd_count() {
    local mode="$1"
    shift
    if [ "$#" -lt 1 ]; then
        echo "loc: kein Ordner angegeben (siehe: loc.sh help)" >&2
        return 1
    fi

    local name
    if [ "$#" -eq 1 ]; then
        name="${1%/}"
        name="${name##*/}"
    else
        name="$# Elemente"
    fi

    local tmp
    tmp=$(mktemp)
    list_source_files "$@" > "$tmp"

    local files
    files=$(wc -l < "$tmp" | tr -d '[:space:]')

    if [ "$files" = "0" ]; then
        rm -f "$tmp"
        if [ "$mode" = "notify" ]; then
            notify "LoC — ${name}" "Keine Quellcode-Dateien gefunden" ""
        else
            echo "LoC — ${name}: keine Quellcode-Dateien gefunden."
        fi
        return 0
    fi

    local counts total langs top subtitle
    counts=$(count_nonempty_batch < "$tmp")
    rm -f "$tmp"
    total=$(printf '%s\n' "$counts" | awk -F'\t' '{ s += $1 } END { printf "%d", s }')
    langs=$(printf '%s\n' "$counts" | aggregate_by_lang)
    top=$(printf '%s\n' "$langs" | top_langs_line 3)
    subtitle="$(format_number "$total") Zeilen · $(format_number "$files") Dateien"

    if [ "$mode" = "notify" ]; then
        notify "LoC — ${name}" "$subtitle" "$top"
    else
        echo "LoC — ${name}"
        echo "  ${subtitle}"
        echo ""
        printf '%s\n' "$langs" | while IFS=$'\t' read -r n name; do
            printf '  %-12s %s\n' "$name" "$(format_number "$n")"
        done
    fi
}
# --- END QUICK ACTION CORE ---

cmd_help() {
    cat <<EOF
loc v${LOC_VERSION} — zählt Quellcode-Zeilen (nicht-leere Zeilen)

USAGE
  loc.sh <ordner-oder-datei> [...]   Report auf stdout
  loc.sh notify <ordner> [...]       macOS-Benachrichtigung (Quick Action)
  loc.sh version | help

WAS GEZÄHLT WIRD
  - Nur Dateien mit Quellcode-Endung (py, js, ts, swift, go, rs, sh, ...)
  - Nur nicht-leere Zeilen (mind. ein Nicht-Whitespace-Zeichen);
    Kommentare zählen mit, Leerzeilen nicht
  - Ausgeschlossen: .git, node_modules, venv, build, dist, vendor, ...
    sowie Minified-/Bundle-Dateien (*.min.js, *.min.css, *.bundle.js)
EOF
}

main() {
    case "${1:-help}" in
        version|--version|-v) echo "loc v${LOC_VERSION}" ;;
        help|--help|-h)       cmd_help ;;
        notify)               shift; cmd_count notify "$@" ;;
        *)                    cmd_count report "$@" ;;
    esac
}

# Only run main() when executed directly, not when sourced (for tests).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
