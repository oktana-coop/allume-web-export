import AllumeWebModels
import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import AllumeWeb

@Suite struct ImageFilesTests {
  @Test func makeACopyBrowsersCanShowAndAThumbnailApart() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let photo = try makeImageFile(named: "photo.heic", width: 1000, height: 500, in: folder)
    let contents = try makeContents(with: [makeImage("photo", file: photo)])

    let files = makeImageFiles(of: contents, in: folder.appending(path: "made"))

    let made = try #require(files["photo.heic"])
    let thumbnail = try #require(made.thumbnail)
    #expect(made.image.name == "photo.jpg" && thumbnail.name == "photo.jpg")
    #expect(made.image.url != thumbnail.url)
    #expect(
      [made.image.url, thumbnail.url].allSatisfy { url in
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
      })
  }

  @Test func leaveOutAnImageThatNeedsNeither() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let icon = try makeImageFile(named: "icon.png", width: 100, height: 50, in: folder)
    let contents = try makeContents(with: [makeImage("icon", file: icon)])

    let files = makeImageFiles(of: contents, in: folder.appending(path: "made"))

    #expect(files.isEmpty)
  }
}

private func makeTemporaryFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "ImageFilesTests-\(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}

private func makeImage(_ id: String, file: URL) -> Document {
  .image(
    Document.Image(
      id: Document.ID(rawValue: id), label: nil,
      file: Asset(name: file.lastPathComponent, url: file), excerpt: nil))
}

/// An opaque image file of the size, in the format its name's extension gives.
private func makeImageFile(named name: String, width: Int, height: Int, in folder: URL) throws
  -> URL
{
  let type = try #require(UTType(filenameExtension: (name as NSString).pathExtension))
  let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
  let context = try #require(
    CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
  context.setFillColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1)
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))

  let file = folder.appending(path: name)
  let destination = try #require(
    CGImageDestinationCreateWithURL(file as CFURL, type.identifier as CFString, 1, nil))
  CGImageDestinationAddImage(destination, try #require(context.makeImage()), nil)
  #expect(CGImageDestinationFinalize(destination))

  return file
}
