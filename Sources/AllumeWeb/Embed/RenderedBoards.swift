import AllumeWebModels
import AllumeWebRendering

/// The published boards as rendered: their index, each board's view, with its references kept,
/// and the files the views refer to. `embed` writes them to a folder, and the site is made from
/// them.
package struct RenderedBoards: Sendable {
  package let index: BoardsIndex
  /// In breadth-first order from the root.
  package let views: [BoardView]
  package let files: [PublishedFile]
}

/// The boards published from the export, rendered. The favicons are each link host's icon.
package func renderedBoards(for contents: Contents, favicons: [String: Asset]) -> RenderedBoards {
  let (views, files) = renderBoards(contents, favicons: favicons)

  return RenderedBoards(index: boardsIndex(for: contents), views: views, files: files)
}
