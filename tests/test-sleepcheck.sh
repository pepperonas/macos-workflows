# Tests for workflows/sleepcheck/sleepcheck.sh
# Sourced by tests/run.sh — test functions must start with `test_`.

# shellcheck disable=SC1091
source "$REPO_ROOT/workflows/sleepcheck/sleepcheck.sh"

# Sample `pmset -g assertions` output (real-world shape).
SAMPLE_ASSERTIONS='Assertion status system-wide:
   PreventUserIdleSystemSleep     1
   NoDisplaySleepAssertion        1
Listed by owning process:
   pid 1092(sharingd): [0x0009] 00:01:01 PreventUserIdleSystemSleep named: "Handoff"
   pid 67577(Google Chrome): [0x0008] 18:57:40 NoDisplaySleepAssertion named: "Capturing"
   pid 578(powerd): [0x0009] 03:19:03 PreventUserIdleSystemSleep named: "Powerd - Prevent sleep while display is on"
   pid 58390(caffeinate): [0x0009] 00:00:06 PreventUserIdleSystemSleep named: "caffeinate command-line tool"
No kernel assertions.'

# ----- browser_match_pattern -----

test_pattern_matches_mcp_chrome() {
    local pat
    pat=$(browser_match_pattern)
    assert_contains "$pat" "mcp-chrome" "pattern targets mcp-chrome user-data-dir"
}

test_pattern_matches_playwright() {
    local pat
    pat=$(browser_match_pattern)
    assert_contains "$pat" "ms-playwright" "pattern targets ms-playwright cache"
}

test_pattern_matches_remote_debugging() {
    local pat
    pat=$(browser_match_pattern)
    assert_contains "$pat" "remote-debugging" "pattern targets the automation debug flag"
}

# ----- parse_blockers (pure stdin filter) -----

test_parse_blockers_keeps_process_lines() {
    local out
    out=$(printf '%s\n' "$SAMPLE_ASSERTIONS" | parse_blockers)
    assert_contains "$out" "67577" "Capturing Chrome blocker is kept"
}

test_parse_blockers_drops_summary_lines() {
    local out count
    out=$(printf '%s\n' "$SAMPLE_ASSERTIONS" | parse_blockers)
    # 4 owning-process lines all prevent system/display sleep
    count=$(printf '%s\n' "$out" | grep -c 'pid ')
    assert_equal "4" "$count" "exactly the 4 per-process blocker lines remain"
}

test_parse_blockers_excludes_kernel_note() {
    local out
    out=$(printf '%s\n' "$SAMPLE_ASSERTIONS" | parse_blockers)
    if [[ "$out" == *"No kernel assertions"* ]]; then
        echo "    ✗ summary line leaked into blockers"
        return 1
    fi
    return 0
}

test_parse_blockers_empty_input() {
    local out
    out=$(printf '' | parse_blockers)
    assert_equal "" "$out" "empty input yields no blockers"
}

# ----- classify_blocker -----

test_classify_caffeinate() {
    local out
    out=$(classify_blocker 'pid 58390(caffeinate): ... caffeinate command-line tool')
    assert_contains "$out" "caffeinate" "caffeinate line classified as caffeinate"
}

test_classify_capturing() {
    local out
    out=$(classify_blocker 'pid 67577(Google Chrome): ... NoDisplaySleepAssertion named: "Capturing"')
    assert_contains "$out" "verwaiste" "Capturing line flagged as possibly orphaned"
}

test_classify_powerd() {
    local out
    out=$(classify_blocker 'pid 578(powerd): ... Prevent sleep while display is on')
    assert_contains "$out" "normal" "powerd line classified as normal"
}

test_classify_unknown() {
    local out
    out=$(classify_blocker 'pid 999(somethingelse): ... whatever')
    assert_contains "$out" "anderer" "unknown owner falls through to generic tag"
}

# ----- Subcommand smoke tests (subprocess, main not triggered by source) -----

test_help_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/sleepcheck/sleepcheck.sh" help 2>&1)
    assert_contains "$out" "USAGE" "help shows USAGE section"
}

test_version_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/sleepcheck/sleepcheck.sh" version 2>&1)
    assert_contains "$out" "sleepcheck v" "version output contains tool name"
}

test_check_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/sleepcheck/sleepcheck.sh" check 2>&1)
    assert_contains "$out" "Sleep-Blocker" "check output has the blockers section header"
}

# ----- Plist validity -----

test_wflow_plist_valid() {
    local plist="$REPO_ROOT/workflows/sleepcheck/Sleep Check.workflow/Contents/document.wflow"
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

test_info_plist_valid() {
    local plist="$REPO_ROOT/workflows/sleepcheck/Sleep Check.workflow/Contents/Info.plist"
    if plutil -lint "$plist" >/dev/null 2>&1; then
        return 0
    else
        echo "    ✗ Info.plist failed plutil -lint"
        return 1
    fi
}
