import AllumeWebModels
import Testing

@testable import AllumeWebRendering

@Suite struct PageShellTests {
  @Test func makesTheViewItsMainContentWithTheViewersStyleSheetAndScript() {
    let view = HTML.element("div", ["class": "allume"], [])

    let html = drawPageShell(title: "Functional | Languages", view: view)
      .map { node in node.rendered(resolving: describe) }.joined()

    #expect(
      html == #"""
        <!doctype html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Functional | Languages</title>
        <link rel="stylesheet" href="viewer.css">
        <style>body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, sans-serif; }</style>
        </head>
        <body>
        <main>
        <div class="allume"></div>
        </main>
        <script src="viewer.js"></script>
        </body>
        </html>

        """#)
  }

  @Test func titlesThePageWithTheBoardsLabelThenTheRoots() throws {
    let contents = try Contents(
      rootID: Document.ID(rawValue: "root"),
      documents: [
        makeBoard("root", label: "Languages", cards: ["functional"]),
        makeBoard("functional", label: "Functional"),
      ],
      users: [:]
    )
    let root = try #require(contents.board(Document.ID(rawValue: "root")))
    let functional = try #require(contents.board(Document.ID(rawValue: "functional")))

    let titles = [pageTitle(of: root, in: contents), pageTitle(of: functional, in: contents)]

    #expect(titles == ["Languages", "Functional | Languages"])
  }
}
