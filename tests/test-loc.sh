# Tests for workflows/loc/loc.sh
# Sourced by tests/run.sh — test functions must start with `test_`.

# shellcheck disable=SC1091
source "$REPO_ROOT/workflows/loc/loc.sh"

# Builds a small project tree with source, non-source, excluded dirs and
# minified files. Echoes the tempdir path; callers must rm -rf it.
# Expected: 4 source files (app.py 3, main.js 2, comp.jsx 4, empty.py 0)
# -> 9 lines, 4 files, JavaScript 6 / Python 3.
_loc_make_fixture() {
    local d
    d=$(mktemp -d)
    mkdir -p "$d/src" "$d/node_modules/lib" "$d/build"
    printf 'a\n\nb\nc\n' > "$d/src/app.py"
    printf 'x=1\ny=2\n' > "$d/main.js"
    printf 'l1\nl2\nl3\nl4\n' > "$d/comp.jsx"
    : > "$d/empty.py"
    printf 'nope\n' > "$d/node_modules/lib/x.js"
    printf 'nope\n' > "$d/build/gen.py"
    printf 'm\n' > "$d/app.min.js"
    printf '# docs\n' > "$d/README.md"
    printf '%s\n' "$d"
}

# ----- prune list -----

test_prune_list_has_vcs_and_dep_dirs() {
    local list rc=0
    list=$(prune_dir_names)
    assert_contains "$list" ".git" "prunes VCS dirs" || rc=1
    assert_contains "$list" "node_modules" "prunes JS deps" || rc=1
    assert_contains "$list" "venv" "prunes Python venvs" || rc=1
    assert_contains "$list" "dist" "prunes build output" || rc=1
    return $rc
}

# ----- lang_for_ext / ext_of (REPLY_* protocol, fork-free) -----

test_lang_for_ext_python() {
    lang_for_ext py
    assert_equal "Python" "$REPLY_LANG" "py maps to Python"
}

test_lang_for_ext_merges_js_family() {
    local rc=0
    lang_for_ext jsx
    assert_equal "JavaScript" "$REPLY_LANG" "jsx maps to JavaScript" || rc=1
    lang_for_ext mjs
    assert_equal "JavaScript" "$REPLY_LANG" "mjs maps to JavaScript" || rc=1
    return $rc
}

test_lang_for_ext_unknown_is_empty() {
    lang_for_ext md
    assert_equal "" "$REPLY_LANG" "md is not source"
}

test_ext_of_basic() {
    ext_of "/a/b/app.py"
    assert_equal "py" "$REPLY_EXT" "extension extracted from path"
}

test_ext_of_no_extension() {
    ext_of "/a/b/Makefile"
    assert_equal "" "$REPLY_EXT" "no extension yields empty"
}

# ----- is_excluded_file -----

test_excluded_minified() {
    if is_excluded_file "/x/app.min.js"; then
        return 0
    else
        echo "    ✗ *.min.js should be excluded"
        return 1
    fi
}

test_regular_js_not_excluded() {
    if is_excluded_file "/x/app.js"; then
        echo "    ✗ plain .js must not be excluded"
        return 1
    fi
    return 0
}

# ----- filter_source_paths (pure stdin filter) -----

test_filter_source_paths() {
    local out
    out=$(printf '%s\n' /a/app.py /a/readme.md /a/x.min.js /a/Makefile /a/deep/tool.rs \
        | filter_source_paths)
    assert_equal "/a/app.py
/a/deep/tool.rs" "$out" "only whitelisted source files pass"
}

# ----- format_number -----

test_format_number_small() {
    assert_equal "999" "$(format_number 999)" "no separator below 1000"
}

test_format_number_thousands() {
    assert_equal "1.000" "$(format_number 1000)" "dot separator at 1000"
}

test_format_number_millions() {
    assert_equal "1.234.567" "$(format_number 1234567)" "grouping repeats"
}

# ----- top_langs_line -----

test_top_langs_line_format() {
    local out
    out=$(printf '6\tJavaScript\n3\tPython\n' | top_langs_line 3)
    assert_equal "JavaScript 6 · Python 3" "$out" "middle-dot separated pairs"
}

test_top_langs_line_caps_entries() {
    local out
    out=$(printf '9\tA\n8\tB\n7\tC\n6\tD\n' | top_langs_line 3)
    if [[ "$out" == *"D"* ]]; then
        echo "    ✗ fourth language leaked past the cap"
        return 1
    fi
    assert_contains "$out" "C 7" "third language still present"
}

