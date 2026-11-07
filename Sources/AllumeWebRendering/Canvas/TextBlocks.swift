import AllumeWebModels

func drawTextBlock(_ block: TextBlock, interactive: Bool) -> HTML {
  let style =
    "left:\(number: block.position.x)px;top:\(number: block.position.y)px;"
    + "max-width:\(number: block.maxWidth)px"

  return .element(
    "div", ["class": "chain", "style": .text(style)],
    block.paragraphs.map(drawParagraph) + (interactive ? [copyButton] : []))
}

/// An empty paragraph keeps its line with a break, and has nothing to highlight.
private func drawParagraph(_ paragraph: TextBlock.Paragraph) -> HTML {
  guard !paragraph.text.isEmpty else {
    return .element("p", [:], [.element("br", [:], [])])
  }

  return .element(
    "p", ["data-color": paragraph.highlight.map { color in .text(color.rawValue) }],
    [.text(paragraph.text)])
}
