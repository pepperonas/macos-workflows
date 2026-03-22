#!/bin/bash
# Build the remove_background tool and install to ~/Library/Services/
cd "$(dirname "$0")"
swiftc -O -o remove_background remove_background.swift \
    -framework AppKit -framework Vision -framework CoreImage
cp remove_background "$HOME/Library/Services/remove_background"
echo "Built and installed: ~/Library/Services/remove_background"
