import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct RenderBoardsTests {
  @Test func renderEachBoardsViewInBreadthFirstOrder() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional"]),
        makeBoard("functional", label: "Functional"),
      ],
      users: [:]
    )

    let (views, _) = renderBoards(contents, favicons: [:], images: [:])

    #expect(views.map(\.boardID.rawValue) == ["root", "functional"])
    #expect(views.allSatisfy { view in view.html.hasPrefix(#"<div class="allume""#) })
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

    let (views, _) = renderBoards(contents, favicons: [:], images: [:])

    let root = try #require(views.first)
    #expect(
      root.html.contains(#"<a class="allume-body allume-panel" href="allume:board/functional""#))
    #expect(root.html.contains(#"<a href="allume:board/functional#card-note">Functional</a>"#))
    let functional = try #require(views.last)
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

    let (views, _) = renderBoards(
      contents, favicons: ["ocaml.org": makeAsset("ocaml.org.png")], images: [:])

    let html = try #require(views.first?.html)
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

    let (_, files) = renderBoards(contents, favicons: [:], images: [:])

    #expect(files.map(\.path) == ["image.png", "root_ink.svg"])
  }

  @Test func previewTheRootWithThumbnailsListingItsFilesOnce() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["image", "child"]), makeBoard("child", cards: ["image"]),
        makeImage("image"),
      ],
      users: [:]
    )
    let images = [
      "image.png": ImageFiles(image: makeAsset("image.png"), thumbnail: makeAsset("image.jpg"))
    ]

    let preview = renderRootPreview(contents, favicons: [:], images: images)

    #expect(preview.html.contains(#"src="allume:file/thumbs/image.jpg""#))
    #expect(preview.files.map(\.path) == ["thumbs/image.jpg"])
  }
}
