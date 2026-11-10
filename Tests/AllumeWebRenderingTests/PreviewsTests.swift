import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct PreviewsTests {
  @Test func showTheBoardOnAPageOfTheSizeAtItsOwnSize() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [makeCard("note", frame: Rect(x: 100, y: 50, width: 200, height: 100))],
            chains: [], connections: [], ink: [])),
        makeNote("note"),
      ],
      users: [:]
    )

    let html = try drawnPreviewPage(of: "root", in: contents)

    #expect(
      html.hasPrefix(
        #"<div class="allume allume-board-preview" style="width:250px;height:145px">"#))
    #expect(
      html.contains(
        markup(
          #"""
          <div class="allume-preview" style="transform:translateY(32px)">
            <div class="allume-card allume-note-card" data-allume-doc="note"
              style="left:100px;top:50px;width:200px;height:100px;z-index:0">
              <div class="allume-body">A note</div>
            </div>
          </div>
          """#)))
  }

  @Test func showTheBoardOnAPageInTheColorOfItsCards() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["note"]), makeNote("note")],
      users: [:]
    )

    let html = try drawnPreviewPage(of: "root", in: contents, color: .purple)

    #expect(html.hasPrefix(#"<div class="allume allume-board-preview" data-allume-color="purple""#))
  }

  @Test func showTheBoardCardsOnThePageWithTheirPreviewsImages() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["child"]), makeBoard("child", cards: ["grandchild"]),
        makeBoard("grandchild", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )
    let previews = [
      CardPreview(boardID: Document.ID(rawValue: "grandchild"), color: nil): PreviewImageFiles(
        light: makeAsset("grandchild-light.jpg"), dark: makeAsset("grandchild-dark.jpg"),
        size: Size(width: 1440, height: 1440))
    ]

    let html = try drawnPreviewPage(of: "child", in: contents, previews: previews)

    #expect(html.contains(#"src="file:previews/grandchild-light.jpg""#))
    #expect(html.contains(#"src="file:previews/grandchild-dark.jpg""#))
  }

  @Test func leaveOutWhateverCanBeClicked() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["child", "note"]),
        makeBoard("child", cards: ["note", "link", "grandchild"], comments: ["comment"]),
        makeBoard("grandchild"), makeNote("note"), makeLink("link", url: "https://ocaml.org"),
        makeComment("comment"),
      ],
      users: [:]
    )

    let html = try drawnPreviewPage(of: "child", in: contents)

    #expect(
      html.contains(#"data-allume-doc="link""#) && html.contains(#"<div class="allume-comment""#))
    #expect(!html.contains("<button"))
    #expect(!html.contains(#" id="card-"#))
    #expect(!html.contains("<a "))
  }

  @Test func putEachPieceOnALineOfItsOwn() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["child"]), makeBoard("child", cards: ["a", "b"]),
        makeNote("a"), makeNote("b"),
      ],
      users: [:]
    )

    let html = try drawnPreviewPage(of: "child", in: contents)

    #expect(
      html.contains(
        #"</div>"# + "\n" + #"<div class="allume-card allume-note-card" data-allume-doc="b""#))
    #expect(html.hasSuffix("</div>\n</div>"))
  }
}

/// The board's preview page, 250 by 145, with references described.
private func drawnPreviewPage(
  of boardID: String, in contents: Contents, color: CardColor? = nil,
  previews: [CardPreview: PreviewImageFiles] = [:]
) throws -> String {
  let board = try #require(contents.board(Document.ID(rawValue: boardID)))

  return drawBoardPreview(
    of: board, color: color, size: Size(width: 250, height: 145), contents: contents,
    layouts: layouts(in: contents), favicons: [:], images: [:], previews: previews
  )
  .rendered(resolving: describe)
}
