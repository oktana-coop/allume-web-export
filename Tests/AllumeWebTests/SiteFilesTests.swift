import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct SiteFilesTests {
  @Test func areThePagesThenTheFilesTheyReferToThenTheViewer() throws {
    let contents = try makeContents()

    let files = siteFiles(for: contents)

    #expect(files.map(\.path) == ["index.html", "files/image.png", "viewer.css", "viewer.js"])
  }

  @Test func holdThePagesTextAndCopyEverythingElse() throws {
    let contents = try makeContents()

    let files = siteFiles(for: contents)

    let sources = files.map(\.source)
    guard case .text(let page) = sources.first else {
      Issue.record("The first file isn't a page: \(String(describing: sources.first))")
      return
    }
    #expect(page.hasPrefix("<!doctype html>"))
    #expect(sources.dropFirst().first == .copy(URL(filePath: "/bundle/files/image.png")))
  }

  @Test func copyThePackagesViewerFiles() throws {
    let contents = try makeContents()

    let files = siteFiles(for: contents)

    let viewerURLs = files.suffix(2).compactMap { file -> URL? in
      guard case .copy(let url) = file.source else {
        return nil
      }
      return url
    }
    #expect(viewerURLs.map(\.lastPathComponent) == ["viewer.css", "viewer.js"])
    #expect(
      viewerURLs.allSatisfy { url in
        FileManager.default.fileExists(atPath: url.path(percentEncoded: false))
      })
  }
}

/// A root board with an image on it.
private func makeContents() throws -> Contents {
  try Contents(
    rootID: Document.ID(rawValue: "root"),
    documents: [
      .board(
        Document.Board(
          id: Document.ID(rawValue: "root"), label: "Languages",
          cards: [
            Card(
              documentID: Document.ID(rawValue: "image"),
              frame: Rect(x: 0, y: 0, width: 100, height: 100), zIndex: 0, color: nil)
          ],
          chains: [], connections: [], ink: [])),
      .image(
        Document.Image(
          id: Document.ID(rawValue: "image"), label: nil,
          file: Asset(name: "image.png", url: URL(filePath: "/bundle/files/image.png")),
          excerpt: nil)),
    ],
    users: [:]
  )
}
