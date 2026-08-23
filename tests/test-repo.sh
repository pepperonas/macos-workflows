# Repo-wide invariants: every workflow bundle is valid, documented, and the
# top-level docs (README badges, VERSION, CHANGELOG) match reality.
# These are docs-sync pins — they exist so the documentation cannot silently
# drift from the repo (e.g. a bundle lost by `open`-install, a stale badge).
# Sourced by tests/run.sh — test functions must start with `test_`.

_repo_workflow_dirs() {
    ls -d "$REPO_ROOT"/workflows/*/ 2>/dev/null
}

_repo_wflow_plists() {
    ls "$REPO_ROOT"/workflows/*/*.workflow/Contents/document.wflow 2>/dev/null
}

_repo_info_plists() {
    ls "$REPO_ROOT"/workflows/*/*.workflow/Contents/Info.plist 2>/dev/null
}

# Every workflow dir must contain a .workflow bundle. This catches the
# `open`-install caveat: installing MOVES the bundle out of the repo, and
# workflows/new-textfile/ was empty for months before this test existed.
test_repo_every_workflow_has_bundle() {
    local d rc=0
    while IFS= read -r d; do
        if ! ls -d "$d"*.workflow >/dev/null 2>&1; then
            echo "    ✗ $(basename "$d") has no .workflow bundle (lost via open-install?)"
            rc=1
        fi
    done < <(_repo_workflow_dirs)
    return $rc
}

test_repo_every_workflow_has_readme() {
    local d rc=0
    while IFS= read -r d; do
        if [ ! -f "${d}README.md" ]; then
            echo "    ✗ $(basename "$d") has no README.md"
            rc=1
        fi
    done < <(_repo_workflow_dirs)
    return $rc
}

test_repo_all_wflow_plists_lint() {
    local p rc=0
    while IFS= read -r p; do
        if ! plutil -lint "$p" >/dev/null 2>&1; then
            echo "    ✗ plutil -lint failed: $p"
            rc=1
        fi
    done < <(_repo_wflow_plists)
    return $rc
}

test_repo_all_info_plists_lint() {
    local p rc=0
    while IFS= read -r p; do
        if ! plutil -lint "$p" >/dev/null 2>&1; then
            echo "    ✗ plutil -lint failed: $p"
            rc=1
        fi
    done < <(_repo_info_plists)
    return $rc
}

# Two services with the same menu name would shadow each other in Finder.
test_repo_menu_names_unique() {
    local p names dupes
    names=""
    while IFS= read -r p; do
        names="${names}$(plutil -extract 'NSServices.0.NSMenuItem.default' raw "$p" 2>/dev/null)
"
    done < <(_repo_info_plists)
    dupes=$(printf '%s' "$names" | sort | uniq -d)
    if [ -n "$dupes" ]; then
        echo "    ✗ duplicate service menu names: $dupes"
        return 1
    fi
    return 0
}

# A service without NSSendFileTypes/NSSendTypes never appears in any menu.
test_repo_every_service_declares_input() {
    local p rc=0
    while IFS= read -r p; do
        if ! plutil -extract 'NSServices.0.NSSendFileTypes.0' raw "$p" >/dev/null 2>&1 \
            && ! plutil -extract 'NSServices.0.NSSendTypes.0' raw "$p" >/dev/null 2>&1; then
            echo "    ✗ no NSSendFileTypes/NSSendTypes: $p"
            rc=1
        fi
    done < <(_repo_info_plists)
    return $rc
}

# CLAUDE.md rule: python3 scripts must export a Homebrew-aware PATH, because
# Automator's stripped PATH only finds the pip-less system Python.
test_repo_python_scripts_export_path() {
    local p cmd rc=0
    while IFS= read -r p; do
        cmd=$(plutil -extract 'actions.0.action.ActionParameters.COMMAND_STRING' raw "$p" 2>/dev/null)
        if [[ "$cmd" == *python3* && "$cmd" != *"/opt/homebrew/bin"* ]]; then
            echo "    ✗ python3 without Homebrew PATH export: $p"
            rc=1
        fi
    done < <(_repo_wflow_plists)
    return $rc
}

# CLAUDE.md pins all bundles to Automator 2.10 / document version 2.
test_repo_automator_version_pinned() {
    local p v rc=0
    while IFS= read -r p; do
        v=$(plutil -extract 'AMApplicationVersion' raw "$p" 2>/dev/null)
        if [ "$v" != "2.10" ]; then
            echo "    ✗ AMApplicationVersion is '$v' (expected 2.10): $p"
            rc=1
        fi
    done < <(_repo_wflow_plists)
    return $rc
}

# Every workflow must be linked from a table in the root README.
test_repo_readme_links_all_workflows() {
    local d name readme rc=0
    readme=$(cat "$REPO_ROOT/README.md")
    while IFS= read -r d; do
        name=$(basename "$d")
        if [[ "$readme" != *"workflows/${name}/"* ]]; then
            echo "    ✗ workflows/${name}/ not linked in README.md"
            rc=1
        fi
    done < <(_repo_workflow_dirs)
    return $rc
}

# The "collection of N Quick Actions" claim must match the actual dir count.
test_repo_readme_count_matches_dirs() {
    local claimed actual
    claimed=$(sed -n 's/.*collection of \([0-9][0-9]*\) macOS Finder Quick Actions.*/\1/p' \
        "$REPO_ROOT/README.md" | head -1)
    actual=$(_repo_workflow_dirs | wc -l | tr -d ' ')
    assert_equal "$actual" "$claimed" "README workflow count matches workflows/ dirs"
}

test_repo_version_matches_readme_badge() {
    local version badge
    version=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
    badge=$(sed -n 's/.*badge\/version-\([0-9.]*\)-blue.*/\1/p' "$REPO_ROOT/README.md" | head -1)
    assert_equal "$version" "$badge" "VERSION matches README version badge"
}

test_repo_changelog_has_current_version() {
    local version
    version=$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")
    if grep -q "^## \[${version}\]" "$REPO_ROOT/CHANGELOG.md"; then
        return 0
    fi
    echo "    ✗ CHANGELOG.md has no '## [${version}]' entry"
    return 1
}

# The tests badge must state the real suite size (test_* functions across
# all test files — exactly what tests/run.sh discovers and executes).
test_repo_tests_badge_matches_suite() {
    local actual badge
    actual=$(grep -hE '^test_[a-z0-9_]+\(\)' "$REPO_ROOT"/tests/test-*.sh | wc -l | tr -d ' ')
    badge=$(sed -n 's/.*badge\/tests-\([0-9][0-9]*\)%20passing.*/\1/p' "$REPO_ROOT/README.md" | head -1)
    assert_equal "$actual" "$badge" "README tests badge matches test function count"
}
