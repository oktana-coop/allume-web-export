import Foundation
import Testing

@testable import AllumeWebThumbnails

@Suite struct ThumbnailsTests {
  @Test func scaleAnImageToTheWidthKeepingItsAspectRatio() throws {
    let image = try makeImageFile(width: 1000, height: 500)
    defer { try? FileManager.default.removeItem(at: image) }

    let scaled = try #require(thumbnail(of: image, width: 256))

    let size = try pixelSize(of: scaled.data)
    #expect(size.width == 256 && size.height == 128)
  }

  @Test(arguments: [100, 256])
  func leaveAnImageNoWiderThanTheWidthAlone(width: Int) throws {
    let image = try makeImageFile(width: width, height: 50)
    defer { try? FileManager.default.removeItem(at: image) }

    #expect(thumbnail(of: image, width: 256) == nil)
  }

  @Test func makeJPEGWhenNoPixelIsTransparent() throws {
    // Its alpha channel goes unused, as in many screenshots.
    let image = try makeImageFile(width: 1000, height: 500)
    defer { try? FileManager.default.removeItem(at: image) }

    let scaled = try #require(thumbnail(of: image, width: 256))

    #expect(scaled.format == .jpeg)
    #expect(scaled.data.starts(with: [0xFF, 0xD8]))
  }

  @Test func makePNGWhenAPixelIsTransparent() throws {
    let image = try makeImageFile(width: 1000, height: 500, transparent: true)
    defer { try? FileManager.default.removeItem(at: image) }

    let scaled = try #require(thumbnail(of: image, width: 256))

    #expect(scaled.format == .png)
    #expect(scaled.data.starts(with: [0x89, 0x50, 0x4E, 0x47]))
  }

  @Test func followTheImagesOrientation() throws {
    // Turned a quarter turn, the image is 500 wide and 1000 high as shown.
    let image = try makeImageFile(width: 1000, height: 500, type: .jpeg, orientation: 6)
    defer { try? FileManager.default.removeItem(at: image) }

    let scaled = try #require(thumbnail(of: image, width: 256))

    let size = try pixelSize(of: scaled.data)
    #expect(size.width == 256 && size.height == 512)
  }

  @Test func readNothingFromAFileThatIsntAnImage() throws {
    let file = FileManager.default.temporaryDirectory.appending(
      path: "ThumbnailsTests-\(UUID()).png")
    try Data("not an image".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    #expect(thumbnail(of: file, width: 256) == nil)
  }
}
