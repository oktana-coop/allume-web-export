import AllumeWebModels

/// A board's view, whose links and images are references, for its output to resolve to URLs.
package struct BoardView: Equatable, Sendable {
  package let boardID: Document.ID
  package let html: String
}

/// Each board's view, in breadth-first order from the root, and the files the views refer to,
/// once each, in the order they're first referred to. An image's files, found by its file name,
/// are those publishing made for it: a copy browsers can show, and a thumbnail for previews.
package func renderBoards(
  _ contents: Contents, favicons: [String: Asset],
  images: [String: ImageFiles]
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
          images: images)
      )
    }
  }

  let views = drawn.map { boardID, view in
    BoardView(boardID: boardID, html: view.rendered(resolving: \.text))
  }
  let files = drawn.flatMap { _, view in view.files }.uniqued(on: \.path)
  return (views, files)
}
