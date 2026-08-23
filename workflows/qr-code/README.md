# QR Code

Finder Quick Action: right-click file(s) → **QR Code** → a QR code PNG is
generated next to each file. Text files encode their *contents*, anything
else encodes the file *path*.

- Output: `<name>-qr.png` next to the original
- A notification confirms how many codes were created

## Build (required once)

This workflow calls a compiled Swift binary (Core Image `CIQRCodeGenerator`
under the hood — no third-party QR library):

```bash
cd workflows/qr-code && ./build.sh
```

`build.sh` compiles `qr_code.swift` and installs the binary to
`~/Library/Services/qr_code`, where the workflow expects it. If the binary
is missing, the Quick Action shows a notification asking you to run
`build.sh` instead of failing silently.

The compiled binary is git-ignored; only the `.swift` source is tracked.

## Requirements

Xcode Command Line Tools (`xcode-select --install`) for the one-time build.

## Install

```bash
./build.sh
open "QR Code.workflow"   # ⚠️ moves the bundle into ~/Library/Services —
                          # commit first, restore with git checkout
```
