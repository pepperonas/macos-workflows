#!/bin/bash
# cleanup-caches.sh — Free disk space by clearing caches and PM2 logs.
#
# Modes:
#   (default)        Clean caches and report freed space
#   sizes|--sizes    Preview sizes only, no deletion
#   version          Print version
#   help|--help      Show help
#
# Cleans: macOS caches, npm cache, Gradle caches, user logs, PM2 logs
#         (local + Raspberry Pis), brew cleanup.

set -eu

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export LC_NUMERIC=C  # Force '.' as decimal separator for printf/bc

CLEANUP_CACHES_VERSION="1.0.0"

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# ----------------------------------------------------------------------------
# Pure helpers (testable, no side effects beyond stdout)
# ----------------------------------------------------------------------------

bytes_to_human() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.1f GB" "$(echo "scale=1; $bytes / 1073741824" | bc)"
    elif (( bytes >= 1048576 )); then
        printf "%.0f MB" "$(echo "scale=0; $bytes / 1048576" | bc)"
    elif (( bytes >= 1024 )); then
        printf "%.0f KB" "$(echo "scale=0; $bytes / 1024" | bc)"
    else
        printf "%d B" "$bytes"
    fi
}

dir_size_bytes() {
    if [ -d "$1" ]; then
        local raw
        raw=$(du -sk "$1" 2>/dev/null) || true
        if [ -n "$raw" ]; then
            echo "$raw" | awk 'END{print $1 * 1024}'
        else
            echo 0
        fi
    else
        echo 0
    fi
}

free_disk_summary() {
    df -h /System/Volumes/Data | awk 'NR==2{print $4 " available (" $5 " used)"}'
}

cleanup_targets() {
    printf '%s\n' \
        "$HOME/Library/Caches:macOS Caches" \
        "$HOME/.npm/_cacache:npm Cache" \
        "$HOME/.gradle/caches:Gradle Caches" \
        "$HOME/Library/Logs:User Logs" \
        "$HOME/.pm2/logs:PM2 Logs"
}

# ----------------------------------------------------------------------------
# Commands
# ----------------------------------------------------------------------------

cmd_sizes() {
    local total=0 entry path label bytes
    echo -e "${BOLD}Cleanup Caches — sizes preview${NC}"
    while IFS= read -r entry; do
        path="${entry%%:*}"
        label="${entry##*:}"
        bytes=$(dir_size_bytes "$path")
        total=$((total + bytes))
        printf "  %-18s %s\n" "$label:" "$(bytes_to_human "$bytes")"
    done < <(cleanup_targets)
    echo "  ─────────────────────────"
    printf "  %-18s %s\n" "Gesamt:" "$(bytes_to_human "$total")"
    echo "  $(free_disk_summary)"
}

cmd_clean() {
    local total_freed=0 entry path label before after freed

    echo -e "${BOLD}Cleaning local caches...${NC}"
    while IFS= read -r entry; do
        path="${entry%%:*}"
        label="${entry##*:}"
        if [ -d "$path" ]; then
            before=$(dir_size_bytes "$path")
            rm -rf "${path:?}"/* 2>/dev/null || true
            after=$(dir_size_bytes "$path")
            freed=$((before - after))
            total_freed=$((total_freed + freed))
            echo -e "  ${GREEN}✓${NC} ${label}: $(bytes_to_human "$freed") freed"
        else
            echo -e "  ${YELLOW}–${NC} ${label}: not found, skipping"
        fi
    done < <(cleanup_targets)

    echo ""
    echo -e "${BOLD}Tool cleanups...${NC}"

    if command -v pm2 &>/dev/null; then
        pm2 flush >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓${NC} Local PM2 logs flushed"
    else
        echo -e "  ${YELLOW}–${NC} PM2 not installed locally, skipping"
    fi

    if command -v npm &>/dev/null; then
        npm cache clean --force >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓${NC} npm cache invalidated"
    fi

    if command -v brew &>/dev/null; then
        local brew_out
        brew_out=$(brew cleanup -s 2>&1 | tail -1)
        echo -e "  ${GREEN}✓${NC} brew cleanup: ${brew_out}"
    fi

    echo ""
    echo -e "${BOLD}Remote PM2 flush...${NC}"

    if ssh -o ConnectTimeout=3 raspi3 'pm2 flush' >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} raspi3 PM2 logs flushed"
    else
        echo -e "  ${YELLOW}–${NC} raspi3 unreachable, skipping"
    fi

    if ssh -o ConnectTimeout=3 raspi2 'sudo pm2 flush' >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} raspi2 PM2 logs flushed (sudo)"
    else
        echo -e "  ${YELLOW}–${NC} raspi2 unreachable, skipping"
    fi

    echo ""
    echo -e "${BOLD}Total freed: $(bytes_to_human "$total_freed")${NC}"
    echo -e "Disk usage: $(free_disk_summary)"
}

cmd_help() {
    cat <<EOF
cleanup-caches v${CLEANUP_CACHES_VERSION}

USAGE
  cleanup-caches.sh [command]

COMMANDS
  (none)           Clean caches and report freed space
  sizes            Show what would be cleaned, without deleting
  version          Print version
  help             Show this help

TARGETS
  ~/Library/Caches      macOS application caches
  ~/.npm/_cacache       npm package cache
  ~/.gradle/caches      Gradle build caches
  ~/Library/Logs        User application logs
  ~/.pm2/logs           PM2 process log files

  + pm2 flush (local + raspi3 + raspi2)
  + npm cache clean --force
  + brew cleanup -s
EOF
}

main() {
    case "${1:-clean}" in
        sizes|--sizes|-s)        cmd_sizes ;;
        version|--version|-v)    echo "cleanup-caches v${CLEANUP_CACHES_VERSION}" ;;
        help|--help|-h)          cmd_help ;;
        clean|*)                 cmd_clean ;;
    esac
}

# Only run main() when executed directly, not when sourced (for tests).
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
