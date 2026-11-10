import AllumeWebModels

/// A board's view, whose links and images are references, for its output to resolve to URLs.
package struct BoardView: Equatable, Sendable {
  package let boardID: Document.ID
  package let html: String
}

/// A board's preview, to be drawn as an image, whose images are references, the files it refers
/// to, and its size at the board's size, in CSS pixels.
package struct BoardPreview: Equatable, Sendable {
  package let html: String
  package let files: [PublishedFile]
  package let size: Size
}

/// Each board's view, in breadth-first order from the root, and the files the views refer to,
/// once each, in the order they're first referred to. An image's files, found by its file name,
/// are those publishing made for it: a copy browsers can show, and a thumbnail for previews. A
/// board card shows the preview images publishing drew for its board in its color.
package func renderBoards(
  _ contents: Contents, favicons: [String: Asset],
  images: [String: ImageFiles], previews: [CardPreview: PreviewImageFiles]
)
  -> (views: [BoardView], files: [PublishedFile])
{
  let boardLayouts = layouts(in: contents)
  let drawn = contents.hierarchy.boardIDs.compactMap { boardID in
    contents.board(boardID).map { board in
      (
        boardID: boardID,
        view: drawBoardView(
          board, contents: contents, layouts: boardLayouts, favicons: favicons,
          images: images, previews: previews)
      )
    }
  }

  let views = drawn.map { boardID, view in
    BoardView(boardID: boardID, html: view.rendered(resolving: \.text))
  }
  let files = drawn.flatMap { _, view in view.files }.uniqued(on: \.path)
  return (views, files)
}

/// The size of each board's preview as the cards that show it do, on their color: the part of the
/// board the largest of them shows, from its top left. An empty board has none.
package func cardPreviewSizes(_ contents: Contents) -> [CardPreview: Size] {
  let layouts = layouts(in: contents)
  let cards = contents.hierarchy.boardIDs.compactMap { boardID in contents.board(boardID) }
    .flatMap { board in
      board.cards.compactMap { card -> (preview: CardPreview, frame: Rect)? in
        guard case .board(let child)? = contents.document(card.documentID),
          hasContents((layouts[child.id] ?? layout(of: child)).contentBounds)
        else {
          return nil
        }
        return (CardPreview(boardID: child.id, color: card.color), card.frame)
      }
    }

  return Dictionary(grouping: cards, by: \.preview).mapValues { cards in
    let shown = cards.map { card in
      Size(
        width: card.frame.width / previewScale(in: card.frame),
        height: card.frame.height / previewScale(in: card.frame))
    }
    return Size(
      width: shown.map(\.width).reduce(0, max), height: shown.map(\.height).reduce(0, max))
  }
}

private func hasContents(_ contentBounds: Rect) -> Bool {
  contentBounds.maxX > 0 && contentBounds.maxY > 0
}

/// The board's preview as its cards show it, the part of the size, to be drawn as an image, with
/// its board cards showing the previews' images drawn so far.
package func renderCardPreview(
  _ preview: CardPreview, size: Size, contents: Contents, favicons: [String: Asset],
  images: [String: ImageFiles], previews: [CardPreview: PreviewImageFiles]
) -> BoardPreview? {
  contents.board(preview.boardID).map { board in
    renderPreview(
      of: board, color: preview.color, size: size, contents: contents,
      layouts: layouts(in: contents), favicons: favicons, images: images, previews: previews)
  }
}

/// The root board's whole preview, to be drawn as an image, with its board cards showing their
/// previews' images.
package func renderRootPreview(
  _ contents: Contents, favicons: [String: Asset], images: [String: ImageFiles],
  previews: [CardPreview: PreviewImageFiles]
) -> BoardPreview {
  guard let root = contents.board(contents.rootID) else {
    preconditionFailure("The contents' root is always a board.")
  }

  let layouts = layouts(in: contents)
  return renderPreview(
    of: root, color: nil,
    size: previewSize(of: (layouts[root.id] ?? layout(of: root)).contentBounds),
    contents: contents, layouts: layouts, favicons: favicons, images: images, previews: previews)
}

/// A preview's page shows its board at its full size, so its images are the originals rather than
/// their thumbnails.
private func renderPreview(
  of board: Document.Board, color: CardColor?, size: Size, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset], images: [String: ImageFiles],
  previews: [CardPreview: PreviewImageFiles]
) -> BoardPreview {
  let originals = images.mapValues { files in ImageFiles(image: files.image, thumbnail: nil) }
  let preview = drawBoardPreview(
    of: board, color: color, size: size, contents: contents, layouts: layouts,
    favicons: favicons, images: originals, previews: previews)

  return BoardPreview(
    html: preview.rendered(resolving: \.text), files: preview.files.uniqued(on: \.path),
    size: size)
}
