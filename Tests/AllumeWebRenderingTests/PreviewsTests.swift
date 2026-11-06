import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct PreviewsTests {
  @Test func fillTheCardAtTheirScale() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["child"]),
        .board(
          Document.Board(
            id: Document.ID(rawValue: "child"), label: nil,
            cards: [makeCard("note", frame: Rect(x: 100, y: 50, width: 200, height: 100))],
            chains: [], connections: [], ink: [])),
        makeNote("note"),
      ],
      users: [:]
    )
    let child = try #require(contents.board(Document.ID(rawValue: "child")))

    let html = drawPreview(
      of: child, in: Rect(x: 0, y: 0, width: 200, height: 100), depth: 1, contents: contents,
      layouts: layouts(in: contents), favicons: [:]
    )?
    .rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <div class="preview" style="width:400px;height:200px;transform:scale(0.5)">
            <div class="card card--text" data-doc="note"
              style="left:100px;top:50px;width:200px;height:100px;z-index:0">
              <div class="body">A note</div>
            </div>
          </div>
          """#))
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
    let child = try #require(contents.board(Document.ID(rawValue: "child")))

    let html = try #require(
      drawPreview(
        of: child, in: Rect(x: 0, y: 0, width: 200, height: 100), depth: 1, contents: contents,
        layouts: layouts(in: contents), favicons: [:]
      )?
      .rendered(resolving: describe))

    #expect(html.contains(#"data-doc="link""#) && html.contains(#"<div class="comment""#))
    #expect(!html.contains("<button"))
    #expect(!html.contains(" id="))
    #expect(!html.contains("<a "))
  }

  @Test func nestUpToThreeLevels() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["a"]), makeBoard("a", cards: ["b"]),
        makeBoard("b", cards: ["c"]), makeBoard("c", cards: ["d"]), makeBoard("d"),
      ],
      users: [:]
    )

    let html = try #require(drawnContents(of: "root", in: contents))

    #expect(html.components(separatedBy: #"<div class="preview""#).count - 1 == 3)
    #expect(html.contains(#"<div class="body panel"></div>"#))
  }
}
