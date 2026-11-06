import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct RenderBoardsTests {
  @Test func nameTheRootsPageIndexAndTheOthersAfterTheirSlugs() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional"]),
        makeBoard("functional", label: "Functional"),
      ],
      users: [:]
    )
    let slug = try #require(slugs(in: contents)[Document.ID(rawValue: "functional")])

    let (pages, _) = renderBoards(contents, favicons: [:])

    #expect(pages.map(\.path) == ["index.html", "\(slug).html"])
    #expect(pages.allSatisfy { page in page.html.hasSuffix("</html>\n") })
  }

  @Test func linkBoardsAndCardsToTheirPages() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional", "note"]),
        makeBoard("functional", label: "Functional", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )
    let slug = try #require(slugs(in: contents)[Document.ID(rawValue: "functional")])

    let (pages, _) = renderBoards(contents, favicons: [:])

    let root = try #require(pages.first)
    #expect(root.html.contains(#"<a class="body panel" href="\#(slug).html""#))
    #expect(root.html.contains(#"<a href="\#(slug).html#card-note">Functional</a>"#))
    #expect(pages.last?.html.contains(#"<a href="index.html" rel="up">Languages</a>"#) == true)
  }

  @Test func referToFilesUnderFilesWithEachSegmentEncoded() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["Tom & Jerry", "link"]), makeImage("Tom & Jerry"),
        makeLink("link", url: "https://ocaml.org"),
      ],
      users: [:]
    )

    let (pages, _) = renderBoards(
      contents, favicons: ["ocaml.org": makeAsset("ocaml.org.png")])

    let html = try #require(pages.first?.html)
    #expect(html.contains(#"src="files/Tom%20%26%20Jerry.png""#))
    #expect(html.contains(#"src="files/favicons/ocaml.org.png""#))
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
