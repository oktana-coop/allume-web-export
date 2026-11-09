import Foundation
import Testing
import UniformTypeIdentifiers

@testable import AllumeWebImages

@Suite struct WebCopiesTests {
  @Test func makeAHEICImageAJPEGAtItsFullSize() throws {
    let image = try makeImageFile(width: 1000, height: 500, type: .heic)
    defer { try? FileManager.default.removeItem(at: image) }

    let copy = try #require(webCopy(of: image))

    #expect(copy.format == .jpeg)
    #expect(copy.data.starts(with: [0xFF, 0xD8]))
    let size = try pixelSize(of: copy.data)
    #expect(size.width == 1000 && size.height == 500)
  }

  @Test func makeAPNGWhenAPixelIsTransparent() throws {
    let image = try makeImageFile(width: 1000, height: 500, type: .heic, transparent: true)
    defer { try? FileManager.default.removeItem(at: image) }

    let copy = try #require(webCopy(of: image))

    #expect(copy.format == .png)
  }

  @Test func followTheImagesOrientation() throws {
    // Turned a quarter turn, the image is 500 wide and 1000 high as shown.
    let image = try makeImageFile(width: 1000, height: 500, type: .heic, orientation: 6)
    defer { try? FileManager.default.removeItem(at: image) }

    let copy = try #require(webCopy(of: image))

    let size = try pixelSize(of: copy.data)
    #expect(size.width == 500 && size.height == 1000)
  }

  @Test(arguments: [UTType.png, .jpeg, .gif])
  func leaveAnImageBrowsersShowAlone(type: UTType) throws {
    let image = try makeImageFile(width: 1000, height: 500, type: type)
    defer { try? FileManager.default.removeItem(at: image) }

    #expect(webCopy(of: image) == nil)
  }

  @Test func readNothingFromAFileThatIsntAnImage() throws {
    let file = FileManager.default.temporaryDirectory.appending(
      path: "WebCopiesTests-\(UUID()).heic")
    try Data("not an image".utf8).write(to: file)
    defer { try? FileManager.default.removeItem(at: file) }

    #expect(webCopy(of: file) == nil)
  }
}
