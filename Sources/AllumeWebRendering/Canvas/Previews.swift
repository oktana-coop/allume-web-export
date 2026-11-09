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

/// The board's preview as an element of its own, for a page to show: its contents as a board
/// card's preview draws them, at their full size, with room above them for titles and the margin
/// at the board's origin repeated beyond them. It keeps the board's proportions, and the viewer
/// scales its contents to its width. It's hidden from screen readers, being a picture of the
/// board.
func drawBoardPreview(
  of board: Document.Board, contents: Contents, layouts: [Document.ID: BoardLayout],
  favicons: [String: Asset], images: [String: ImageFiles]
) -> HTML {
  let contentBounds = (layouts[board.id] ?? layout(of: board)).contentBounds
  let width = contentBounds.maxX + contentBounds.x
  let height = fitTopPadding + contentBounds.maxY + contentBounds.y
  let style =
    "width:\(number: width)px;height:\(number: height)px;"
    + "transform:scale(var(--allume-preview-scale, 1)) translateY(\(number: fitTopPadding)px)"

  let preview = HTML.element(
    "div", ["class": "allume-preview", "style": .text(style)],
    separatedByLineBreaks(
      drawBoardContents(
        board, depth: 1, contents: contents, layouts: layouts, favicons: favicons,
        images: images)))

  return .element(
    "div",
    [
      "class": "allume allume-board-preview", "aria-hidden": "true",
      "style": .text("aspect-ratio:\(number: width)/\(number: height)"),
    ],
    onLinesOfTheirOwn([Icon.sprite, preview]))
}
