// loc_display — floating HUD result panel for the "LoC Chart" Quick Action.
//
// Usage:
//   loc_display --title "LoC — proj" --total 24512 --files 312 \
//               --lang "JavaScript=6234" --lang "Python=3123" [--rest 420]
//
// Shows a dark-blur panel in the top-right corner with the total line count
// and an animated per-language bar chart (brand colors where known).
// Click anywhere on the panel (or wait 30 s) → it fades out; nothing opens.
// Build: ./build.sh (installs to ~/Library/Services/loc_display).

import AppKit

struct Row {
    let name: String
    let count: Int
    let isRest: Bool
}

var title = "LoC"
var total = 0
var files = 0
var rows: [Row] = []

var it = CommandLine.arguments.dropFirst().makeIterator()
while let a = it.next() {
    switch a {
    case "--title": title = it.next() ?? title
    case "--total": total = Int(it.next() ?? "") ?? 0
    case "--files": files = Int(it.next() ?? "") ?? 0
    case "--lang":
        if let v = it.next() {
            let parts = v.split(separator: "=", maxSplits: 1)
            if parts.count == 2, let c = Int(parts[1]) {
                rows.append(Row(name: String(parts[0]), count: c, isRest: false))
            }
        }
    case "--rest":
        if let v = it.next(), let c = Int(v), c > 0 {
            rows.append(Row(name: "Sonstige", count: c, isRest: true))
        }
    default: break
    }
}

let fmt = NumberFormatter()
fmt.numberStyle = .decimal
fmt.groupingSeparator = "."
fmt.usesGroupingSeparator = true
func fnum(_ n: Int) -> String { fmt.string(from: NSNumber(value: n)) ?? String(n) }

func roundedFont(_ size: CGFloat, _ weight: NSFont.Weight) -> NSFont {
    let f = NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    if let d = f.fontDescriptor.withDesign(.rounded), let rf = NSFont(descriptor: d, size: size) {
        return rf
    }
    return f
}

func hexColor(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: 1)
}

// Brand-ish colors, brightened where the original is too dark for a HUD.
let brandColors: [String: UInt32] = [
    "Python": 0x4B8BBE, "JavaScript": 0xF7DF1E, "TypeScript": 0x3178C6,
    "Swift": 0xF05138, "Shell": 0x89E051, "Go": 0x00ADD8, "Rust": 0xDEA584,
    "Java": 0xE76F00, "Kotlin": 0xA97BFF, "C": 0x9CA3AF, "C++": 0xF34B7D,
    "Obj-C": 0x438EFF, "Ruby": 0xCC342D, "PHP": 0x8993BE, "HTML": 0xE34C26,
    "CSS": 0x9B6BC3, "Vue": 0x41B883, "Svelte": 0xFF3E00, "SQL": 0xE38C00,
    "Dart": 0x00B4AB, "Lua": 0x6A7FE0, "Perl": 0x39457E, "Scala": 0xDC322F,
    "Haskell": 0x8F4E8B, "Elixir": 0x9A6FB8, "Erlang": 0xA90533,
    "Clojure": 0x63B132, "R": 0x276DC3,
]
let fallbackColors: [UInt32] = [0x5AC8FA, 0xBF5AF2, 0x64D2FF, 0xFF9F0A, 0xFF375F, 0x30D158]

func colorFor(_ row: Row, index: Int) -> NSColor {
    if row.isRest { return NSColor.systemGray }
    if let hex = brandColors[row.name] { return hexColor(hex) }
    return hexColor(fallbackColors[index % fallbackColors.count])
}

func label(_ s: String, _ f: NSFont, _ c: NSColor) -> NSTextField {
    let l = NSTextField(labelWithString: s)
    l.font = f
    l.textColor = c
    l.lineBreakMode = .byTruncatingTail
    return l
}

final class ClickCloseView: NSVisualEffectView {
    var onClick: (() -> Void)?
    override func mouseDown(with event: NSEvent) { onClick?() }
}

// ---------------------------------------------------------------------------
// Layout (coordinates measured from the top, converted via yTop)
// ---------------------------------------------------------------------------

let W: CGFloat = 344
let pad: CGFloat = 20
let rowH: CGFloat = 36
let headerH: CGFloat = 74
let hintH: CGFloat = 22
let H: CGFloat = pad + headerH + CGFloat(rows.count) * rowH + hintH + 14

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard let screen = NSScreen.main else { exit(0) }
let vf = screen.visibleFrame
let finalX = vf.maxX - W - 16
let finalY = vf.maxY - H - 16

