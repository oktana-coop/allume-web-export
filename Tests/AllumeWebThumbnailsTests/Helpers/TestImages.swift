import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

/// An image file of the size, in the format, with an alpha channel. It's opaque unless
/// `transparent`, which leaves its right half clear, and its metadata has the orientation.
func makeImageFile(
  width: Int, height: Int, type: UTType = .png, transparent: Bool = false, orientation: Int = 1
) throws -> URL {
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  let context = try #require(
    CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
  context.fill(CGRect(x: 0, y: 0, width: transparent ? width / 2 : width, height: height))

  let file = FileManager.default.temporaryDirectory.appending(
    path: "ThumbnailsTests-\(UUID()).\(type.preferredFilenameExtension ?? "image")")
  let destination = try #require(
    CGImageDestinationCreateWithURL(file as CFURL, type.identifier as CFString, 1, nil))
  CGImageDestinationAddImage(
    destination, try #require(context.makeImage()),
    [kCGImagePropertyOrientation: orientation] as CFDictionary)
  #expect(CGImageDestinationFinalize(destination))

  return file
}

/// The width and height of the encoded image.
func pixelSize(of data: Data) throws -> (width: Int, height: Int) {
  let source = try #require(CGImageSourceCreateWithData(data as CFData, nil))
  let properties = try #require(
    CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])

  return (
    try #require(properties[kCGImagePropertyPixelWidth] as? Int),
    try #require(properties[kCGImagePropertyPixelHeight] as? Int)
  )
}
