import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct EmbedFilesTests {
  @Test func areTheIndexThenTheViewsThenTheFilesTheyReferToThenTheViewer() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(from: renderedBoards(for: contents, favicons: [:]))

    #expect(
      files.map(\.path) == [
        "boards.json", "boards/root.html", "files/image.png", "allume.css", "allume.js",
      ])
  }

  @Test func keepTheViewsReferences() throws {
    let contents = try makeContents(with: [makeImage("image.png")])

    let files = embedFiles(from: renderedBoards(for: contents, favicons: [:]))

    let view = files.first { file in file.path == "boards/root.html" }?.source
    guard case .text(let html)? = view else {
      Issue.record("The root's view isn't text: \(String(describing: view))")
      return
    }
    #expect(html.hasPrefix(#"<div class="allume""#))
    #expect(html.contains(#"src="allume:file/image.png""#))
  }
}
