import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

/// A square image of one color in the format, with a frame for each size, and the metadata.
func makeImage(sizes: [Int], type: UTType, metadata: [CFString: Any] = [:]) throws -> Data {
  let data = NSMutableData()
  let destination = try #require(
    CGImageDestinationCreateWithData(data, type.identifier as CFString, sizes.count, nil))
  for size in sizes {
    CGImageDestinationAddImage(destination, try makeSquare(size: size), metadata as CFDictionary)
  }
  #expect(CGImageDestinationFinalize(destination))

  return data as Data
}

/// The width and height of the image's first frame, and its GPS data, if any.
func properties(of image: Data) throws -> (width: Int, height: Int, gps: [CFString: Any]?) {
  let source = try #require(CGImageSourceCreateWithData(image as CFData, nil))
  let properties = try #require(
    CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])

  return (
    try #require(properties[kCGImagePropertyPixelWidth] as? Int),
    try #require(properties[kCGImagePropertyPixelHeight] as? Int),
    properties[kCGImagePropertyGPSDictionary] as? [CFString: Any]
  )
}

private func makeSquare(size: Int) throws -> CGImage {
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  let context = try #require(
    CGContext(
      data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
  context.fill(CGRect(x: 0, y: 0, width: size, height: size))

  return try #require(context.makeImage())
}
