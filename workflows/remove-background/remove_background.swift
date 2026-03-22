import Foundation
import AppKit
import Vision
import CoreImage

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: remove_background <image_path> [image_path ...]\n", stderr)
    exit(1)
}

for path in CommandLine.arguments.dropFirst() {
    let url = URL(fileURLWithPath: path)
    let ext = url.pathExtension.lowercased()

    guard ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "webp", "svg"].contains(ext) else {
        fputs("Skipping unsupported format: \(url.lastPathComponent)\n", stderr)
        continue
    }

    guard let ciImage = CIImage(contentsOf: url) else {
        fputs("Failed to load image: \(url.lastPathComponent)\n", stderr)
        continue
    }

    let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
    let request = VNGenerateForegroundInstanceMaskRequest()

    do {
        try handler.perform([request])
    } catch {
        fputs("Vision request failed for \(url.lastPathComponent): \(error.localizedDescription)\n", stderr)
        continue
    }

    guard let result = request.results?.first else {
        fputs("No foreground detected in: \(url.lastPathComponent)\n", stderr)
        continue
    }

    do {
        let allInstances = result.allInstances
        let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: allInstances, from: handler)

        let maskCIImage = CIImage(cvPixelBuffer: maskPixelBuffer)

        let context = CIContext()
        let filter = CIFilter(name: "CIBlendWithMask")!
        filter.setValue(ciImage, forKey: kCIInputImageKey)
        filter.setValue(CIImage(color: .clear).cropped(to: ciImage.extent), forKey: kCIInputBackgroundImageKey)
        filter.setValue(maskCIImage, forKey: kCIInputMaskImageKey)

        guard let outputCIImage = filter.outputImage else {
            fputs("Failed to apply mask for: \(url.lastPathComponent)\n", stderr)
            continue
        }

        let name = url.deletingPathExtension().lastPathComponent
        let dir = url.deletingLastPathComponent()
        let outputURL = dir.appendingPathComponent("\(name)-free.png")

        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        try context.writePNGRepresentation(of: outputCIImage, to: outputURL, format: .RGBA8, colorSpace: colorSpace)

        print("Created: \(outputURL.lastPathComponent)")
    } catch {
        fputs("Failed to generate mask for \(url.lastPathComponent): \(error.localizedDescription)\n", stderr)
    }
}
