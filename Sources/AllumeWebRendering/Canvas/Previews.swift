import AllumeWebModels

/// The board's preview images, one for each appearance, at the preview scale of the card in the
/// frame, which crops them.
func drawPreviewImages(_ files: PreviewImageFiles, in frame: Rect) -> [HTML] {
  let scale = previewScale(in: frame)
  let style =
    "width:\(number: files.size.width * scale)px;height:\(number: files.size.height * scale)px"

  return [("light", files.light), ("dark", files.dark)].map { appearance, image in
    .element(
      "img",
      [
        "class": .text("allume-preview-image allume-preview-\(appearance)"),
        "src": .file(PublishedFile(path: "previews/\(image.name)", source: image.url)),
        "alt": "",
        "style": .text(style),
        "loading": "lazy",
        "decoding": "async",
        "draggable": "false",
      ], [])
  }
}

/// The board's preview on a page of its own, to be drawn as an image: the board as its own page
/// shows it, at its full size from the top left, its board cards showing their previews' images,
/// on a panel of the size in the color, if any, with room above it for titles.
func drawBoardPreview(
  of board: Document.Board, color: CardColor?, size: Size, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset], images: [String: ImageFiles],
  previews: [CardPreview: PreviewImageFiles]
) -> HTML {
  let preview = HTML.element(
    "div",
    [
      "class": "allume-preview",
      "style": .text("transform:translateY(\(number: fitTopPadding)px)"),
    ],
    separatedByLineBreaks(
      drawBoardContents(
        board, depth: 1, contents: contents, layouts: layouts, favicons: favicons,
        images: images, previews: previews)))

  return .element(
    "div",
    [
      "class": "allume allume-board-preview",
      "data-allume-color": color.map { color in .text(color.rawValue) },
      "style": .text("width:\(number: size.width)px;height:\(number: size.height)px"),
    ],
    onLinesOfTheirOwn([Icon.sprite, preview]))
}

/// A board's whole preview at the board's size: its contents, with room above them for titles and
/// the margin at the board's origin repeated beyond them.
func previewSize(of contentBounds: Rect) -> Size {
  Size(
    width: contentBounds.maxX + contentBounds.x,
    height: fitTopPadding + contentBounds.maxY + contentBounds.y)
}
