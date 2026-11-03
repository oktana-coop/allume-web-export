import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct BoardsTests {
  @Test func readsTheFixturesBoardsWithoutWarnings() throws {
    let bundle = try AllumeBundle(contentsOf: fixtureURL)

    let (documents, warnings) = readDocuments(in: bundle)

    let root = board(bundle.contents.root, in: documents)
    #expect(
      documents.compactMap { document in board(document.id.rawValue, in: documents) }.count == 13)
    #expect(root?.label == "Languages")
    #expect(root?.cards.count == 5)
    #expect(root?.chains.count == 2)
    #expect(root?.connections.count == 2)
    #expect(root?.ink.count == 1)
    #expect(warnings.isEmpty)
  }

  @Test func readsACardsFrameAndColor() throws {
    let card = makeCardJSON("n", color: "Purple", frame: (10, 20, 300, 200), z: 3)
    let contents = makeContents(documents: #""b" : {"type" : "board", "cards" : [\#(card)]}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(
      board("b", in: documents)?.cards == [
        Card(
          documentID: Document.ID(rawValue: "n"),
          frame: Rect(x: 10, y: 20, width: 300, height: 200),
          zIndex: 3, color: .purple)
      ])
    #expect(warnings.isEmpty)
  }

  @Test func leavesOutAnUnknownCardColor() throws {
    let card = makeCardJSON("n", color: "Teal")
    let contents = makeContents(documents: #""b" : {"type" : "board", "cards" : [\#(card)]}"#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(board("b", in: documents)?.cards.first?.color == nil)
    #expect(
      warnings == [
        .unknownCardColor(
          boardID: Document.ID(rawValue: "b"), documentID: Document.ID(rawValue: "n"), color: "Teal"
        )
      ])
  }

  @Test func readsCanvasTextWithItsHighlights() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "chains" : [{
          "chain_id" : "t", "position_x" : 5, "position_y" : 6, "line_break_width" : 600,
          "text_file" : "t.txt", "format" : {"0" : {"color" : "Purple"}}, "ink_models" : {}
        }]}
        """#)

    let (documents, warnings) = try withBundle(
      contents: contents, files: ["t.txt": "Title\n\nBody"]
    ) {
      bundle in readDocuments(in: bundle)
    }

    let text = TextBlock(
      id: Chain.ID(rawValue: "t"), position: Point(x: 5, y: 6), lineBreakWidth: 600,
      paragraphs: [
        TextBlock.Paragraph(text: "Title", highlight: .purple),
        TextBlock.Paragraph(text: "", highlight: nil),
        TextBlock.Paragraph(text: "Body", highlight: nil),
      ])
    #expect(board("b", in: documents)?.chains == [.text(text)])
    #expect(warnings.isEmpty)
  }

  @Test func leavesOutAnUnknownHighlightColor() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "chains" : [{
          "chain_id" : "t", "position_x" : 0, "position_y" : 0, "text_file" : "t.txt",
          "format" : {"0" : {"color" : "Teal"}}, "ink_models" : {}
        }]}
        """#)

    let (documents, warnings) = try withBundle(contents: contents, files: ["t.txt": "Title"]) {
      bundle in readDocuments(in: bundle)
    }

    guard case .text(let text) = board("b", in: documents)?.chains.first else {
      Issue.record("Expected the canvas text")
      return
    }
    #expect(text.paragraphs == [TextBlock.Paragraph(text: "Title", highlight: nil)])
    #expect(warnings == [.unknownHighlightColor(Chain.ID(rawValue: "t"), color: "Teal")])
  }

  @Test func leavesCanvasTextEmptyWhenItsFileIsMissing() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "chains" : [{
          "chain_id" : "t", "position_x" : 0, "position_y" : 0, "text_file" : "t.txt",
          "ink_models" : {}
        }]}
        """#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    guard case .text(let text) = board("b", in: documents)?.chains.first else {
      Issue.record("Expected the canvas text")
      return
    }
    #expect(text.paragraphs == [TextBlock.Paragraph(text: "", highlight: nil)])
    #expect(warnings == [.missingFile(name: "t.txt")])
  }

  @Test func readsACommentThread() throws {
    let card = makeCardJSON("c")
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "chains" : [{
          "chain_id" : "thread", "position_x" : 0, "position_y" : 0, "cards" : [\#(card)],
          "ink_models" : {}
        }]}
        """#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    guard case .comments(let thread) = board("b", in: documents)?.chains.first else {
      Issue.record("Expected the comment thread")
      return
    }
    #expect(thread.id == Chain.ID(rawValue: "thread"))
    #expect(thread.cards.map(\.documentID.rawValue) == ["c"])
    #expect(warnings.isEmpty)
  }

  @Test func leavesOutInkOnAChain() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "chains" : [{
          "chain_id" : "t", "position_x" : 0, "position_y" : 0,
          "ink_models" : {"0" : {"ink_svg" : "t.svg", "scale" : 1}}
        }]}
        """#)

    let (_, warnings) = try withBundle(contents: contents) { bundle in readDocuments(in: bundle) }

    #expect(warnings == [.inkOnChain(Chain.ID(rawValue: "t"))])
  }

  @Test func resolvesConnectionEnds() throws {
    let card = makeCardJSON("a", cardID: "card a")
    let contents = makeContents(
      documents: #"""
        "b" : {
          "type" : "board", "cards" : [\#(card)],
          "chains" : [{"chain_id" : "t", "position_x" : 0, "position_y" : 0, "ink_models" : {}}],
          "connections" : [["card a", "t"], ["card a", "nowhere"], ["card a"]]
        }
        """#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(
      board("b", in: documents)?.connections == [
        Connection(from: .card(Document.ID(rawValue: "a")), to: .chain(Chain.ID(rawValue: "t")))
      ])
    #expect(
      warnings == [
        .unknownConnectionEnd(boardID: Document.ID(rawValue: "b"), end: "nowhere"),
        .malformedConnection(boardID: Document.ID(rawValue: "b")),
      ])
  }

  @Test func readsInkSizesFromTheirSVGs() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "ink_models" : {
          "10" : {"ink_svg" : "second.svg", "scale" : 2},
          "2" : {"ink_svg" : "first.svg", "scale" : 1}
        }}
        """#)
    let files = [
      "first.svg": #"<svg xmlns="http://www.w3.org/2000/svg" width="10" height="20"></svg>"#,
      "second.svg": #"<svg viewBox="0, 0, 7, 5" height="5" width="7"></svg>"#,
    ]

    let (documents, warnings) = try withBundle(contents: contents, files: files) { bundle in
      readDocuments(in: bundle)
    }

    let ink = board("b", in: documents)?.ink
    #expect(ink?.map(\.file.name) == ["first.svg", "second.svg"])
    #expect(ink?.map(\.size) == [Size(width: 10, height: 20), Size(width: 14, height: 10)])
    #expect(warnings.isEmpty)
  }

  @Test func leavesOutInkWhoseSVGIsMissing() throws {
    let contents = makeContents(
      documents: #"""
        "b" : {"type" : "board", "ink_models" : {"0" : {"ink_svg" : "gone.svg", "scale" : 1}}}
        """#)

    let (documents, warnings) = try withBundle(contents: contents) { bundle in
      readDocuments(in: bundle)
    }

    #expect(board("b", in: documents)?.ink.isEmpty == true)
    #expect(warnings == [.missingFile(name: "gone.svg")])
  }
}

private func board(_ id: String, in documents: [Document]) -> Document.Board? {
  documents.lazy.compactMap { document -> Document.Board? in
    guard case .board(let board) = document, board.id.rawValue == id else {
      return nil
    }
    return board
  }.first
}
