#!/bin/bash
# Tests for the Rename Tracks Quick Action.
#
# The Python logic has its own suite (workflows/rename-tracks/test-rename-tracks.py,
# ~100 assertions). These tests cover the *bundle*: plists lint, the embedded
# copy must not drift from the source, and the shell wrapper's control flow.

WF="$REPO_ROOT/workflows/rename-tracks"
BUNDLE="$WF/Rename Tracks.workflow/Contents"

# --- Extract the COMMAND_STRING from the ActionParameters block ---------------
# (COMMAND_STRING appears twice in a document.wflow; anchor on ActionParameters.)
_command_string() {
    plutil -extract actions.0.action.ActionParameters.COMMAND_STRING raw -o - \
        "$BUNDLE/document.wflow" 2>/dev/null
}

# --- Bundle invariants -------------------------------------------------------

test_renametracks_info_plist_valid() {
    assert_contains "$(plutil -lint "$BUNDLE/Info.plist")" "OK" "Info.plist lints"
}

test_renametracks_wflow_plist_valid() {
    assert_contains "$(plutil -lint "$BUNDLE/document.wflow")" "OK" "document.wflow lints"
}

test_renametracks_menu_name() {
    local name
    name=$(plutil -extract NSServices.0.NSMenuItem.default raw -o - "$BUNDLE/Info.plist" 2>/dev/null)
    assert_equal "Rename Tracks" "$name" "menu name is Rename Tracks"
}

# Folders only — the action operates on a directory, not on single tracks.
test_renametracks_accepts_folders_only() {
    local types
    types=$(plutil -extract NSServices.0.NSSendFileTypes json -o - "$BUNDLE/Info.plist" 2>/dev/null)
    assert_equal '["public.folder"]' "$types" "NSSendFileTypes is public.folder only"
}

test_renametracks_uses_zsh_and_arguments() {
    local shell method
    shell=$(plutil -extract actions.0.action.ActionParameters.shell raw -o - "$BUNDLE/document.wflow" 2>/dev/null)
    method=$(plutil -extract actions.0.action.ActionParameters.inputMethod raw -o - "$BUNDLE/document.wflow" 2>/dev/null)
    assert_equal "/bin/zsh" "$shell" "shell is /bin/zsh"
    assert_equal "1" "$method" "inputMethod is 1 (arguments)"
}

# Automator runs with a stripped PATH — without this only /usr/bin/python3 is found.
test_renametracks_exports_path() {
    assert_contains "$(_command_string)" \
        'export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"' "COMMAND_STRING exports PATH"
}

# UUIDs must not collide with the LoC bundle this was templated from.
test_renametracks_uuids_differ_from_template() {
    local k a b
    for k in UUID InputUUID OutputUUID; do
        a=$(plutil -extract "actions.0.action.$k" raw -o - \
            "$REPO_ROOT/workflows/loc/LoC.workflow/Contents/document.wflow" 2>/dev/null)
        b=$(plutil -extract "actions.0.action.$k" raw -o - "$BUNDLE/document.wflow" 2>/dev/null)
        if [ "$a" = "$b" ]; then
            echo "    ✗ $k still matches the LoC template"
            return 1
        fi
    done
    return 0
}

# --- Drift guard: embedded copy == source ------------------------------------
# The .wflow carries a full copy of rename-tracks.py so the Quick Action works
# without this repo. Byte-for-byte pin, regenerate with build-wflow.py --write.

test_renametracks_embedded_python_matches_source() {
    local embedded source
    embedded=$(_command_string | sed -n "/^cat > \"\$skript\" <<'PYEOF'$/,/^PYEOF$/p" | sed '1d;$d')
    source=$(cat "$WF/rename-tracks.py")
    # Trailing newline is stripped on both sides by $( ).
    assert_equal "$source" "$embedded" "embedded Python matches rename-tracks.py"
}

test_renametracks_generator_reports_current() {
    local out
    out=$(cd "$WF" && python3 build-wflow.py 2>&1)
    assert_contains "$out" "aktuell" "build-wflow.py says the bundle is current"
}

# --- Python suite ------------------------------------------------------------

test_renametracks_python_suite_passes() {
    local out
    out=$(cd "$WF" && python3 -B test-rename-tracks.py 2>&1)
    assert_contains "$out" "Alle Tests grün" "Python suite passes"
}

# --- Shell control flow ------------------------------------------------------
# Driven with a stubbed osascript so the dialogs neither block nor appear.

_run_action() {
    local folder="$1" answer="$2" tmp
    tmp=$(mktemp -d)
    _command_string > "$tmp/cmd.zsh"
    mkdir -p "$tmp/bin"
    {
        echo '#!/bin/sh'
        echo 'shift 2>/dev/null'
        echo 'for a in "$@"; do echo "$a" >> "$QA_LOG"; done'
        echo 'cat > /dev/null'
        echo 'echo "$QA_ANSWER"'
    } > "$tmp/bin/osascript"
    chmod +x "$tmp/bin/osascript"
    QA_LOG="$tmp/log" QA_ANSWER="$answer" PATH="$tmp/bin:$PATH" \
        /bin/zsh "$tmp/cmd.zsh" "$folder" >/dev/null 2>&1
    cat "$tmp/log" 2>/dev/null
    rm -rf "$tmp"
}

_fixture_folder() {
    local d
    d=$(mktemp -d)
    : > "$d/ABC - The Look Of Love.m4a"
    : > "$d/Toto - Africa.m4a"
    : > "$d/One - Two - Three.m4a"
    echo "$d"
}

test_renametracks_confirm_renames() {
    local d
    d=$(_fixture_folder)
    _run_action "$d" "Umbenennen" > /dev/null
    local ok=0
    [ -f "$d/ABC - The Look of Love.m4a" ] || { echo "    ✗ file was not renamed"; ok=1; }
    [ -f "$d/One - Two - Three.m4a" ] || { echo "    ✗ ambiguous name was touched"; ok=1; }
    rm -rf "$d"
    return $ok
}

test_renametracks_cancel_changes_nothing() {
    local d before after
    d=$(_fixture_folder)
    before=$(ls "$d")
    _run_action "$d" "Abbrechen" > /dev/null
    after=$(ls "$d")
    rm -rf "$d"
    assert_equal "$before" "$after" "cancelling leaves every file untouched"
}

test_renametracks_reports_nothing_to_do() {
    local d out
    d=$(mktemp -d)
    : > "$d/Toto - Africa.m4a"
    out=$(_run_action "$d" "OK")
    rm -rf "$d"
    assert_contains "$out" "bereits der Konvention" "clean folder reports nothing to do"
}

test_renametracks_skips_non_folders() {
    local d out
    d=$(mktemp -d)
    : > "$d/ABC - The Look Of Love.m4a"
    out=$(_run_action "$d/ABC - The Look Of Love.m4a" "Umbenennen")
    local ok=0
    [ -n "$out" ] && { echo "    ✗ a plain file produced a dialog"; ok=1; }
    [ -f "$d/ABC - The Look Of Love.m4a" ] || { echo "    ✗ file was renamed anyway"; ok=1; }
    rm -rf "$d"
    return $ok
}
