import AllumeWebModels

/// A board's page, whose links and images are references, for its site to fill with URLs.
package struct Page: Equatable, Sendable {
  package let boardID: Document.ID
  package let html: String
}

/// Each board as a page, in breadth-first order from the root, and the files the pages refer to,
/// once each, in the order they're first referred to.
package func renderBoards(_ contents: Contents, favicons: [String: Asset])
  -> (pages: [Page], files: [PublishedFile])
{
  let boardLayouts = layouts(in: contents)
  let trees = contents.hierarchy.boardIDs.compactMap { boardID in
    contents.board(boardID).map { board in
      (
        boardID: boardID,
        tree: drawPageShell(
          title: pageTitle(of: board, in: contents),
          view: drawBoardView(
            board, contents: contents, layouts: boardLayouts, favicons: favicons))
      )
    }
  }

  let pages = trees.map { boardID, tree in
    Page(boardID: boardID, html: tree.map { node in node.rendered(resolving: \.text) }.joined())
  }
  let files = trees.flatMap { _, tree in tree.flatMap { node in node.files } }
    .uniqued(on: \.path)
  return (pages, files)
}
