#!/bin/bash
# Plain-bash test runner. No external dependencies.
# Usage: ./tests/run.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_ROOT

GREEN='\033[0;32m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0
FAILED_TESTS=()

assert_equal() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-assertion}"
    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo -e "    ${RED}✗${NC} ${msg}"
        echo -e "      expected: ${DIM}${expected}${NC}"
        echo -e "      actual:   ${DIM}${actual}${NC}"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-substring}"
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo -e "    ${RED}✗${NC} ${msg}"
        echo -e "      haystack: ${DIM}${haystack}${NC}"
        echo -e "      needle:   ${DIM}${needle}${NC}"
        return 1
    fi
}

assert_success() {
    local exit_code="$1"
    local msg="${2:-command should succeed}"
    if [ "$exit_code" -eq 0 ]; then
        return 0
    else
        echo -e "    ${RED}✗${NC} ${msg} (exit=${exit_code})"
        return 1
    fi
}

export -f assert_equal assert_contains assert_success

run_test() {
    local test_func="$1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if "$test_func"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo -e "  ${GREEN}✓${NC} ${test_func}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        FAILED_TESTS+=("$test_func")
        echo -e "  ${RED}✗${NC} ${test_func}"
    fi
}

# ---------- Run test files ----------
echo -e "${BOLD}Running tests...${NC}"
echo ""

for test_file in "$SCRIPT_DIR"/test-*.sh; do
    [ -f "$test_file" ] || continue
    echo -e "${BOLD}$(basename "$test_file" .sh)${NC}"
    # shellcheck disable=SC1090
    source "$test_file"
    # Each test file defines test_* functions; run them all
    for fn in $(declare -F | awk '{print $3}' | grep '^test_'); do
        run_test "$fn"
    done
    # Cleanup function references for next file
    while IFS= read -r fn; do
        unset -f "$fn"
    done < <(declare -F | awk '{print $3}' | grep '^test_')
    echo ""
done

# ---------- Summary ----------
echo "─────────────────────────"
if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}All ${TESTS_TOTAL} tests passed.${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}${TESTS_FAILED} of ${TESTS_TOTAL} tests failed:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $t"
    done
    exit 1
fi
