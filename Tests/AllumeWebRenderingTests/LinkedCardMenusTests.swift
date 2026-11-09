import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct LinkedCardMenusTests {
  @Test func listTheBoardsADocumentIsOnAndMarkTheCurrentOne() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional", "note"]),
        makeBoard("functional", label: "Functional", cards: ["note"]),
        makeNote("note"),
      ],
      users: [:]
    )

    let html = drawn("note", on: "functional", in: contents)

    #expect(
      html
        == markup(
          #"""
          <div class="allume-card allume-note-card" data-allume-doc="note" id="card-note"
            style="left:0px;top:0px;width:100px;height:100px;z-index:0">
            <div class="allume-body">A note</div>
            \#(copyButtonMarkup)
            <button type="button" class="allume-linked" popovertarget="allume-linked-note"
              aria-label="Appears in 2 boards">
              \#(iconMarkup("linked"))
            </button>
            <div popover id="allume-linked-note" class="allume-linked-menu">
              <p>Appears in 2 boards</p>
              <ul>
                <li><a href="board:root#note">Languages</a></li>
                <li><a href="board:functional#note" aria-current="true">Functional</a></li>
              </ul>
            </div>
          </div>
          """#))
  }

  @Test func areLeftOutForADocumentOnOneBoard() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [makeBoard("root", cards: ["note"]), makeNote("note")],
      users: [:]
    )

    let html = drawn("note", on: "root", in: contents)

    #expect(html?.contains("linked") == false)
  }

  @Test func areLeftOutInPreviews() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", cards: ["functional", "note"]),
        makeBoard("functional", cards: ["note"]), makeNote("note"),
      ],
      users: [:]
    )

    let html = drawn("note", on: "functional", in: contents, depth: 1)

    #expect(html?.contains("linked") == false)
  }
}
