import AllumeWebModels
import Testing

@testable import AllumeWeb

@Suite struct StandalonePageTests {
  @Test func makesTheViewItsMainContentWithTheViewersStyleSheetAndScript() {
    let page = standalonePage(
      title: "Functional | Languages", view: #"<div class="allume"></div>"#)

    #expect(
      page == #"""
        <!doctype html>
        <html lang="en">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Functional | Languages</title>
        <link rel="stylesheet" href="viewer.css">
        <style>
        body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; }
        main { height: 100dvh; }
        </style>
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

  @Test func escapesTheTitle() {
    let page = standalonePage(title: "Tom & Jerry", view: "")

    #expect(page.contains("<title>Tom &amp; Jerry</title>"))
  }

  @Test func titlesThePageWithTheBoardsLabelThenTheRoots() throws {
    let contents = try makeContents(with: [makeBoard("functional", label: "Functional")])

    let titles = [
      pageTitle(of: Document.ID(rawValue: "root"), in: contents),
      pageTitle(of: Document.ID(rawValue: "functional"), in: contents),
    ]

    #expect(titles == ["Languages", "Functional | Languages"])
  }
}
