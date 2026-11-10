import AllumeWebImages
import AllumeWebModels
import AllumeWebRendering
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct EmbedFilesTests {
  @Test func areTheIndexThenTheViewsThenThePreviewImagesThenTheFilesThenTheViewer() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]),
      urlPatterns: URLPatterns(), previewImages: previewImages)

    #expect(
      files.map(\.path) == [
        "boards.json", "boards/root.html", "preview-light.jpg", "preview-dark.jpg",
        "files/image.png", "allume.css", "allume.js",
      ])
  }

  @Test func writeThePreviewImagesAndListThemInTheIndex() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]),
      urlPatterns: URLPatterns(), previewImages: previewImages)

    #expect(
      files.contains(OutputFile(path: "preview-light.jpg", source: .data(Data("light".utf8)))))
    #expect(files.contains(OutputFile(path: "preview-dark.jpg", source: .data(Data("dark".utf8)))))
    let index = try #require(text(of: "boards.json", in: files))
    #expect(index.contains(#""dark" : "preview-dark.jpg""#))
    #expect(index.contains(#""light" : "preview-light.jpg""#))
  }

  @Test func leaveThePreviewOutWithoutItsImages() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: thumbnailedImage),
      urlPatterns: URLPatterns(), previewImages: nil)

    #expect(!files.map(\.path).contains { path in path.hasPrefix("preview") })
    #expect(!files.map(\.path).contains("files/thumbs/image.jpg"))
    #expect(try #require(text(of: "boards.json", in: files)).contains("preview") == false)
  }

  @Test func keepTheViewsReferencesWithoutPatterns() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]),
      urlPatterns: URLPatterns(), previewImages: nil)

    let html = try #require(rootView(in: files))
    #expect(html.hasPrefix(#"<div class="allume""#))
    #expect(html.contains(#"src="allume:file/image.png""#))
  }

  @Test func resolveTheViewsReferencesFromThePatterns() throws {
    let contents = try makeContents(with: [
      makeBoard("functional", label: "Functional"), makeImage("image.png"),
    ])
    let slug = try #require(slugs(in: contents)[Document.ID(rawValue: "functional")])
    let urlPatterns = URLPatterns(board: "/boards/{slug}/", files: "/allume/files")

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]), urlPatterns: urlPatterns,
      previewImages: nil)

    let html = try #require(rootView(in: files))
    #expect(html.contains(#"href="/boards/\#(slug)/""#))
    #expect(html.contains(#"src="/allume/files/image.png""#))
    #expect(!html.contains("allume:"))
  }

  @Test func keepTheReferencesOfAKindWithoutAPattern() throws {
    let contents = try makeContents(with: [
      makeBoard("functional", label: "Functional"), makeImage("image.png"),
    ])
    let urlPatterns = URLPatterns(files: "/allume/files/")

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]), urlPatterns: urlPatterns,
      previewImages: nil)

    let html = try #require(rootView(in: files))
    #expect(html.contains(#"href="allume:board/functional""#))
    #expect(html.contains(#"src="/allume/files/image.png""#))
  }
}

/// The root's view, if it's among the files as text.
private func rootView(in files: [OutputFile]) -> String? {
  text(of: "boards/root.html", in: files)
}

/// The file's text, if it's among the files as text.
private func text(of path: String, in files: [OutputFile]) -> String? {
  files.compactMap { file -> String? in
    guard file.path == path, case .text(let text) = file.source else { return nil }
    return text
  }.first
}

/// Stand-ins for the preview's images, which only WebKit draws.
private let previewImages = PreviewImages(
  light: WebImage(data: Data("light".utf8), format: .jpeg),
  dark: WebImage(data: Data("dark".utf8), format: .jpeg))
