import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct RenderBoardsTests {
  @Test func renderEachBoardAsAPageInBreadthFirstOrder() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional"]),
        makeBoard("functional", label: "Functional"),
      ],
      users: [:]
    )

    let (pages, _) = renderBoards(contents, favicons: [:])

    #expect(pages.map(\.boardID.rawValue) == ["root", "functional"])
    #expect(pages.allSatisfy { page in page.html.hasSuffix("</html>\n") })
  }

  @Test func linkBoardsAndCardsWithReferences() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional", "note"]),
        makeBoard("functional", label: "Functional", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )

    let (pages, _) = renderBoards(contents, favicons: [:])

    let root = try #require(pages.first)
    #expect(root.html.contains(#"<a class="body panel" href="allume:board/functional""#))
    #expect(root.html.contains(#"<a href="allume:board/functional#card-note">Functional</a>"#))
    let functional = try #require(pages.last)
    #expect(functional.html.contains(#"<a href="allume:board/root" rel="up">Languages</a>"#))
  }

  @Test func referToFilesWithEachSegmentOfTheirPathEncoded() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["Tom & Jerry", "link"]), makeImage("Tom & Jerry"),
        makeLink("link", url: "https://ocaml.org"),
      ],
      users: [:]
    )

    let (pages, _) = renderBoards(contents, favicons: ["ocaml.org": makeAsset("ocaml.org.png")])

    let html = try #require(pages.first?.html)
    #expect(html.contains(#"src="allume:file/Tom%20%26%20Jerry.png""#))
    #expect(html.contains(#"src="allume:file/favicons/ocaml.org.png""#))
  }

  @Test func listEachFileOnceInTheOrderFirstReferredTo() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [makeCard("child"), makeCard("image")], chains: [], connections: [],
            ink: [Ink(file: makeAsset("root_ink.svg"), size: Size(width: 100, height: 100))])),
        makeBoard("child", cards: ["image"]), makeImage("image"),
      ],
      users: [:]
    )

    let (_, files) = renderBoards(contents, favicons: [:])

    #expect(files.map(\.path) == ["image.png", "root_ink.svg"])
  }
}
