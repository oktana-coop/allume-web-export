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

/// Each board's preview as the cards that show it do, on their color, to be drawn as images for
/// them.
package func renderBoardPreviews(
  _ contents: Contents, favicons: [String: Asset], images: [String: ImageFiles]
) -> [CardPreview: BoardPreview] {
  let layouts = layouts(in: contents)
  let shown = contents.hierarchy.boardIDs.compactMap { boardID in contents.board(boardID) }
    .flatMap { board in
      board.cards.compactMap { card -> (preview: CardPreview, board: Document.Board)? in
        guard case .board(let child)? = contents.document(card.documentID) else {
          return nil
        }
        return (CardPreview(boardID: child.id, color: card.color), child)
      }
    }
    .uniqued(on: \.preview)

  return Dictionary(
    uniqueKeysWithValues: shown.map { preview, board in
      (
        preview,
        renderPreview(
          of: board, color: preview.color, contents: contents, layouts: layouts,
          favicons: favicons, images: images)
      )
    })
}

/// The root board's preview, to be drawn as an image. Its images are those of the views, but for
/// the root's own, which show at nearly their size, larger than their thumbnails.
package func renderRootPreview(
  _ contents: Contents, favicons: [String: Asset], images: [String: ImageFiles]
) -> BoardPreview {
  guard let root = contents.board(contents.rootID) else {
    preconditionFailure("The contents' root is always a board.")
  }

  let rootImageNames = Set(
    root.cards.compactMap { card -> String? in
      guard case .image(let image)? = contents.document(card.documentID) else {
        return nil
      }
      return image.file.name
    })
  let previewImages = Dictionary(
    uniqueKeysWithValues: images.map { name, files in
      (name, rootImageNames.contains(name) ? ImageFiles(image: files.image, thumbnail: nil) : files)
    })

  return renderPreview(
    of: root, color: nil, contents: contents, layouts: layouts(in: contents), favicons: favicons,
    images: previewImages)
}

private func renderPreview(
  of board: Document.Board, color: CardColor?, contents: Contents,
  layouts: [Document.ID: BoardLayout], favicons: [String: Asset], images: [String: ImageFiles]
) -> BoardPreview {
  let preview = drawBoardPreview(
    of: board, color: color, contents: contents, layouts: layouts, favicons: favicons,
    images: images)

  return BoardPreview(
    html: preview.rendered(resolving: \.text), files: preview.files.uniqued(on: \.path),
    size: previewSize(of: (layouts[board.id] ?? layout(of: board)).contentBounds))
}
