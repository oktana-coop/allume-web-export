import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebRendering

@Suite struct LayoutTests {
  @Suite struct ContentBounds {
    @Test func spanCardsAndText() {
      let board = makeBoardValue(
        cards: [
          makeCard("a", frame: Rect(x: 100, y: 50, width: 200, height: 100)),
          makeCard("b", frame: Rect(x: 400, y: 300, width: 100, height: 50)),
        ],
        chains: [.text(makeText(at: Point(x: 50, y: 500), ["Hi"]))])

      let contentBounds = layout(of: board).contentBounds

      // The text's line, 24 px, padded 5 above and below.
      #expect(contentBounds == Rect(x: 50, y: 50, width: 450, height: 484))
    }

    @Test func spanCommentThreads() {
      let board = makeBoardValue(
        cards: [makeCard("a", frame: Rect(x: 100, y: 100, width: 100, height: 100))],
        chains: [
          .comments(
            CommentThread(
              id: Chain.ID(rawValue: "thread"),
              cards: [makeCard("comment", frame: Rect(x: 600, y: 0, width: 100, height: 40))]))
        ])

      let contentBounds = layout(of: board).contentBounds

      #expect(contentBounds == Rect(x: 100, y: 0, width: 600, height: 200))
    }

    @Test func extendOnlyTheFarEdgesWithInk() {
      let board = makeBoardValue(
        cards: [makeCard("a", frame: Rect(x: 100, y: 100, width: 100, height: 100))],
        ink: [makeInk(width: 400, height: 50)])

      let contentBounds = layout(of: board).contentBounds

      #expect(contentBounds == Rect(x: 100, y: 100, width: 300, height: 100))
    }

    @Test func areEmptyForAnEmptyBoard() {
      let contentBounds = layout(of: makeBoardValue()).contentBounds

      #expect(contentBounds == Rect(x: 0, y: 0, width: 0, height: 0))
    }
  }

  @Suite struct TextEstimates {
    @Test func wrapLongParagraphs() {
      let text = makeText(
        at: Point(x: 0, y: 0), [String(repeating: "a", count: 100), ""], lineBreakWidth: 400)

      let contentBounds = layout(of: makeBoardValue(chains: [.text(text)])).contentBounds

      // 100 characters wrap onto 3 lines of 400, the empty paragraph takes a fourth, and each
      // paragraph is padded 5 above and below.
      #expect(contentBounds == Rect(x: 0, y: 0, width: 400, height: 116))
    }

    @Test func giveHeadingsTallerLines() {
      let text = TextBlock(
        id: Chain.ID(rawValue: "text"), position: Point(x: 0, y: 0), lineBreakWidth: 400,
        paragraphs: [
          TextBlock.Paragraph(text: "Capitalism", highlight: nil, role: .heading),
          TextBlock.Paragraph(text: "Private Property", highlight: nil),
        ])

      let contentBounds = layout(of: makeBoardValue(chains: [.text(text)])).contentBounds

      // A heading's line is 34 px, and body text's 24, each padded 5 above and below.
      #expect(contentBounds.height == 78)
    }

    @Test func countUTF16Units() {
      let emoji = makeText(at: Point(x: 0, y: 0), ["😀"])
      let letters = makeText(at: Point(x: 0, y: 0), ["ab"])

      let emojiWidth = layout(of: makeBoardValue(chains: [.text(emoji)])).contentBounds.width
      let lettersWidth = layout(of: makeBoardValue(chains: [.text(letters)])).contentBounds.width

      #expect(emojiWidth == lettersWidth)
    }
  }

  @Suite struct ConnectionLines {
    @Test func joinTheEdgesAndStopShort() {
      let board = makeBoardValue(
        cards: [
          makeCard("a", frame: Rect(x: 0, y: 0, width: 100, height: 100)),
          makeCard("b", frame: Rect(x: 300, y: 0, width: 100, height: 100)),
        ],
        connections: [connection("a", "b")])

      let lines = layout(of: board).connectionLines

      #expect(lines == [Line(from: Point(x: 110, y: 50), to: Point(x: 290, y: 50))])
    }

    @Test func joinCommentThreadsAndTheirComments() {
      let thread = CommentThread(
        id: Chain.ID(rawValue: "thread"),
        cards: [makeCard("comment", frame: Rect(x: 0, y: 300, width: 100, height: 100))])
      let board = makeBoardValue(
        cards: [makeCard("a", frame: Rect(x: 0, y: 0, width: 100, height: 100))],
        chains: [.comments(thread)],
        connections: [
          Connection(from: .card(Document.ID(rawValue: "a")), to: .chain(thread.id)),
          Connection(
            from: .card(Document.ID(rawValue: "comment")), to: .card(Document.ID(rawValue: "a"))),
        ])

      let lines = layout(of: board).connectionLines

      #expect(
        lines == [
          Line(from: Point(x: 50, y: 110), to: Point(x: 50, y: 290)),
          Line(from: Point(x: 50, y: 290), to: Point(x: 50, y: 110)),
        ])
    }

    @Test func leaveOutLinesWithoutRoom() {
      let board = makeBoardValue(
        cards: [
          makeCard("a", frame: Rect(x: 0, y: 0, width: 100, height: 100)),
          makeCard("b", frame: Rect(x: 115, y: 0, width: 100, height: 100)),
        ],
        connections: [connection("a", "b")])

      let lines = layout(of: board).connectionLines

      #expect(lines.isEmpty)
    }
  }

  @Suite struct Layouts {
    @Test func coverEveryBoard() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["child"]), makeBoard("child")],
        users: [:]
      )

      let layouts = layouts(in: contents)

      #expect(Set(layouts.keys.map(\.rawValue)) == ["root", "child"])
    }
  }

  @Suite struct PreviewScale {
    @Test func showsAWindowsWidthOfTheBoardInTheCard() {
      let scale = previewScale(in: Rect(x: 0, y: 0, width: 360, height: 100))

      #expect(scale == 0.25)
    }

    @Test func isAtMost08() {
      let scale = previewScale(in: Rect(x: 0, y: 0, width: 1600, height: 100))

      #expect(scale == 0.8)
    }
  }
}

private func makeBoardValue(
  cards: [Card] = [], chains: [Chain] = [], connections: [Connection] = [], ink: [Ink] = []
) -> Document.Board {
  Document.Board(
    id: Document.ID(rawValue: "board"), label: nil, cards: cards, chains: chains,
    connections: connections, ink: ink)
}

private func makeText(
  at position: Point, _ paragraphs: [String], lineBreakWidth: Double? = nil
) -> TextBlock {
  TextBlock(
    id: Chain.ID(rawValue: "text"), position: position, lineBreakWidth: lineBreakWidth,
    paragraphs: paragraphs.map { text in TextBlock.Paragraph(text: text, highlight: nil) })
}

private func makeInk(width: Double, height: Double) -> Ink {
  Ink(
    file: Asset(name: "ink.svg", url: URL(filePath: "/ink.svg")),
    size: Size(width: width, height: height))
}

private func connection(_ from: String, _ to: String) -> Connection {
  Connection(from: .card(Document.ID(rawValue: from)), to: .card(Document.ID(rawValue: to)))
}
