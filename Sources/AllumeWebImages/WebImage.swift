import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// An image in a format every browser shows.
package struct WebImage: Equatable, Sendable {
  package let data: Data
  package let format: Format

  package enum Format: Equatable, Sendable {
    case jpeg
    /// For an image with transparent pixels, which JPEG can't keep.
    case png

    /// E.g. `jpg`.
    package var fileExtension: String {
      switch self {
      case .jpeg: "jpg"
      case .png: "png"
      }
    }
  }
}

/// The image drawn the way it's shown, after the rotation its orientation asks for, with its
/// longer side at most the given length.
func drawnImage(from source: CGImageSource, longerSide: Int) -> CGImage? {
  CGImageSourceCreateThumbnailAtIndex(
    source, 0,
    [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: longerSide,
    ] as CFDictionary)
}

/// The image's width and height as shown, after the rotation its orientation asks for.
func displayedSize(of source: CGImageSource) -> (width: Int, height: Int)? {
  guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
    let width = properties[kCGImagePropertyPixelWidth] as? Int,
    let height = properties[kCGImagePropertyPixelHeight] as? Int
  else {
    return nil
  }

  // Orientations 5 to 8 turn the image a quarter turn.
  let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
  return (5...8).contains(orientation) ? (height, width) : (width, height)
}

/// The image as JPEG, or as PNG when any of its pixels is transparent.
package func encoded(_ image: CGImage) -> WebImage? {
  let format: WebImage.Format = hasTransparentPixel(image) ? .png : .jpeg
  return encoded(image, as: format).map { data in WebImage(data: data, format: format) }
}

/// Whether any pixel isn't fully opaque. Many images, screenshots especially, have an alpha
/// channel without using it.
private func hasTransparentPixel(_ image: CGImage) -> Bool {
  guard ![.none, .noneSkipFirst, .noneSkipLast].contains(image.alphaInfo) else {
    return false
  }

  let bytesPerRow = image.width * 4
  var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)
  let drawn = pixels.withUnsafeMutableBytes { buffer in
    CGContext(
      data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
      bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ).map { context in
      context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    } != nil
  }
  return drawn && stride(from: 3, to: pixels.count, by: 4).contains { index in pixels[index] < 255 }
}

/// Measured on real boards' screenshots, 0.9 makes images only about a seventh bigger than 0.8.
private let jpegQuality = 0.9

private func encoded(_ image: CGImage, as format: WebImage.Format) -> Data? {
  let type: UTType =
    switch format {
    case .jpeg: .jpeg
    case .png: .png
    }
  let data = NSMutableData()
  guard
    let destination = CGImageDestinationCreateWithData(data, type.identifier as CFString, 1, nil)
  else {
    return nil
  }

  let options: [CFString: Any] =
    format == .jpeg ? [kCGImageDestinationLossyCompressionQuality: jpegQuality] : [:]
  CGImageDestinationAddImage(destination, image, options as CFDictionary)
  return CGImageDestinationFinalize(destination) ? data as Data : nil
}
