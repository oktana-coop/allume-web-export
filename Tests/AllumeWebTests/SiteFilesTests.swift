import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb
@testable import AllumeWebRendering

@Suite struct SiteFilesTests {
  @Test func buildEachPageFromTheRenderedBoardsAlone() throws {
    let root = Document.ID(rawValue: "root")
    let functional = Document.ID(rawValue: "functional")
    let boards = RenderedBoards(
      index: BoardsIndex(
        root: root,
        boards: [
          root: BoardsIndex.Board(
            label: "Languages", slug: "languages-abc123", parents: [], view: "boards/root.html"),
          functional: BoardsIndex.Board(
            label: "Functional", slug: "functional-q5tbqj", parents: [root],
            view: "boards/functional.html"),
        ]),
      views: [
        BoardView(boardID: root, html: #"<a href="allume:board/functional">Functional</a>"#),
        BoardView(boardID: functional, html: #"<a href="allume:board/root">Languages</a>"#),
      ],
      files: [], preview: BoardPreview(html: "", files: [], size: Size(width: 0, height: 0)))

    let files = siteFiles(from: boards, theme: .light)

    #expect(
      files.map(\.path) == ["index.html", "functional-q5tbqj.html", "allume.css", "allume.js"])
    let pages = files.compactMap { file -> String? in
      guard case .text(let html) = file.source else { return nil }
      return html
    }
    #expect(pages[0].contains("<title>Languages</title>"))
    #expect(pages[0].contains(#"<a href="functional-q5tbqj.html">"#))
    #expect(pages[1].contains("<title>Functional | Languages</title>"))
    #expect(pages[1].contains(#"<a href="index.html">"#))
  }

  @Test func areThePagesThenTheFilesTheyReferToThenTheViewer() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:], previews: [:]), theme: .light)

    #expect(files.map(\.path) == ["index.html", "files/image.png", "allume.css", "allume.js"])
  }

  @Test func holdThePagesTextAndCopyEverythingElse() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:], previews: [:]), theme: .light)

    let sources = files.map(\.source)
    guard case .text(let page) = sources.first else {
      Issue.record("The first file isn't a page: \(String(describing: sources.first))")
      return
    }
    #expect(page.hasPrefix("<!doctype html>"))
    #expect(sources.dropFirst().first == .copy(URL(filePath: "/bundle/files/image.png")))
  }

  @Test func copyOnlyTheFilesTheViewsShow() throws {
    // The root's own image shows whole on its page, and as a thumbnail in its preview alone.
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(
      from: renderedBoards(for: contents, favicons: [:], images: thumbnailedImage, previews: [:]),
      theme: .light)

    #expect(files.map(\.path).contains("files/image.png"))
    #expect(!files.map(\.path).contains("files/thumbs/image.jpg"))
  }

  @Test func copyTheLinksFavicons() throws {
    let contents = try makeContents(with: [makeLink("link", url: "https://ocaml.org/docs")])
    let icon = URL(filePath: "/cache/favicons/ocaml.org.png")

    let files = siteFiles(
      from: renderedBoards(
        for: contents, favicons: ["ocaml.org": Asset(name: "ocaml.org.png", url: icon)],
        images: [:], previews: [:]), theme: .light)

    #expect(files.contains(OutputFile(path: "files/favicons/ocaml.org.png", source: .copy(icon))))
  }

  @Test func copyThePackagesViewerFiles() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(
      from: renderedBoards(for: contents, favicons: [:], images: [:], previews: [:]), theme: .light)

    let viewerURLs = files.suffix(2).compactMap { file -> URL? in
      guard case .copy(let url) = file.source else {
        return nil
      }
      return url
    }
    #expect(viewerURLs.map(\.lastPathComponent) == ["allume.css", "allume.js"])
    #expect(
      viewerURLs.allSatisfy { url in
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
      })
  }
}
