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
            <div class="allume-card allume-note-card" data-allume-doc="note" id="card-note"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="allume-body">Tom &amp; Jerry</div>
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
            <div class="allume-card allume-note-card" data-allume-doc="note"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="allume-body">A note</div>
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
            <img class="allume-body" src="file:image.png" alt="Figure" title="From Monoids"
              loading="lazy" decoding="async" draggable="false">
            """#)) == true)
    }

    @Test func showTheirThumbnailInPreviewsAndTheOriginalOnTheBoardsOwnPage() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["image"]), makeImage("image")],
        users: [:]
      )
      let images = [
        "image.png": ImageFiles(image: makeAsset("image.png"), thumbnail: makeAsset("image.jpg"))
      ]

      let sources = [0, 1].map { depth in
        drawn("image", on: "root", in: contents, depth: depth, images: images)
      }

      #expect(sources[0]?.contains(#"src="file:image.png""#) == true)
      #expect(sources[1]?.contains(#"src="file:thumbs/image.jpg""#) == true)
    }

    @Test func showTheCopyBrowsersCanShowOfAnImageTheyCant() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["image"]), makeImage("image")],
        users: [:]
      )
      // As for a HEIC image, made a JPEG, without a thumbnail.
      let images = ["image.png": ImageFiles(image: makeAsset("image.jpg"), thumbnail: nil)]

      let sources = [0, 1].map { depth in
        drawn("image", on: "root", in: contents, depth: depth, images: images)
      }

      #expect(sources.allSatisfy { html in html?.contains(#"src="file:image.jpg""#) == true })
    }

    @Test func showTheOriginalInPreviewsWithoutAThumbnail() throws {
      let contents = try Contents(
        rootID: Document.ID(rawValue: "root"),
        documents: [makeBoard("root", cards: ["image"]), makeImage("image")],
        users: [:]
      )

      let html = drawn("image", on: "root", in: contents, depth: 1)

      #expect(html?.contains(#"src="file:image.png""#) == true)
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
            <a class="allume-body" href="https://www.Haskell.org/learn" target="_blank" rel="noopener">
              \#(iconMarkup("url"))
              <span class="allume-title">Learn</span>
              <span class="allume-host">haskell.org</span>
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
            <img class="allume-favicon" src="file:favicons/ocaml.org.png" alt="" loading="lazy"
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
            <div class="allume-body">
              \#(iconMarkup("url"))
              <span class="allume-title">example.com/talks/lambda</span>
              <span class="allume-host">example.com/talks/lambda</span>
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

      let html = drawCard(
        wide, on: board, depth: 1, contents: contents, layouts: [:], favicons: [:], images: [:]
      )?
      .rendered(resolving: describe)

      #expect(
        html
          == markup(
            #"""
            <div class="allume-card allume-pdf-card" data-allume-doc="pdf"
              style="left:10px;top:20px;width:320px;z-index:3">
              <div class="allume-body" title="">
                \#(iconMarkup("pdf"))
                <span class="allume-title">PDF</span>
                <span class="allume-host">PDF</span>
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
            <div class="allume-card allume-board-card" data-allume-doc="child" id="card-child"
              style="left:0px;top:0px;width:100px;height:100px;z-index:0">
              <div class="allume-board-title"><span>Untitled board</span></div>
              <a class="allume-body allume-panel" href="board:child" aria-label="Untitled board">
                <div class="allume-preview"
                  style="width:125px;height:125px;transform:scale(0.8) translateY(32px)"></div>
              </a>
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
            <div class="allume-board-title">
              <span class="allume-linked">\#(iconMarkup("linked"))</span>
              <span>Monoids</span>
            </div>
            <div class="allume-body allume-panel">
              <div class="allume-preview"
                  style="width:125px;height:125px;transform:scale(0.8) translateY(32px)"></div>
            </div>
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

    #expect(html?.contains(#"data-allume-doc="note" data-allume-color="purple" style="#) == true)
  }
}
