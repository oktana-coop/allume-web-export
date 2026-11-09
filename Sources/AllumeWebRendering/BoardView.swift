import AllumeWebModels

/// A board's view, as one element: the icons it draws, then its breadcrumbs and zoom controls
/// above its canvas.
func drawBoardView(
  _ board: Document.Board, contents: Contents, layouts: [Document.ID: BoardLayout],
  favicons: [String: Asset]
) -> HTML {
  let bounds = (layouts[board.id] ?? layout(of: board)).contentBounds
  let canvas = HTML.element(
    "div",
    [
      "class": "allume-canvas",
      "data-allume-bounds": .text(
        "\(number: bounds.x),\(number: bounds.y),\(number: bounds.maxX),\(number: bounds.maxY)"),
      "style": .text(
        "width:\(number: bounds.maxX + canvasMargin)px;height:\(number: bounds.maxY + canvasMargin)px"
      ),
    ],
    onLinesOfTheirOwn(
      drawBoardContents(
        board, depth: 0, contents: contents, layouts: layouts, favicons: favicons)))

  let bar = HTML.element(
    "header", ["class": "allume-bar"],
    onLinesOfTheirOwn([drawBreadcrumbs(of: board, contents: contents), zoomControls]))
  let viewport = HTML.element("div", ["class": "allume-viewport"], onLinesOfTheirOwn([canvas]))

  return .element(
    "div", ["class": "allume", "data-allume-board": .text(board.id.rawValue)],
    onLinesOfTheirOwn([Icon.sprite, bar, viewport]))
}

/// Room beyond the contents' far edges, so that the canvas scrolls past them without JavaScript.
private let canvasMargin = 400.0

private var zoomControls: HTML {
  .element(
    "div", ["class": "allume-zoom", "role": "toolbar", "aria-label": "Zoom"],
    onLinesOfTheirOwn([
      .element(
        "button", ["type": "button", "data-allume-zoom": "out", "aria-label": "Zoom out"],
        [.text("−")]),
      .element("output", ["class": "allume-zoom-level"], [.text("100%")]),
      .element(
        "button", ["type": "button", "data-allume-zoom": "in", "aria-label": "Zoom in"],
        [.text("+")]),
      .element("button", ["type": "button", "data-allume-zoom": "home"], [.text("Fit")]),
    ]))
}
