import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct BoardViewTests {
  @Test func holdsItsIconsThenItsBreadcrumbsAndZoomControlsAboveItsCanvas() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        .board(
          Document.Board(
            id: Document.ID(rawValue: "root"), label: "Languages", cards: [], chains: [],
            connections: [],
            ink: [Ink(file: makeAsset("root_ink.svg"), size: Size(width: 200, height: 100))]))
      ],
      users: [:]
    )
    let root = try #require(contents.board(Document.ID(rawValue: "root")))
    let sprite = Icon.sprite.rendered(resolving: describe)
    let ink = markup(
      #"""
      <img class="allume-ink" src="file:root_ink.svg" alt="" draggable="false"
        style="width:200px;height:100px">
      """#)

    let html = drawnView(of: root, in: contents)

    #expect(
      html == #"""
        <div class="allume" data-allume-board="root">
        \#(sprite)
        <header class="allume-bar">
        <nav class="allume-breadcrumbs" aria-label="Breadcrumbs"><h1><span>Languages</span></h1></nav>
        <div class="allume-zoom" role="toolbar" aria-label="Zoom">
        <button type="button" data-allume-zoom="out" aria-label="Zoom out">−</button>
        <output class="allume-zoom-level">100%</output>
        <button type="button" data-allume-zoom="in" aria-label="Zoom in">+</button>
        <button type="button" data-allume-zoom="home">Fit</button>
        </div>
        </header>
        <div class="allume-viewport">
        <div class="allume-canvas" data-allume-bounds="0,0,200,100" style="width:600px;height:500px">
        \#(ink)
        </div>
        </div>
        </div>
        """#)
  }

  @Test func makeRoomBeyondTheFarEdgesOfTheContents() throws {
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
    let root = try #require(contents.board(Document.ID(rawValue: "root")))

    let html = drawnView(of: root, in: contents)

    #expect(
      html.contains(
        markup(
          #"""
          <div class="allume-canvas" data-allume-bounds="100,50,300,150" style="width:700px;height:550px">
          """#)))
  }
}

private func drawnView(of board: Document.Board, in contents: Contents) -> String {
  drawBoardView(board, contents: contents, layouts: layouts(in: contents), favicons: [:])
    .rendered(resolving: describe)
}
