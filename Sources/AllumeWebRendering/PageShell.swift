import AllumeWebModels

/// A standalone page around a board's view, as its main content, with the viewer's style sheet
/// and script.
func drawPageShell(title: String, view: HTML) -> [HTML] {
  let head = HTML.element(
    "head", [:],
    onLinesOfTheirOwn([
      .element("meta", ["charset": "utf-8"], []),
      .element("meta", ["name": "viewport", "content": "width=device-width, initial-scale=1"], []),
      .element("title", [:], [.text(title)]),
      .element("link", ["rel": "stylesheet", "href": "viewer.css"], []),
      .element("style", [:], [.text(pageStyle)]),
    ]))
  let body = HTML.element(
    "body", [:],
    onLinesOfTheirOwn([
      .element("main", [:], onLinesOfTheirOwn([view])),
      .element("script", ["src": "viewer.js"], []),
    ]))

  return [
    .doctype, .text("\n"), .element("html", ["lang": "en"], onLinesOfTheirOwn([head, body])),
    .text("\n"),
  ]
}

// The view takes the page's font. The family names are unquoted, since a style element's text
// isn't unescaped.
private let pageStyle =
  "body { margin: 0; font-family: system-ui, -apple-system, Segoe UI, sans-serif; }"

/// The board's label, then the root's, except on the root's own page.
func pageTitle(of board: Document.Board, in contents: Contents) -> String {
  board.id == contents.rootID
    ? board.displayLabel
    : "\(board.displayLabel) | \(contents.board(contents.rootID)?.displayLabel ?? "")"
}
