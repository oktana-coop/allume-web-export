import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct SiteFilesTests {
  @Test func areThePagesThenTheFilesTheyReferToThenTheViewer() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(for: contents, favicons: [:])

    #expect(files.map(\.path) == ["index.html", "files/image.png", "viewer.css", "viewer.js"])
  }

  @Test func holdThePagesTextAndCopyEverythingElse() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(for: contents, favicons: [:])

    let sources = files.map(\.source)
    guard case .text(let page) = sources.first else {
      Issue.record("The first file isn't a page: \(String(describing: sources.first))")
      return
    }
    #expect(page.hasPrefix("<!doctype html>"))
    #expect(sources.dropFirst().first == .copy(URL(filePath: "/bundle/files/image.png")))
  }

  @Test func copyTheLinksFavicons() throws {
    let contents = try makeContents(with: [makeLink("link", url: "https://ocaml.org/docs")])
    let icon = URL(filePath: "/cache/favicons/ocaml.org.png")

    let files = siteFiles(
      for: contents, favicons: ["ocaml.org": Asset(name: "ocaml.org.png", url: icon)])

    #expect(files.contains(SiteFile(path: "files/favicons/ocaml.org.png", source: .copy(icon))))
  }

  @Test func copyThePackagesViewerFiles() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = siteFiles(for: contents, favicons: [:])

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
