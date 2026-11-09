import AllumeWebModels
import AllumeWebRendering
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct EmbedFilesTests {
  @Test func areTheIndexThenTheViewsThenTheFilesTheyReferToThenTheViewer() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]),
      urlPatterns: URLPatterns())

    #expect(
      files.map(\.path) == [
        "boards.json", "boards/root.html", "files/image.png", "allume.css", "allume.js",
      ])
  }

  @Test func keepTheViewsReferencesWithoutPatterns() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:]),
      urlPatterns: URLPatterns())

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
      from: renderedBoards(for: contents, favicons: [:], images: [:]), urlPatterns: urlPatterns)

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
      from: renderedBoards(for: contents, favicons: [:], images: [:]), urlPatterns: urlPatterns)

    let html = try #require(rootView(in: files))
    #expect(html.contains(#"href="allume:board/functional""#))
    #expect(html.contains(#"src="/allume/files/image.png""#))
  }
}

/// The root's view, if it's among the files as text.
private func rootView(in files: [OutputFile]) -> String? {
  files.compactMap { file -> String? in
    guard file.path == "boards/root.html", case .text(let html) = file.source else { return nil }
    return html
  }.first
}
