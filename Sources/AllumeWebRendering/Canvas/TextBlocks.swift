import AllumeWebModels

func drawTextBlock(_ block: TextBlock, interactive: Bool) -> HTML {
  let style =
    "left:\(number: block.position.x)px;top:\(number: block.position.y)px;"
    + "max-width:\(number: block.maxWidth)px"

  return .element(
    "div", ["class": "allume-text-block", "style": .text(style)],
    block.paragraphs.map(drawParagraph) + (interactive ? [copyButton] : []))
}

/// A heading is an `h3`. An empty paragraph keeps its line with a break, and has nothing to
/// highlight.
private func drawParagraph(_ paragraph: TextBlock.Paragraph) -> HTML {
  let element =
    switch paragraph.role {
    case .body: "p"
    case .heading: "h3"
    }
  guard !paragraph.text.isEmpty else {
    return .element(element, [:], [.element("br", [:], [])])
  }

  return .element(
    element, ["data-allume-color": paragraph.highlight.map { color in .text(color.rawValue) }],
    [.text(paragraph.text)])
}