let panel = NSPanel(contentRect: NSRect(x: finalX + 28, y: finalY, width: W, height: H),
                    styleMask: [.borderless, .nonactivatingPanel],
                    backing: .buffered, defer: false)
panel.level = .statusBar
panel.isOpaque = false
panel.backgroundColor = .clear
panel.hasShadow = true
panel.becomesKeyOnlyIfNeeded = true
panel.isMovableByWindowBackground = true
panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

let fx = ClickCloseView(frame: NSRect(x: 0, y: 0, width: W, height: H))
fx.material = .hudWindow
fx.state = .active
fx.blendingMode = .behindWindow
fx.wantsLayer = true
fx.layer?.cornerRadius = 18
fx.layer?.masksToBounds = true
panel.contentView = fx

func yTop(_ fromTop: CGFloat, _ height: CGFloat) -> CGFloat { H - fromTop - height }

// Header: title, big total, files
let titleLabel = label(title, NSFont.systemFont(ofSize: 13, weight: .semibold),
                       .secondaryLabelColor)
titleLabel.frame = NSRect(x: pad, y: yTop(pad, 16), width: W - 2 * pad, height: 16)
fx.addSubview(titleLabel)

let bigLabel = label(fnum(total), roundedFont(30, .bold), .labelColor)
bigLabel.sizeToFit()
bigLabel.setFrameOrigin(NSPoint(x: pad, y: yTop(pad + 22, 38)))
fx.addSubview(bigLabel)

let caption = label("Zeilen  ·  \(fnum(files)) Dateien",
                    NSFont.systemFont(ofSize: 13, weight: .medium),
                    .secondaryLabelColor)
caption.sizeToFit()
caption.setFrameOrigin(NSPoint(x: bigLabel.frame.maxX + 10,
                               y: bigLabel.frame.minY + 7))
fx.addSubview(caption)

// Bars
let maxCount = max(rows.map(\.count).max() ?? 1, 1)
let trackW = W - 2 * pad
var fills: [(layer: CALayer, target: CGFloat, delay: Double)] = []

for (i, row) in rows.enumerated() {
    let top = pad + headerH + CGFloat(i) * rowH
    let color = colorFor(row, index: i)

    let name = label(row.name, NSFont.systemFont(ofSize: 12, weight: .medium),
                     row.isRest ? .secondaryLabelColor : .labelColor)
    name.frame = NSRect(x: pad, y: yTop(top, 15), width: trackW - 100, height: 15)
    fx.addSubview(name)

    let count = label(fnum(row.count), roundedFont(12, .semibold), .secondaryLabelColor)
    count.alignment = .right
    count.frame = NSRect(x: W - pad - 96, y: yTop(top, 15), width: 96, height: 15)
    fx.addSubview(count)

    let track = NSView(frame: NSRect(x: pad, y: yTop(top + 19, 6), width: trackW, height: 6))
    track.wantsLayer = true
    track.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.12).cgColor
    track.layer?.cornerRadius = 3
    fx.addSubview(track)

    let fill = CALayer()
    fill.frame = CGRect(x: 0, y: 0, width: 0, height: 6)
    fill.cornerRadius = 3
    fill.backgroundColor = color.cgColor
    track.layer?.addSublayer(fill)

    let target = max(6, trackW * CGFloat(row.count) / CGFloat(maxCount))
    fills.append((fill, target, 0.20 + 0.08 * Double(i)))
}

// Hint
let hint = label("Klicken zum Schließen — verschwindet automatisch",
                 NSFont.systemFont(ofSize: 10, weight: .regular),
                 .tertiaryLabelColor)
hint.alignment = .center
hint.frame = NSRect(x: pad, y: 12, width: W - 2 * pad, height: 13)
fx.addSubview(hint)

// ---------------------------------------------------------------------------
// Show, animate, close
// ---------------------------------------------------------------------------

var closing = false
func closePanel() {
    if closing { return }
    closing = true
    NSAnimationContext.runAnimationGroup({ ctx in
        ctx.duration = 0.22
        panel.animator().alphaValue = 0
    }, completionHandler: { NSApp.terminate(nil) })
}
fx.onClick = { closePanel() }

panel.alphaValue = 0
panel.orderFrontRegardless()
NSAnimationContext.runAnimationGroup { ctx in
    ctx.duration = 0.30
    ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
    panel.animator().alphaValue = 1
    panel.animator().setFrame(NSRect(x: finalX, y: finalY, width: W, height: H),
                              display: true)
}

for f in fills {
    DispatchQueue.main.asyncAfter(deadline: .now() + f.delay) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.6)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        f.layer.frame = CGRect(x: 0, y: 0, width: f.target, height: 6)
        CATransaction.commit()
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 30) { closePanel() }

app.run()
