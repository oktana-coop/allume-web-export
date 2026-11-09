import AllumeWebImages
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import AllumeWebSnapshots

@Suite @MainActor struct SnapshotTests {
  @Test func drawThePageAtTheWidthKeepingItsProportions() async throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let page = try write(page: "<body style=\"margin: 0\">A page</body>", in: folder)

    let image = try #require(
      await snapshot(
        of: page, size: CGSize(width: 400, height: 200), appearance: .light, width: 600))

    let size = try pixelSize(of: image)
    #expect(size.width == 600 && size.height == 300)
    #expect(image.format == .jpeg)
  }

  @Test func followTheSystemsAppearanceWhereThePageDoes() async throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let page = try write(
      page: """
        <style>
          :root { color-scheme: light dark; }
          body { margin: 0; background: light-dark(white, black); }
        </style>
        """, in: folder)

    let light = try #require(
      await snapshot(
        of: page, size: CGSize(width: 100, height: 100), appearance: .light, width: 100))
    let dark = try #require(
      await snapshot(
        of: page, size: CGSize(width: 100, height: 100), appearance: .dark, width: 100))

    #expect(try brightness(atCenterOf: light) > 0.9)
    #expect(try brightness(atCenterOf: dark) < 0.1)
  }

  @Test func waitForLazyImagesToLoad() async throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    try makeBlackImage().write(to: folder.appending(path: "black.png"))
    let page = try write(
      page: """
        <body style="margin: 0">
          <img src="black.png" loading="lazy" style="display: block; width: 100px; height: 100px">
        </body>
        """, in: folder)

    let image = try #require(
      await snapshot(
        of: page, size: CGSize(width: 100, height: 100), appearance: .light, width: 100))

    #expect(try brightness(atCenterOf: image) < 0.1)
  }

  @Test func runNoneOfThePagesScripts() async throws {
    let folder = try makeFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let page = try write(
      page: """
        <body style="margin: 0; background: white">
          <script>document.body.style.background = 'black';</script>
        </body>
        """, in: folder)

    let image = try #require(
      await snapshot(
        of: page, size: CGSize(width: 100, height: 100), appearance: .light, width: 100))

    #expect(try brightness(atCenterOf: image) > 0.9)
  }

  @Test func drawNothingWithoutAPage() async throws {
    let missing = FileManager.default.temporaryDirectory.appending(
      path: "SnapshotTests-\(UUID())/page.html")

    let image = await snapshot(
      of: missing, size: CGSize(width: 100, height: 100), appearance: .light, width: 100)

    #expect(image == nil)
  }
}

private func makeFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "SnapshotTests-\(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}

private func write(page html: String, in folder: URL) throws -> URL {
  let page = folder.appending(path: "page.html")
  try Data("<!doctype html>\n<meta charset=\"utf-8\">\n\(html)\n".utf8).write(to: page)
  return page
}

/// A black PNG, 10 px square.
private func makeBlackImage() throws -> Data {
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  let context = try #require(
    CGContext(
      data: nil, width: 10, height: 10, bitsPerComponent: 8, bytesPerRow: 0, space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  context.setFillColor(red: 0, green: 0, blue: 0, alpha: 1)
  context.fill(CGRect(x: 0, y: 0, width: 10, height: 10))

  let data = NSMutableData()
  let destination = try #require(
    CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil))
  CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
  #expect(CGImageDestinationFinalize(destination))
  return data as Data
}

private func decoded(_ image: WebImage) throws -> CGImage {
  let source = try #require(CGImageSourceCreateWithData(image.data as CFData, nil))
  return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
}

private func pixelSize(of image: WebImage) throws -> (width: Int, height: Int) {
  let decoded = try decoded(image)
  return (decoded.width, decoded.height)
}

/// The average of the red, green and blue of the image's center pixel, from 0 to 1.
private func brightness(atCenterOf image: WebImage) throws -> Double {
  let decoded = try decoded(image)
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  var pixel = [UInt8](repeating: 0, count: 4)
  let drawn = pixel.withUnsafeMutableBytes { buffer in
    CGContext(
      data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
      space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ).map { context in
      context.draw(
        decoded,
        in: CGRect(
          x: -decoded.width / 2, y: -decoded.height / 2, width: decoded.width,
          height: decoded.height))
    } != nil
  }
  try #require(drawn)

  return Double(Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])) / 3 / 255
}
