#!/bin/bash
# sleepcheck.sh — Diagnose why the Mac won't sleep and clean up orphaned
# automation browsers (Playwright / MCP) that hold sleep assertions.
#
# Modes:
#   (default)        Show active sleep blockers + orphaned automation browsers
#   kill|-k|--kill   Also terminate orphaned automation browsers
#   version          Print version
#   help|--help      Show help
#
# A common culprit is a leftover Playwright/MCP-controlled Chrome holding a
# "Capturing" NoDisplaySleepAssertion for hours. This finds and (optionally)
# kills it. Uses only built-in tools (pmset, pgrep, ps, osascript).

set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

SLEEPCHECK_VERSION="1.0.0"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# Pure helpers (testable, no side effects beyond stdout)
# ----------------------------------------------------------------------------

# ERE matching orphaned automation-browser processes (Playwright / Puppeteer
# MCP-controlled Chrome/Chromium). Kept as a function so tests can assert it.
browser_match_pattern() {
    printf '%s' 'mcp-chrome|ms-playwright.*--remote-debugging|--remote-debugging-pipe.*ms-playwright'
}

# Reads `pmset -g assertions` output on stdin, prints the per-process lines
# that actively prevent system OR display sleep. Pure text filter — unit
# testable against a fixture.
parse_blockers() {
    grep -E 'pid [0-9]+\(' 2>/dev/null \
        | grep -iE 'PreventUserIdleSystemSleep|PreventSystemSleep|NoDisplaySleep|PreventUserIdleDisplaySleep' \
        || true
}

# Given a single assertion line, echo a short human-readable cause tag.
classify_blocker() {
    local line="$1"
    case "$line" in
        *caffeinate*)         echo "caffeinate — CLI/Claude Code, temporär" ;;
        *NoDisplaySleep*[Cc]apturing*) echo "Capturing — evtl. verwaiste Automation-Instanz" ;;
        *Chrome*|*chrome*|*Chromium*)  echo "Browser — evtl. verwaiste Automation-Instanz" ;;
        *powerd*)             echo "powerd — Display an, normal" ;;
        *sharingd*|*Handoff*) echo "Handoff/Sharing, temporär" ;;
        *WhatsApp*|*runningboardd*)     echo "App-Hintergrundtask, temporär" ;;
        *)                    echo "anderer Prozess" ;;
    esac
}

# Echo PIDs of orphaned automation browsers (one per line, empty if none).
orphan_browser_pids() {
    pgrep -f "$(browser_match_pattern)" 2>/dev/null || true
}

# ----------------------------------------------------------------------------
# Commands
# ----------------------------------------------------------------------------

cmd_check() {
    local kill_mode="${1:-0}"

    echo -e "${BOLD}Sleep-Blocker (aktive Assertions)${NC}"
    local blockers
    blockers=$(pmset -g assertions 2>/dev/null | parse_blockers)
    if [ -z "$blockers" ]; then
        echo -e "  ${GREEN}–${NC} keine"
    else
        while IFS= read -r line; do
            [ -z "$line" ] && continue
            local pid cause
            pid=$(echo "$line" | sed -n 's/.*pid \([0-9]*\)(.*/\1/p')
            cause=$(classify_blocker "$line")
            printf "  • pid %-7s %s\n" "${pid:-?}" "$cause"
        done <<< "$blockers"
    fi

    echo ""
    echo -e "${BOLD}Verwaiste Automation-Browser (Playwright/MCP)${NC}"
    local pids
    pids=$(orphan_browser_pids)
    if [ -z "$pids" ]; then
        echo -e "  ${GREEN}–${NC} keine gefunden"
        return 0
    fi

    local p et
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        et=$(ps -o etime= -p "$p" 2>/dev/null | tr -d ' ')
        echo -e "  ${YELLOW}•${NC} pid ${p}  (Laufzeit ${et:-?})"
    done <<< "$pids"

    if [ "$kill_mode" = "1" ]; then
        echo ""
        echo -e "${BOLD}Beende verwaiste Browser…${NC}"
        local killed=0
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            kill "$p" 2>/dev/null || true
            killed=$((killed + 1))
        done <<< "$pids"
        sleep 1
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            ps -p "$p" >/dev/null 2>&1 && kill -9 "$p" 2>/dev/null || true
        done <<< "$pids"
        echo -e "  ${GREEN}✓${NC} ${killed} Prozess(e) beendet"
    else
        echo ""
        echo -e "  → Zum Beenden:  sleepcheck.sh kill"
    fi
}

cmd_help() {
    cat <<EOF
sleepcheck v${SLEEPCHECK_VERSION}

USAGE
  sleepcheck.sh [command]

COMMANDS
  (none)           Show sleep blockers + orphaned automation browsers
  kill | -k        Also terminate orphaned Playwright/MCP browsers
  version          Print version
  help             Show this help

WHAT IT FINDS
  • Active power assertions that prevent system or display sleep
    (caffeinate, NoDisplaySleep "Capturing", powerd, …)
  • Orphaned automation browsers from Playwright / MCP that hold a
    "Capturing" assertion for hours and keep the display awake

NOTES
  • A 'caffeinate' owned by Claude Code is normal and clears when the
    session ends — it is reported, never killed.
  • Only matches Playwright/MCP Chrome (user-data-dir mcp-chrome,
    --remote-debugging-pipe); your normal browser is never touched.
EOF
}

main() {
    case "${1:-check}" in
        kill|--kill|-k)          cmd_check 1 ;;
        version|--version|-v)    echo "sleepcheck v${SLEEPCHECK_VERSION}" ;;
        help|--help|-h)          cmd_help ;;
        check|*)                 cmd_check 0 ;;
    esac
}

# Only run main() when executed directly, not when sourced (for tests).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
