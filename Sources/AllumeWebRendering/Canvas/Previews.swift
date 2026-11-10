import AllumeWebModels

/// Previews nest up to three levels. A board card any deeper has an empty panel.
let maxPreviewDepth = 3

/// The board's contents at the depth, scaled to fit the frame, or nil past the deepest preview.
func drawPreview(
  of board: Document.Board, in frame: Rect, depth: Int, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset],
  images: [String: ImageFiles]
) -> HTML? {
  guard depth <= maxPreviewDepth else {
    return nil
  }

  let contentBounds = (layouts[board.id] ?? layout(of: board)).contentBounds
  let scale = previewScale(of: contentBounds, in: frame)
  // Drawn larger than the frame by the scale, so that once scaled it fills the frame.
  let style =
    "width:\(number: frame.width / scale)px;height:\(number: frame.height / scale)px;"
    + "transform:scale(\(number: scale)) translateY(\(number: fitTopPadding)px)"

  return .element(
    "div", ["class": "allume-preview", "style": .text(style)],
    separatedByLineBreaks(
      drawBoardContents(
        board, depth: depth, contents: contents, layouts: layouts, favicons: favicons,
        images: images)))
}

/// The board's preview on a page of its own, to be drawn as an image: its contents as a board
/// card's preview draws them, at their full size, on a panel with room above them for titles and
/// the margin at the board's origin repeated beyond them.
func drawBoardPreview(
  of board: Document.Board, contents: Contents, layouts: [Document.ID: BoardLayout],
  favicons: [String: Asset], images: [String: ImageFiles]
) -> HTML {
  let size = previewSize(of: (layouts[board.id] ?? layout(of: board)).contentBounds)
  let preview = HTML.element(
    "div",
    [
      "class": "allume-preview",
      "style": .text("transform:translateY(\(number: fitTopPadding)px)"),
    ],
    separatedByLineBreaks(
      drawBoardContents(
        board, depth: 1, contents: contents, layouts: layouts, favicons: favicons,
        images: images)))

  return .element(
    "div",
    [
      "class": "allume allume-board-preview",
      "style": .text("width:\(number: size.width)px;height:\(number: size.height)px"),
    ],
    onLinesOfTheirOwn([Icon.sprite, preview]))
}

/// A board's preview at the board's size: its contents, with room above them for titles and the
/// margin at the board's origin repeated beyond them.
func previewSize(of contentBounds: Rect) -> Size {
  Size(
    width: contentBounds.maxX + contentBounds.x,
    height: fitTopPadding + contentBounds.maxY + contentBounds.y)
}
