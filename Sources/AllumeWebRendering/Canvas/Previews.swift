import AllumeWebModels

/// Previews nest up to three levels. A board card any deeper has an empty panel.
let maxPreviewDepth = 3

/// The board's contents at the depth, scaled to fit the frame, or nil past the deepest preview.
func drawPreview(
  of board: Document.Board, in frame: Rect, depth: Int, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset],
  thumbnails: [String: Asset]
) -> HTML? {
  guard depth <= maxPreviewDepth else {
    return nil
  }

  let contentBounds = (layouts[board.id] ?? layout(of: board)).contentBounds
  let scale = previewScale(of: contentBounds, in: frame)
  // Drawn larger than the frame by the scale, so that once scaled it fills the frame.
  let style =
    "width:\(number: frame.width / scale)px;height:\(number: frame.height / scale)px;"
    + "transform:scale(\(number: scale))"

  return .element(
    "div", ["class": "allume-preview", "style": .text(style)],
    separatedByLineBreaks(
      drawBoardContents(
        board, depth: depth, contents: contents, layouts: layouts, favicons: favicons,
        thumbnails: thumbnails)))
}
