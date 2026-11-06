import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import AllumeWebFavicons

@Suite struct ReencodingTests {
  @Test func shrinksALargeIconTo128Pixels() throws {
    let icon = try makeImage(sizes: [256], type: .png)

    let png = try #require(reencodedIcon(icon))

    #expect(png.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    #expect(try properties(of: png).width == 128)
  }

  @Test func neverEnlargesASmallIcon() throws {
    let icon = try makeImage(sizes: [32], type: .png)

    let png = try #require(reencodedIcon(icon))

    #expect(try properties(of: png).width == 32)
  }

  @Test(arguments: [UTType.ico, .jpeg, .gif])
  func turnsTheOtherFormatsIntoPNG(type: UTType) throws {
    let icon = try makeImage(sizes: [64], type: type)

    let png = try #require(reencodedIcon(icon))

    #expect(png.starts(with: [0x89, 0x50, 0x4E, 0x47]))
  }

  @Test func takesTheSmallestFrameOfAtLeast128Pixels() throws {
    let icon = try makeImage(sizes: [16, 256, 32, 128], type: .ico)

    let png = try #require(reencodedIcon(icon))

    #expect(try properties(of: png).width == 128)
  }

  @Test func refusesSVGWebPAndAnythingElse() throws {
    let svg = Data(#"<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>"#.utf8)
    let webP = Data("RIFF\u{0}\u{0}\u{0}\u{0}WEBPVP8 ".utf8)
    let html = Data("<!doctype html><html><script>alert(1)</script></html>".utf8)

    let pngs = [svg, webP, html].map(reencodedIcon)

    #expect(pngs.allSatisfy { png in png == nil })
  }

  @Test func refusesFramesLargerThan1024Pixels() throws {
    let icon = try makeImage(sizes: [2048], type: .png)

    let png = reencodedIcon(icon)

    #expect(png == nil)
  }

  @Test func keepsNothingButThePixels() throws {
    let metadata: [CFString: Any] = [
      kCGImagePropertyExifDictionary: [kCGImagePropertyExifUserComment: "Taken at home"],
      kCGImagePropertyGPSDictionary: [
        kCGImagePropertyGPSLatitude: 37.98, kCGImagePropertyGPSLatitudeRef: "N",
      ],
    ]
    let icon = try makeImage(sizes: [64], type: .jpeg, metadata: metadata)
    let iconWithScript = icon + Data("<script>alert(1)</script>".utf8)
    #expect(try properties(of: icon).gps != nil)
    #expect(icon.firstRange(of: Data("Taken at home".utf8)) != nil)

    let png = try #require(reencodedIcon(iconWithScript))

    #expect(png.firstRange(of: Data("<script>".utf8)) == nil)
    #expect(png.firstRange(of: Data("Taken at home".utf8)) == nil)
    #expect(try properties(of: png).gps == nil)
  }
}
