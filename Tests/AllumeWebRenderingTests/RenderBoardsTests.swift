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

    let (views, _) = renderBoards(contents, favicons: [:], images: [:], previews: [:])

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

    let (views, _) = renderBoards(contents, favicons: [:], images: [:], previews: [:])

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
      contents, favicons: ["ocaml.org": makeAsset("ocaml.org.png")], images: [:], previews: [:])

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

    let (_, files) = renderBoards(contents, favicons: [:], images: [:], previews: [:])

    #expect(files.map(\.path) == ["image.png", "root_ink.svg"])
  }

  @Test func previewTheRootWithItsImagesWholeAndItsBoardCardsShowingTheirImages() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["photo", "child"]), makeBoard("child", cards: ["photo"]),
        makeImage("photo"),
      ],
      users: [:]
    )
    let images = [
      "photo.png": ImageFiles(image: makeAsset("photo.png"), thumbnail: makeAsset("photo.jpg"))
    ]
    let previews = [
      CardPreview(boardID: Document.ID(rawValue: "child"), color: nil): PreviewImageFiles(
        light: makeAsset("child-light.jpg"), dark: makeAsset("child-dark.jpg"),
        size: Size(width: 1440, height: 1440))
    ]

    let preview = renderRootPreview(contents, favicons: [:], images: images, previews: previews)

    #expect(
      preview.files.map(\.path) == [
        "photo.png", "previews/child-light.jpg", "previews/child-dark.jpg",
      ])
  }

  @Test func previewTheRootWhole() throws {
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

    let preview = renderRootPreview(contents, favicons: [:], images: [:], previews: [:])

    // 100 + 200 wide, with the margin at the origin repeated; room for titles, then 50 + 100,
    // and the margin.
    #expect(preview.size == Size(width: 400, height: 232))
  }

  @Test func sizeEachBoardsPreviewAsAWindowOfItForItsLargestCard() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [
              makeCard("child", frame: Rect(x: 0, y: 0, width: 360, height: 90)),
              makeCard("other"),
            ], chains: [], connections: [], ink: [])),
        .board(
          Document.Board(
            id: Document.ID(rawValue: "other"), label: nil,
            cards: [makeCard("child", frame: Rect(x: 0, y: 0, width: 180, height: 180))],
            chains: [], connections: [], ink: [])),
        makeBoard("child", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )

    let sizes = cardPreviewSizes(contents)

    let child = CardPreview(boardID: Document.ID(rawValue: "child"), color: nil)
    // Each card shows a window 1440 px wide: the first at 0.25, 360 tall, the second at 0.125,
    // 1440 tall.
    #expect(sizes[child] == Size(width: 1440, height: 1440))
  }

  @Test func sizeAWideCardsPreviewAt08() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: nil,
            cards: [makeCard("child", frame: Rect(x: 0, y: 0, width: 1600, height: 400))],
            chains: [], connections: [], ink: [])),
        makeBoard("child", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )

    let sizes = cardPreviewSizes(contents)

    let child = CardPreview(boardID: Document.ID(rawValue: "child"), color: nil)
    #expect(sizes[child] == Size(width: 2000, height: 500))
  }

  @Test func sizeNoPreviewForAnEmptyBoard() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["child"]), makeBoard("child")],
      users: [:]
    )

    let sizes = cardPreviewSizes(contents)

    #expect(sizes.isEmpty)
  }
}
