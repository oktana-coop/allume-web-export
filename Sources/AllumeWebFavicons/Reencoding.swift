import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A PNG of our own, at most 128 px, drawn from an untrusted icon, so that only its pixels cross
/// over: no scripts, metadata, color profiles, animation or bytes hidden after the image. Nil
/// unless it's a PNG, ICO, JPEG or GIF with a frame of at most 1,024 px.
func reencodedIcon(_ data: Data) -> Data? {
  guard hasAcceptedSignature(data),
    let source = CGImageSourceCreateWithData(
      data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
    let type = CGImageSourceGetType(source), acceptedTypes.contains(type as String),
    let index = bestFrame(in: source),
    let decoded = CGImageSourceCreateThumbnailAtIndex(
      source, index,
      [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: maxIconSize,
        kCGImageSourceCreateThumbnailWithTransform: true,
      ] as CFDictionary),
    let redrawn = redrawn(decoded)
  else {
    return nil
  }

  return png(of: redrawn)
}

/// 16 px icons, at 4 times zoom on screens with 2 pixels to the point.
private let maxIconSize = 128

/// Frames larger than this are refused from their header, before any decoding.
private let maxFrameSize = 1024

private let acceptedTypes = Set([UTType.png, .ico, .jpeg, .gif].map(\.identifier))

/// Our own check, before ImageIO looks at the data. SVG, WebP and everything else are refused.
private func hasAcceptedSignature(_ data: Data) -> Bool {
  let signatures: [[UInt8]] = [
    [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],  // PNG
    [0x00, 0x00, 0x01, 0x00],  // ICO
    [0xFF, 0xD8, 0xFF],  // JPEG
    [0x47, 0x49, 0x46, 0x38],  // GIF
  ]
  return signatures.contains { signature in data.starts(with: signature) }
}

/// Of the first 16 frames, by the sizes in their headers: the smallest of at least 128 px, else the
/// largest. An ICO holds several sizes, and a GIF's first frame is taken.
private func bestFrame(in source: CGImageSource) -> Int? {
  let frames = (0..<min(CGImageSourceGetCount(source), 16)).compactMap {
    index -> (index: Int, size: Int)? in
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
      let width = properties[kCGImagePropertyPixelWidth] as? Int,
      let height = properties[kCGImagePropertyPixelHeight] as? Int,
      width > 0, height > 0, max(width, height) <= maxFrameSize
    else {
      return nil
    }
    return (index, max(width, height))
  }
  let bigEnough = frames.filter { frame in frame.size >= maxIconSize }

  return (bigEnough.min { a, b in a.size < b.size } ?? frames.max { a, b in a.size < b.size })?
    .index
}

/// The image drawn into a new 8-bit sRGB bitmap with transparency.
private func redrawn(_ image: CGImage) -> CGImage? {
  guard image.width <= maxIconSize, image.height <= maxIconSize,
    let space = CGColorSpace(name: CGColorSpace.sRGB),
    let context = CGContext(
      data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: 0,
      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
  else {
    return nil
  }

  context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
  return context.makeImage()
}

/// Encoded with no properties, so with no metadata.
private func png(of image: CGImage) -> Data? {
  let data = NSMutableData()
  guard
    let destination = CGImageDestinationCreateWithData(
      data, UTType.png.identifier as CFString, 1, nil)
  else {
    return nil
  }

  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination) ? data as Data : nil
}
