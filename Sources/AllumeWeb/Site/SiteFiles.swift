import AllumeWebModels
import AllumeWebRendering
import Foundation

/// A file of a published site.
public struct SiteFile: Equatable, Sendable {
  /// From the site's folder, e.g. `index.html` or `files/user_6e359fff.png`.
  public let path: String
  public let source: Source

  public enum Source: Equatable, Sendable {
    case text(String)
    /// A file whose bytes are copied as they are.
    case copy(URL)
  }
}

/// Every file of the standalone site, from the rendered boards alone: a page for each board's
/// view, their files under `files/`, and the viewer's style sheet and script.
package func siteFiles(from boards: RenderedBoards) -> [SiteFile] {
  let urls = siteURLs(for: boards.index)

  // The site's URLs list every published board, which are all a page can refer to.
  guard
    let sitePages = try? boards.views.map({ view throws(UnknownBoardError) in
      try sitePage(of: view, index: boards.index, urls: urls)
    })
  else {
    preconditionFailure("A page refers to a board the site doesn't publish.")
  }

  return sitePages
    + boards.files.map { file in
      SiteFile(path: "files/\(file.path)", source: .copy(file.source))
    }
    + ["allume.css", "allume.js"].map { name in
      SiteFile(path: name, source: .copy(viewerFile(name)))
    }
}

/// The view's standalone page, at its board's URL, with each reference filled with the site's URL.
private func sitePage(
  of view: BoardView, index: BoardsIndex, urls: ReferenceURLs
) throws(UnknownBoardError) -> SiteFile {
  let page = standalonePage(title: pageTitle(of: view.boardID, in: index), view: view.html)
  let html = try resolvingReferences(in: page) { reference throws(UnknownBoardError) in
    try reference.url(in: urls)
  }

  return SiteFile(
    path: try BoardReference(boardID: view.boardID).url(in: urls), source: .text(html))
}

private func viewerFile(_ name: String) -> URL {
  guard let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Viewer")
  else {
    preconditionFailure("The package's resources have no Viewer/\(name).")
  }

  return url
}
