import AllumeWebImages
import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import AllumeWeb

@Suite struct PreviewImagesTests {
  @Test func drawTheBoardsPreviewInLightAndDark() async throws {
    let contents = try makeContents(with: [makeLink("link", url: "https://ocaml.org")])
    let boards = renderedBoards(for: contents, favicons: [:], images: [:])

    let images = try #require(await previewImages(of: boards.preview, index: boards.index))

    let (light, dark) = (try decoded(images.light), try decoded(images.dark))
    #expect(light.width == 1600 && dark.width == 1600)
    #expect(light.height == dark.height)
    #expect(try brightness(of: light) > brightness(of: dark))
  }

  @Test func drawNothingForAnEmptyBoard() async throws {
    let contents = try makeContents(with: [])
    let boards = renderedBoards(for: contents, favicons: [:], images: [:])

    let images = await previewImages(of: boards.preview, index: boards.index)

    #expect(images == nil)
  }
}

private func decoded(_ image: WebImage) throws -> CGImage {
  let source = try #require(CGImageSourceCreateWithData(image.data as CFData, nil))
  return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
}

/// About how bright the whole image is, from 0 to 1: drawn into a single pixel, which averages it.
private func brightness(of image: CGImage) throws -> Double {
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  var pixel = [UInt8](repeating: 0, count: 4)
  let drawn = pixel.withUnsafeMutableBytes { buffer -> Bool in
    guard
      let context = CGContext(
        data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else {
      return false
    }

    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return true
  }
  try #require(drawn)

  return Double(Int(pixel[0]) + Int(pixel[1]) + Int(pixel[2])) / 3 / 255
}
