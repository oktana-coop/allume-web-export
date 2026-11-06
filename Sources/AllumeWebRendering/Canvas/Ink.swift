import AllumeWebModels

/// Ink starts at the board's origin, so only its size is set.
func drawInk(_ ink: Ink) -> HTML {
  .element(
    "img",
    [
      "class": "ink",
      "src": .reference(.file(PublishedFile(path: ink.file.name, source: ink.file.url))),
      "alt": "",
      "draggable": "false",
      "style": .text("width:\(number: ink.size.width)px;height:\(number: ink.size.height)px"),
    ], [])
}
