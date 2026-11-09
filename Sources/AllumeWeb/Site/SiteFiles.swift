import AllumeWebModels
import AllumeWebRendering
import Foundation

/// Every file of the standalone site, from the rendered boards alone: a page for each board's
/// view, their files under `files/`, and the viewer's style sheet and script.
package func siteFiles(from boards: RenderedBoards) -> [OutputFile] {
  let urls = siteURLs(for: boards.index)

  // The site's URLs list every published board, which are all a page can refer to.
  guard
    let sitePages = try? boards.views.map({ view throws(UnknownBoardError) in
      try sitePage(of: view, index: boards.index, urls: urls)
    })
  else {
    preconditionFailure("A page refers to a board the site doesn't publish.")
  }

  return sitePages + referredFiles(of: boards) + viewerFiles()
}

/// The view's standalone page, at its board's URL, with each reference resolved to the site's URL.
private func sitePage(
  of view: BoardView, index: BoardsIndex, urls: ReferenceURLs
) throws(UnknownBoardError) -> OutputFile {
  let page = standalonePage(title: pageTitle(of: view.boardID, in: index), view: view.html)
  let html = try resolvingReferences(in: page) { reference throws(UnknownBoardError) in
    try reference.url(in: urls)
  }

  return OutputFile(
    path: try BoardReference(boardID: view.boardID).url(in: urls), source: .text(html))
}
