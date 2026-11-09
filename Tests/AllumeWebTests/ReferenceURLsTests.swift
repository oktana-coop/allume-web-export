import AllumeWebModels
import AllumeWebRendering
import Testing

@testable import AllumeWeb

@Suite struct ReferenceURLsTests {
  @Test func fillEachBoardsSlugIntoThePattern() throws {
    let contents = try makeContents(with: [makeBoard("functional", label: "Functional")])
    let slug = try #require(slugs(in: contents)[Document.ID(rawValue: "functional")])

    let urls = boardURLs(pattern: "/boards/{slug}/", in: boardsIndex(for: contents))

    #expect(urls[Document.ID(rawValue: "functional")] == "/boards/\(slug)/")
  }

  @Test func leadToABoardsURLWithACardOnItAsTheHash() throws {
    let board = Reference.board(
      BoardReference(
        boardID: Document.ID(rawValue: "functional"), cardID: Document.ID(rawValue: "note")))

    let resolved = try board.url(in: urls)

    #expect(resolved == "functional.html#card-note")
  }

  @Test func leadToAFileUnderThePrefixWithEachSegmentEncoded() throws {
    let file = Reference.file(FileReference(path: "favicons/Tom & Jerry.png"))

    let resolved = try file.url(in: urls)

    #expect(resolved == "files/favicons/Tom%20%26%20Jerry.png")
  }

  @Test func failOnABoardTheURLsDontList() {
    let board = Reference.board(BoardReference(boardID: Document.ID(rawValue: "haskell")))

    #expect(throws: UnknownBoardError(boardID: Document.ID(rawValue: "haskell"))) {
      try board.url(in: urls)
    }
  }
}

private let urls = ReferenceURLs(
  boards: [Document.ID(rawValue: "functional"): "functional.html"], files: "files/")
