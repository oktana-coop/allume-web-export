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

    let (files, warnings) = await drawnPreviews(of: contents, width: 300, in: folder)

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

    let (files, _) = await drawnPreviews(of: contents, width: 300, in: folder)

    let preview = CardPreview(boardID: Document.ID(rawValue: "child"), color: .purple)
    #expect(files[preview]?.light.name == "child-purple-light.jpg")
  }

  @Test func drawCardsPreviewsOfAnySizeWithoutScrollbars() async throws {
    // 245 by 163 at 0.8 is 306.25 by 203.75 of the board, a size in fractions of a pixel.
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "child"),
                frame: Rect(x: 0, y: 0, width: 245, height: 163), zIndex: 0, color: nil)
            ], chains: [], connections: [], ink: [])),
        makeBoard("child", label: "Functional", cards: ["link"]),
        makeLink("link", url: "https://ocaml.org"),
      ],
      users: [:])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, _) = await drawnPreviews(of: contents, width: 300, in: folder)

    let preview = CardPreview(boardID: Document.ID(rawValue: "child"), color: nil)
    let image = try decoded(file: try #require(files[preview]).light.url)
    // The link is at the top left, so the panel is empty on the right and at the bottom.
    let panel = try color(at: (image.width * 7 / 10, image.height / 2), in: image)
    #expect(try color(at: (image.width - 2, image.height / 2), in: image).isClose(to: panel))
    #expect(try color(at: (image.width * 7 / 10, image.height - 2), in: image).isClose(to: panel))
  }

  @Test func showTheImagesOfABoardsCardsInItsImage() async throws {
    // The child's card shows a window 1440 by 360 of it, in which its card for the grandchild is
    // at 100, 132 with the room for titles, 600 by 200. The grandchild is a purple note.
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "child"),
                frame: Rect(x: 0, y: 0, width: 360, height: 90), zIndex: 0, color: nil)
            ], chains: [], connections: [], ink: [])),
        .board(
          Document.Board(
            id: Document.ID(rawValue: "child"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "grandchild"),
                frame: Rect(x: 100, y: 100, width: 600, height: 200), zIndex: 0, color: nil)
            ], chains: [], connections: [], ink: [])),
        .board(
          Document.Board(
            id: Document.ID(rawValue: "grandchild"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "note"),
                frame: Rect(x: 0, y: 0, width: 1440, height: 1000), zIndex: 0, color: .purple)
            ], chains: [], connections: [], ink: [])),
        .note(Document.Note(id: Document.ID(rawValue: "note"), label: nil, text: "")),
      ],
      users: [:])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, _) = await drawnPreviews(of: contents, width: 1440, in: folder)

    let child = try decoded(file: try #require(files[cardPreview("child")]).light.url)
    // The middle of the grandchild's card, purple rather than an empty panel's gray.
    let color = try color(at: (x: 400, y: 232), in: child)
    #expect(color[2] - color[1] >= 15)
  }

  @Test func showTheDarkImagesOfABoardsCardsInItsDarkImage() async throws {
    // The child's card shows a window 1440 by 360 of it, in which its card for the grandchild is
    // at 100, 132 with the room for titles, 600 by 200.
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "child"),
                frame: Rect(x: 0, y: 0, width: 360, height: 90), zIndex: 0, color: nil)
            ], chains: [], connections: [], ink: [])),
        .board(
          Document.Board(
            id: Document.ID(rawValue: "child"), label: nil,
            cards: [
              Card(
                documentID: Document.ID(rawValue: "grandchild"),
                frame: Rect(x: 100, y: 100, width: 600, height: 200), zIndex: 0, color: nil)
            ], chains: [], connections: [], ink: [])),
        makeBoard("grandchild", label: "Functional", cards: ["link"]),
        makeLink("link", url: "https://ocaml.org"),
      ],
      users: [:])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, _) = await drawnPreviews(of: contents, width: 1440, in: folder)

    let child = try #require(files[cardPreview("child")])
    let (light, dark) = (try decoded(file: child.light.url), try decoded(file: child.dark.url))
    // The middle of the grandchild's card, an empty part of its board.
    let point = (x: 400, y: 232)
    #expect(try brightness(of: color(at: point, in: dark)) < 0.3)
    #expect(try brightness(of: color(at: point, in: light)) > 0.7)
  }

  @Test func drawNoneForAnEmptyBoardWithoutAWarning() async throws {
    let contents = try makeContents(with: [makeBoard("child", label: "Functional")])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Previews \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (files, warnings) = await drawnPreviews(of: contents, width: 300, in: folder)

    #expect(files.isEmpty)
    #expect(warnings.isEmpty)
  }
}

/// The contents' board cards' previews, drawn as publishing draws them.
private func drawnPreviews(of contents: Contents, width: Int, in folder: URL) async
  -> (files: [CardPreview: PreviewImageFiles], warnings: [PublishingWarning])
{
  await makePreviewImageFiles(of: contents, favicons: [:], images: [:], width: width, in: folder)
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

/// The red, green and blue of the image's pixel at the point, from the top left.
private func color(at point: (x: Int, y: Int), in image: CGImage) throws -> [Int] {
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

    // Draws the image so that the point lands on the context's only pixel, whose origin is at
    // the bottom left.
    context.draw(
      image,
      in: CGRect(
        x: -point.x, y: point.y + 1 - image.height, width: image.width, height: image.height))
    return true
  }
  try #require(drawn)

  return pixel.prefix(3).map(Int.init)
}

extension [Int] {
  /// Whether each channel is within a few levels of the other's, as JPEG leaves them.
  fileprivate func isClose(to other: [Int]) -> Bool {
    zip(self, other).allSatisfy { a, b in abs(a - b) <= 6 }
  }
}

private func cardPreview(_ boardID: String) -> CardPreview {
  CardPreview(boardID: Document.ID(rawValue: boardID), color: nil)
}

private func brightness(of color: [Int]) -> Double {
  Double(color.reduce(0, +)) / 3 / 255
}
