# Tests for workflows/cleanup-caches/cleanup-caches.sh
# Sourced by tests/run.sh — test functions must start with `test_`.

# shellcheck disable=SC1091
source "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh"

# ----- bytes_to_human -----

test_bytes_to_human_zero() {
    local out
    out=$(bytes_to_human 0)
    assert_equal "0 B" "$out" "0 bytes formats as '0 B'"
}

test_bytes_to_human_1023b() {
    local out
    out=$(bytes_to_human 1023)
    assert_equal "1023 B" "$out" "1023 bytes stays as bytes"
}

test_bytes_to_human_1kb() {
    local out
    out=$(bytes_to_human 1024)
    assert_equal "1 KB" "$out" "1024 bytes formats as '1 KB'"
}

test_bytes_to_human_1mb() {
    local out
    out=$(bytes_to_human 1048576)
    assert_equal "1 MB" "$out" "1 MiB formats as '1 MB'"
}

test_bytes_to_human_500mb() {
    local out
    out=$(bytes_to_human 524288000)
    assert_equal "500 MB" "$out" "500 MiB formats correctly"
}

test_bytes_to_human_1gb() {
    local out
    out=$(bytes_to_human 1073741824)
    assert_equal "1.0 GB" "$out" "1 GiB formats with one decimal"
}

test_bytes_to_human_6gb() {
    local out
    out=$(bytes_to_human 6442450944)
    assert_equal "6.0 GB" "$out" "6 GiB formats correctly"
}

# ----- dir_size_bytes -----

test_dir_size_bytes_nonexistent() {
    local out
    out=$(dir_size_bytes "/tmp/__nonexistent_$$")
    assert_equal "0" "$out" "missing dir returns 0"
}

test_dir_size_bytes_empty_dir() {
    local tmp
    tmp=$(mktemp -d)
    local out
    out=$(dir_size_bytes "$tmp")
    rm -rf "$tmp"
    # An empty dir on macOS reports 0 KB via du
    if [ "$out" -ge 0 ] && [ "$out" -le 4096 ]; then
        return 0
    else
        echo "    ✗ empty dir returned $out (expected 0..4096)"
        return 1
    fi
}

test_dir_size_bytes_with_data() {
    local tmp
    tmp=$(mktemp -d)
    # Write 2 KB of data
    dd if=/dev/zero of="$tmp/data.bin" bs=1024 count=2 2>/dev/null
    local out
    out=$(dir_size_bytes "$tmp")
    rm -rf "$tmp"
    if [ "$out" -ge 2048 ] && [ "$out" -le 16384 ]; then
        return 0
    else
        echo "    ✗ dir with 2KB returned $out (expected 2048..16384)"
        return 1
    fi
}

# ----- cleanup_targets -----

test_cleanup_targets_count() {
    local count
    count=$(cleanup_targets | wc -l | tr -d ' ')
    assert_equal "5" "$count" "exactly 5 cleanup targets"
}

test_cleanup_targets_contains_caches() {
    local out
    out=$(cleanup_targets)
    assert_contains "$out" "Library/Caches" "targets include Library/Caches"
}

test_cleanup_targets_contains_npm() {
    local out
    out=$(cleanup_targets)
    assert_contains "$out" ".npm/_cacache" "targets include npm cache"
}

test_cleanup_targets_contains_gradle() {
    local out
    out=$(cleanup_targets)
    assert_contains "$out" ".gradle/caches" "targets include Gradle"
}

# ----- free_disk_summary -----

test_free_disk_summary_format() {
    local out
    out=$(free_disk_summary)
    assert_contains "$out" "available" "free disk summary contains 'available'"
}

test_free_disk_summary_used() {
    local out
    out=$(free_disk_summary)
    assert_contains "$out" "used" "free disk summary contains 'used'"
}

# ----- Smoke tests via subshell (don't trigger main since we sourced) -----

test_help_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh" help 2>&1)
    assert_contains "$out" "USAGE" "help shows USAGE section"
}

test_version_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh" version 2>&1)
    assert_contains "$out" "cleanup-caches v" "version output contains tool name"
}

test_sizes_command_subprocess() {
    local out
    out=$(bash "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh" sizes 2>&1)
    assert_contains "$out" "Gesamt:" "sizes output contains total line"
}

test_sizes_command_no_deletion() {
    # Create a probe file in a temp dir mimicking a cache target,
    # ensure 'sizes' mode does not touch HOME data.
    local probe="$HOME/.cleanup-caches-test-probe-$$"
    echo "do-not-touch" > "$probe"
    bash "$REPO_ROOT/workflows/cleanup-caches/cleanup-caches.sh" sizes >/dev/null 2>&1
    local status=0
    if [ -f "$probe" ] && [ "$(cat "$probe")" = "do-not-touch" ]; then
        status=0
    else
        echo "    ✗ probe file was modified or deleted"
        status=1
    fi
    rm -f "$probe"
    return "$status"
}

# ----- Plist validity (light integration test) -----

test_wflow_plist_valid() {
    local plist="$REPO_ROOT/workflows/cleanup-caches/Cleanup Caches.workflow/Contents/document.wflow"
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
    local plist="$REPO_ROOT/workflows/cleanup-caches/Cleanup Caches.workflow/Contents/Info.plist"
    if plutil -lint "$plist" >/dev/null 2>&1; then
        return 0
    else
        echo "    ✗ Info.plist failed plutil -lint"
        return 1
    fi
}
