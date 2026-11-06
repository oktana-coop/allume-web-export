import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct CardsTests {
  @Suite struct Notes {
    @Test func haveTheirIDAndCopyButtonOnTheBoardsOwnPage() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["note"]), makeNote("note", text: "Tom & Jerry")],
        users: [:]
      )

      let html = drawn("note", on: "root", in: contents)

      #expect(
        html
          == markup(
            #"""
            <div class="card card--text" data-doc="note" id="card-note"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="body">Tom &amp; Jerry</div>
              \#(copyButtonMarkup)
            </div>
            """#))
    }

    @Test func leaveOutTheIDAndCopyButtonInPreviews() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["note"]), makeNote("note")],
        users: [:]
      )

      let html = drawn("note", on: "root", in: contents, depth: 1)

      #expect(
        html
          == markup(
            #"""
            <div class="card card--text" data-doc="note"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="body">A note</div>
            </div>
            """#))
    }
  }

  @Suite struct Images {
    @Test func sayWhichDocumentAnExcerptIsFrom() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["image", "pdf"]),
          makeImage("image", label: "Figure", excerptOf: "pdf"),
          makePDF("pdf", label: "Monoids"),
        ],
        users: [:]
      )

      let html = drawn("image", on: "root", in: contents)

      #expect(
        html?.contains(
          markup(
            #"""
            <img class="body" src="file:image.png" alt="Figure" title="From Monoids"
              loading="lazy" decoding="async" draggable="false">
            """#)) == true)
    }
  }

  @Suite struct Links {
    @Test func openTheirURLAndShowItsHost() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["link"]),
          makeLink("link", url: "https://www.Haskell.org/learn", title: "Learn"),
        ],
        users: [:]
      )

      let html = drawn("link", on: "root", in: contents)

      #expect(
        html?.contains(
          markup(
            #"""
            <a class="body" href="https://www.Haskell.org/learn" target="_blank" rel="noopener">
              \#(iconMarkup("url"))
              <span class="title">Learn</span>
              <span class="host">haskell.org</span>
            </a>
            """#)) == true)
    }

    @Test func showTheirSitesFavicon() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["link"]), makeLink("link", url: "https://ocaml.org"),
        ],
        users: [:]
      )

      let html = drawn(
        "link", on: "root", in: contents, favicons: ["ocaml.org": makeAsset("ocaml.org.png")])

      #expect(
        html?.contains(
          markup(
            #"""
            <img class="favicon" src="file:favicons/ocaml.org.png" alt="" loading="lazy"
              draggable="false">
            """#)) == true)
    }

    @Test func showTheWholeURLWithoutAScheme() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["link"]), makeLink("link", url: "example.com/talks/lambda"),
        ],
        users: [:]
      )

      let html = drawn("link", on: "root", in: contents, depth: 1)

      #expect(
        html?.contains(
          markup(
            #"""
            <div class="body">
              \#(iconMarkup("url"))
              <span class="title">example.com/talks/lambda</span>
              <span class="host">example.com/talks/lambda</span>
            </div>
            """#)) == true)
    }
  }

  @Suite struct PDFs {
    @Test func areATileWithTheirTitle() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["pdf"]), makePDF("pdf")],
        users: [:]
      )
      let wide = Card(
        documentID: Document.ID(rawValue: "pdf"),
        frame: Rect(x: 10, y: 20, width: 500, height: 700),
        zIndex: 3, color: nil)
      let board = try #require(contents.board(Document.ID(rawValue: "root")))

      let html = drawCard(wide, on: board, depth: 1, contents: contents, favicons: [:])?
        .rendered(resolving: describe)

      #expect(
        html
          == markup(
            #"""
            <div class="card card--pdf" data-doc="pdf"
              style="left:10px;top:20px;width:320px;z-index:3">
              <div class="body" title="">
                \#(iconMarkup("pdf"))
                <span class="title">PDF</span>
                <span class="host">PDF</span>
              </div>
            </div>
            """#))
    }
  }

  @Suite struct Boards {
    @Test func linkToTheirBoardOnTheBoardsOwnPage() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["child"]), makeBoard("child")],
        users: [:]
      )

      let html = drawn("child", on: "root", in: contents)

      #expect(
        html
          == markup(
            #"""
            <div class="card card--board" data-doc="child" id="card-child"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="board-title"><span>Untitled board</span></div>
              <a class="body panel" href="board:child" aria-label="Untitled board"></a>
            </div>
            """#))
    }

    @Test func showTheyAreLinkedWithAnIconInPreviews() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [
          makeBoard("root", cards: ["a", "child"]), makeBoard("a", cards: ["child"]),
          makeBoard("child", label: "Monoids"),
        ],
        users: [:]
      )

      let html = drawn("child", on: "root", in: contents, depth: 1)

      #expect(
        html?.contains(
          markup(
            #"""
            <div class="board-title">
              <span class="linked">\#(iconMarkup("linked"))</span>
              <span>Monoids</span>
            </div>
            <div class="body panel"></div>
            """#)) == true)
    }
  }

  @Test func carryTheirColor() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [makeCard("note", color: .purple)], chains: [], connections: [], ink: [])),
        makeNote("note"),
      ],
      users: [:]
    )

    let html = drawn("note", on: "root", in: contents, depth: 1)

    #expect(html?.contains(#"data-doc="note" data-color="purple" style="#) == true)
  }
}
