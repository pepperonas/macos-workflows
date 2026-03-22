import Foundation
import CoreImage
import AppKit

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: qr_code <file_path> [file_path ...]\n", stderr)
    exit(1)
}

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)

    // Read file contents if small text file, otherwise use file path
    var content: String
    if let text = try? String(contentsOf: url, encoding: .utf8), text.count < 2000 {
        content = text.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        content = path
    }

    guard let data = content.data(using: .utf8) else {
        fputs("Failed to encode content for: \(url.lastPathComponent)\n", stderr)
        continue
    }

    guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
        fputs("CIQRCodeGenerator not available\n", stderr)
        exit(1)
    }

    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("H", forKey: "inputCorrectionLevel")

    guard let ciImage = filter.outputImage else {
        fputs("Failed to generate QR code for: \(url.lastPathComponent)\n", stderr)
        continue
    }

    let scale: CGFloat = 10.0
    let transform = CGAffineTransform(scaleX: scale, y: scale)
    let scaledImage = ciImage.transformed(by: transform)

    let context = CIContext()
    let name = url.deletingPathExtension().lastPathComponent
    let dir = url.deletingLastPathComponent()
    let outputURL = dir.appendingPathComponent("\(name)-qr.png")

    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    do {
        try context.writePNGRepresentation(of: scaledImage, to: outputURL, format: .RGBA8, colorSpace: colorSpace)
        print("Created: \(outputURL.lastPathComponent)")
    } catch {
        fputs("Failed to write QR code: \(error.localizedDescription)\n", stderr)
    }
}
