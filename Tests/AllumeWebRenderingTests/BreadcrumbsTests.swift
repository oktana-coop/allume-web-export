import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct BreadcrumbsTests {
  @Test func areOnlyTheHeadingForTheRoot() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"), documents: [makeBoard("root", label: "Languages")],
      users: [:]
    )
    let root = try #require(contents.board(Document.ID(rawValue: "root")))

    let html = drawBreadcrumbs(of: root, contents: contents).rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <nav class="breadcrumbs" aria-label="Breadcrumbs">
            <h1><span>Languages</span></h1>
          </nav>
          """#))
  }

  @Test func linkEachPrimaryAncestorWithTheParentLast() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["paradigms"]),
        makeBoard("paradigms", label: "Paradigms", cards: ["functional"]),
        makeBoard("functional", label: "Functional"),
      ],
      users: [:]
    )
    let functional = try #require(contents.board(Document.ID(rawValue: "functional")))

    let html = drawBreadcrumbs(of: functional, contents: contents).rendered(resolving: describe)

    #expect(
      html
        == markup(
          #"""
          <nav class="breadcrumbs" aria-label="Breadcrumbs">
            <a href="board:root">Languages</a>
            <span class="separator" aria-hidden="true">/</span>
            <a href="board:paradigms" rel="up">Paradigms</a>
            <span class="separator" aria-hidden="true">/</span>
            <h1><span>Functional</span></h1>
          </nav>
          """#))
  }

  @Test func holdTheBoardsOwnLinkedCardMenuWithItsPrimaryParentMarked() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional", "ml"]),
        makeBoard("functional", label: "Functional", cards: ["haskell"]),
        makeBoard("ml", label: "ML family", cards: ["haskell"]),
        makeBoard("haskell", label: "Haskell"),
      ],
      users: [:]
    )
    let haskell = try #require(contents.board(Document.ID(rawValue: "haskell")))

    let html = drawBreadcrumbs(of: haskell, contents: contents).rendered(resolving: describe)

    #expect(
      html.hasSuffix(
        markup(
          #"""
          <h1>
            <button type="button" class="linked" popovertarget="linked-self"
              aria-label="Appears in 2 boards">
              \#(iconMarkup("linked"))
            </button>
            <div popover id="linked-self" class="linked-menu">
              <p>Appears in 2 boards</p>
              <ul>
                <li><a href="board:functional#haskell" aria-current="true">Functional</a></li>
                <li><a href="board:ml#haskell">ML family</a></li>
              </ul>
            </div>
            <span>Haskell</span>
          </h1>
          </nav>
          """#)))
  }
}
