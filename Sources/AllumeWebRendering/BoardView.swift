import AllumeWebModels

/// A board's breadcrumbs and zoom controls above its canvas.
func drawBoardView(
  _ board: Document.Board, contents: Contents, layouts: [Document.ID: BoardLayout],
  favicons: [String: Asset]
) -> [HTML] {
  let bounds = (layouts[board.id] ?? layout(of: board)).contentBounds
  let world = HTML.element(
    "div",
    [
      "class": "world",
      "data-bounds": .text(
        "\(number: bounds.x),\(number: bounds.y),\(number: bounds.maxX),\(number: bounds.maxY)"),
      "style": .text(
        "width:\(number: bounds.maxX + worldMargin)px;height:\(number: bounds.maxY + worldMargin)px"
      ),
    ],
    onLinesOfTheirOwn(
      drawBoardContents(
        board, depth: 0, contents: contents, layouts: layouts, favicons: favicons)))

  return [
    .element(
      "header", ["class": "bar"],
      onLinesOfTheirOwn([drawBreadcrumbs(of: board, contents: contents), zoomControls])),
    .element("main", ["class": "viewport"], onLinesOfTheirOwn([world])),
  ]
}

/// Room beyond the contents' far edges, so that the canvas scrolls past them without JavaScript.
private let worldMargin = 400.0

private var zoomControls: HTML {
  .element(
    "div", ["class": "zoom", "role": "toolbar", "aria-label": "Zoom"],
    onLinesOfTheirOwn([
      .element(
        "button", ["type": "button", "data-zoom": "out", "aria-label": "Zoom out"], [.text("−")]),
      .element("output", ["class": "zoom-level"], [.text("100%")]),
      .element(
        "button", ["type": "button", "data-zoom": "in", "aria-label": "Zoom in"], [.text("+")]),
      .element("button", ["type": "button", "data-zoom": "home"], [.text("Fit")]),
    ]))
}
