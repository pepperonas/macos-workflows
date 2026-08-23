#!/bin/bash
cd "$(dirname "$0")"
swiftc -O -o loc_display loc_display.swift -framework AppKit
cp loc_display "$HOME/Library/Services/loc_display"
echo "Built and installed: ~/Library/Services/loc_display"
