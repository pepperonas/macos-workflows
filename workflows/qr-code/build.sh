#!/bin/bash
cd "$(dirname "$0")"
swiftc -O -o qr_code qr_code.swift -framework AppKit -framework CoreImage
cp qr_code "$HOME/Library/Services/qr_code"
echo "Built and installed: ~/Library/Services/qr_code"
