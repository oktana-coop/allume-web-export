import AllumeWebModels

func drawTextBlock(_ block: TextBlock, interactive: Bool) -> HTML {
  let paragraphs = block.paragraphs.map { paragraph -> HTML in
    // An empty paragraph keeps its line with a break, and has nothing to highlight.
    paragraph.text.isEmpty
      ? .element("p", [:], [.element("br", [:], [])])
      : .element(
        "p", ["data-color": paragraph.highlight.map { color in .text(color.rawValue) }],
        [.text(paragraph.text)])
  }
  let style =
    "left:\(number: block.position.x)px;top:\(number: block.position.y)px;"
    + "max-width:\(number: block.maxWidth)px"

  return .element(
    "div", ["class": "chain", "style": .text(style)],
    paragraphs + (interactive ? [copyButton] : []))
}
