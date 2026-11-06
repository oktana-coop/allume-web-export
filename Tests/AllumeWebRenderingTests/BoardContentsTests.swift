import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct BoardContentsTests {
  @Test func areConnectionLinesThenCardsByZIndexThenChainsThenInk() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              makeCard("above", frame: Rect(x: 300, y: 0, width: 100, height: 100), zIndex: 2),
              makeCard("below", zIndex: 1),
            ],
            chains: [
              .text(
                TextBlock(
                  id: Chain.ID(rawValue: "text"), position: Point(x: 0, y: 200),
                  lineBreakWidth: nil,
                  paragraphs: [TextBlock.Paragraph(text: "Laziness", highlight: nil)])),
              .comments(
                CommentThread(id: Chain.ID(rawValue: "thread"), cards: [makeCard("comment")])),
            ],
            connections: [
              Connection(
                from: .card(Document.ID(rawValue: "above")),
                to: .card(Document.ID(rawValue: "below")))
            ],
            ink: [Ink(file: makeAsset("root_ink.svg"), size: Size(width: 400, height: 300))])),
        makeNote("above"), makeNote("below"), makeComment("comment"),
      ],
      users: [:]
    )

    let pieces = try #require(drawnContents(of: "root", in: contents))

    #expect(
      pieces.compactMap { piece in piece.firstMatch(of: /^<\w+ class="([^"]*)"/)?.1 } == [
        "connections", "card card--text", "card card--text", "chain", "comment", "ink",
      ])
    #expect(
      pieces.compactMap { piece in piece.firstMatch(of: /^<div [^>]*data-doc="([^"]*)"/)?.1 } == [
        "below", "above",
      ])
  }

  @Test func keepTheExportsOrderForCardsWithTheSameZIndex() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["c", "a", "b"]), makeNote("a"), makeNote("b"), makeNote("c"),
      ],
      users: [:]
    )

    let pieces = try #require(drawnContents(of: "root", in: contents))

    #expect(
      pieces.compactMap { piece in piece.firstMatch(of: /data-doc="([^"]*)"/)?.1 } == [
        "c", "a", "b",
      ])
  }
}
