import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct BoardViewTests {
  @Test func isTheBreadcrumbsAndZoomControlsAboveTheCanvas() throws {
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
    let ink = markup(
      #"""
      <img class="ink" src="file:root_ink.svg" alt="" draggable="false"
        style="width:200px;height:100px">
      """#)

    let html = drawnView(of: root, in: contents)

    #expect(
      html == #"""
        <header class="bar">
        <nav class="crumbs" aria-label="Breadcrumbs"><h1><span>Languages</span></h1></nav>
        <div class="zoom" role="toolbar" aria-label="Zoom">
        <button type="button" data-zoom="out" aria-label="Zoom out">−</button>
        <output class="zoom-level">100%</output>
        <button type="button" data-zoom="in" aria-label="Zoom in">+</button>
        <button type="button" data-zoom="home">Fit</button>
        </div>
        </header>
        <main class="viewport">
        <div class="world" data-bounds="0,0,200,100" style="width:600px;height:500px">
        \#(ink)
        </div>
        </main>
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
          <div class="world" data-bounds="100,50,300,150" style="width:700px;height:550px">
          """#)))
  }
}

private func drawnView(of board: Document.Board, in contents: Contents) -> String {
  separatedByLineBreaks(
    drawBoardView(board, contents: contents, layouts: layouts(in: contents), favicons: [:])
  )
  .map { node in node.rendered(resolving: describe) }.joined()
}
