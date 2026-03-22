#!/bin/bash
# cleanup-caches.sh — Free disk space by clearing caches and PM2 logs
# Cleans: macOS caches, npm cache, Gradle caches, PM2 logs (local + Raspis)

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

bytes_to_human() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        printf "%.1f GB" "$(echo "scale=1; $bytes / 1073741824" | bc)"
    elif (( bytes >= 1048576 )); then
        printf "%.0f MB" "$(echo "scale=0; $bytes / 1048576" | bc)"
    else
        printf "%.0f KB" "$(echo "scale=0; $bytes / 1024" | bc)"
    fi
}

dir_size_bytes() {
    if [ -d "$1" ]; then
        du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
    else
        echo 0
    fi
}

total_freed=0

clean_dir() {
    local path="$1"
    local label="$2"
    if [ -d "$path" ]; then
        local before
        before=$(dir_size_bytes "$path")
        rm -rf "${path:?}"/* 2>/dev/null
        local after
        after=$(dir_size_bytes "$path")
        local freed=$((before - after))
        total_freed=$((total_freed + freed))
        echo -e "  ${GREEN}✓${NC} ${label}: $(bytes_to_human $freed) freed"
    else
        echo -e "  ${YELLOW}–${NC} ${label}: not found, skipping"
    fi
}

echo -e "${BOLD}Cleaning local caches...${NC}"
clean_dir "$HOME/Library/Caches" "macOS Caches"
clean_dir "$HOME/.npm/_cacache" "npm Cache"
clean_dir "$HOME/.gradle/caches" "Gradle Caches"

echo ""
echo -e "${BOLD}Flushing PM2 logs...${NC}"

if command -v pm2 &>/dev/null; then
    pm2 flush >/dev/null 2>&1
    echo -e "  ${GREEN}✓${NC} Local PM2 logs flushed"
else
    echo -e "  ${YELLOW}–${NC} PM2 not installed locally, skipping"
fi

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
echo -e "${BOLD}Total freed: $(bytes_to_human $total_freed)${NC}"
echo -e "Disk usage: $(df -h /System/Volumes/Data | awk 'NR==2{print $4 " available (" $5 " used)"}')"
