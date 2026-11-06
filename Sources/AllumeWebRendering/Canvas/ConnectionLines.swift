import AllumeWebModels

/// The board's connection lines in one SVG, or nil when it has none. The SVG starts at the board's
/// origin, like the cards, so it reaches to the far edges of the content bounds.
func drawConnectionLines(_ layout: BoardLayout) -> HTML? {
  guard !layout.connectionLines.isEmpty else {
    return nil
  }

  let lines = layout.connectionLines.map { line -> HTML in
    .element(
      "line",
      [
        "x1": .text("\(number: line.from.x)"), "y1": .text("\(number: line.from.y)"),
        "x2": .text("\(number: line.to.x)"), "y2": .text("\(number: line.to.y)"),
      ], [])
  }

  return .element(
    "svg",
    [
      "class": "connections", "width": .text("\(number: layout.contentBounds.maxX)"),
      "height": .text("\(number: layout.contentBounds.maxY)"), "aria-hidden": "true",
    ], lines)
}