# ----- end-to-end on a fixture tree -----

test_report_counts_fixture() {
    local d out rc=0
    d=$(_loc_make_fixture)
    out=$(bash "$REPO_ROOT/workflows/loc/loc.sh" "$d" 2>&1)
    assert_contains "$out" "9 Zeilen · 4 Dateien" "non-empty lines and file count" || rc=1
    if [[ "$out" == *node_modules* ]]; then
        echo "    ✗ node_modules leaked into the report"
        rc=1
    fi
    rm -rf "$d"
    return $rc
}

test_report_language_ranking() {
    local d out js_line py_line rc=0
    d=$(_loc_make_fixture)
    out=$(bash "$REPO_ROOT/workflows/loc/loc.sh" "$d" 2>&1)
    js_line=$(printf '%s\n' "$out" | grep -n 'JavaScript' | cut -d: -f1 | head -1)
    py_line=$(printf '%s\n' "$out" | grep -n 'Python' | cut -d: -f1 | head -1)
    if [ -z "$js_line" ] || [ -z "$py_line" ]; then
        echo "    ✗ expected both JavaScript and Python in the report"
        rc=1
    elif [ "$js_line" -ge "$py_line" ]; then
        echo "    ✗ JavaScript (6 lines) should rank before Python (3)"
        rc=1
    fi
    rm -rf "$d"
    return $rc
}

test_report_empty_folder() {
    local d out rc=0
    d=$(mktemp -d)
    printf 'no source here\n' > "$d/notes.txt"
    out=$(bash "$REPO_ROOT/workflows/loc/loc.sh" "$d" 2>&1)
    assert_contains "$out" "keine Quellcode-Dateien" "empty result is stated, not zero-formatted" || rc=1
    rm -rf "$d"
    return $rc
}

# ----- subcommands -----

test_help_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/loc/loc.sh" help 2>&1)
    assert_contains "$out" "USAGE" "help shows USAGE section"
}

test_version_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/loc/loc.sh" version 2>&1)
    assert_contains "$out" "loc v" "version output contains tool name"
}

# ----- plist validity -----

test_loc_wflow_plist_valid() {
    local plist="$REPO_ROOT/workflows/loc/LoC.workflow/Contents/document.wflow"
    if [ ! -f "$plist" ]; then
        echo "    ✗ wflow plist not found"
        return 1
    fi
    if plutil -lint "$plist" >/dev/null 2>&1; then
        return 0
    else
        echo "    ✗ wflow plist failed plutil -lint"
        return 1
    fi
}

test_loc_info_plist_valid() {
    local plist="$REPO_ROOT/workflows/loc/LoC.workflow/Contents/Info.plist"
    if plutil -lint "$plist" >/dev/null 2>&1; then
        return 0
    else
        echo "    ✗ Info.plist failed plutil -lint"
        return 1
    fi
}

test_loc_service_targets_folders() {
    local out
    out=$(cat "$REPO_ROOT/workflows/loc/LoC.workflow/Contents/Info.plist")
    assert_contains "$out" "public.folder" "Quick Action is offered for folders"
}

# ----- drift guard: embedded script == QUICK ACTION CORE of loc.sh -----
# The document.wflow is generated from loc.sh; this re-derives both sides.
# COMMAND_STRING appears twice in the wflow (empty AMParameterProperties
# declaration first), so extraction anchors at the ActionParameters block.

test_wflow_embeds_core_verbatim() {
    local shf="$REPO_ROOT/workflows/loc/loc.sh"
    local wf="$REPO_ROOT/workflows/loc/LoC.workflow/Contents/document.wflow"
    local core expected actual
    core=$(sed -n '/^# --- BEGIN QUICK ACTION CORE ---$/,/^# --- END QUICK ACTION CORE ---$/p' "$shf" | sed '1d;$d')
    expected="${core}

cmd_count notify \"\$@\""
    actual=$(sed -n '/<key>ActionParameters<\/key>/,$p' "$wf" \
        | sed -n '/<key>COMMAND_STRING<\/key>/,/<\/string>/p' \
        | sed '1d' \
        | sed -e 's/^[[:space:]]*<string>//' -e 's|</string>$||' \
        | sed -e 's/&gt;/>/g' -e 's/&lt;/</g' -e 's/&amp;/\&/g')
    assert_equal "$expected" "$actual" "embedded Quick Action script matches loc.sh core"
}
