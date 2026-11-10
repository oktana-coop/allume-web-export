import AllumeWebImages
import AllumeWebModels
import AllumeWebRendering
import CoreGraphics
import Foundation
import ImageIO
import Testing

@testable import AllumeWeb

@Suite struct PreviewImagesTests {
  @Test func drawTheBoardsPreviewInLightAndDark() async throws {
    let contents = try makeContents(with: [makeLink("link", url: "https://ocaml.org")])
    let boards = renderedBoards(for: contents, favicons: [:], images: [:], previews: [:])

    let images = try #require(
      await previewImages(of: boards.preview, index: boards.index, width: rootPreviewWidth))

    let (light, dark) = (try decoded(images.light), try decoded(images.dark))
    #expect(light.width == 1600 && dark.width == 1600)
    #expect(light.height == dark.height)
    #expect(try brightness(of: light) > brightness(of: dark))
  }

  @Test func drawNothingForAnEmptyBoard() async throws {
    let contents = try makeContents(with: [])
    let boards = renderedBoards(for: contents, favicons: [:], images: [:], previews: [:])

    let images = await previewImages(
      of: boards.preview, index: boards.index, width: rootPreviewWidth)

    #expect(images == nil)
  }

  @Test func drawEachBoardCardsPreviewIntoFilesNamedAfterItsBoard() async throws {
    let contents = try makeContents(with: [
      makeBoard("child", label: "Functional", cards: ["link"]),
      makeLink("link", url: "https://ocaml.org"),
    ])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, warnings) = await makePreviewImageFiles(
      of: renderBoardPreviews(contents, favicons: [:], images: [:]),
      index: boardsIndex(for: contents), width: 300, in: folder)

    let preview = CardPreview(boardID: Document.ID(rawValue: "child"), color: nil)
    let drawn = try #require(files[preview])
    #expect(Array(files.keys) == [preview])
    #expect(warnings.isEmpty)
    #expect([drawn.light.name, drawn.dark.name] == ["child-light.jpg", "child-dark.jpg"])
    let (light, dark) = (try decoded(file: drawn.light.url), try decoded(file: drawn.dark.url))
    #expect(light.width == 300 && dark.width == 300)
    #expect(try brightness(of: light) > brightness(of: dark))
  }

  @Test func drawABoardOnColoredCardsInTheirColor() async throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "child"),
                frame: Rect(x: 0, y: 0, width: 100, height: 100), zIndex: 0, color: .purple)
            ], chains: [], connections: [], ink: [])),
        makeBoard("child", label: "Functional", cards: ["link"]),
        makeLink("link", url: "https://ocaml.org"),
      ],
      users: [:])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, _) = await makePreviewImageFiles(
      of: renderBoardPreviews(contents, favicons: [:], images: [:]),
      index: boardsIndex(for: contents), width: 300, in: folder)

    let preview = CardPreview(boardID: Document.ID(rawValue: "child"), color: .purple)
    #expect(files[preview]?.light.name == "child-purple-light.jpg")
  }

  @Test func drawNoneForAnEmptyBoardWithoutAWarning() async throws {
    let contents = try makeContents(with: [makeBoard("child", label: "Functional")])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, warnings) = await makePreviewImageFiles(
      of: renderBoardPreviews(contents, favicons: [:], images: [:]),
      index: boardsIndex(for: contents), width: 300, in: folder)

    #expect(files.isEmpty)
    #expect(warnings.isEmpty)
  }
}

private func decoded(file: URL) throws -> CGImage {
  let source = try #require(CGImageSourceCreateWithURL(file as CFURL, nil))
  return try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
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
