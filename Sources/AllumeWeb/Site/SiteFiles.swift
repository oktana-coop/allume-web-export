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

/// Every file of the site: a page for each board, the files the pages refer to, under
/// `files/`, and the viewer's style sheet and script. The favicons are each link host's icon.
public func siteFiles(for contents: Contents, favicons: [String: Asset]) -> [SiteFile] {
  let (views, files) = renderBoards(contents, favicons: favicons)
  let urls = siteURLs(for: contents)

  // The site's URLs list every published board, which are all a page can refer to.
  guard
    let sitePages = try? views.map({ view throws(UnknownBoardError) in
      try sitePage(of: view, contents: contents, urls: urls)
    })
  else {
    preconditionFailure("A page refers to a board the site doesn't publish.")
  }

  return sitePages
    + files.map { file in SiteFile(path: "files/\(file.path)", source: .copy(file.source)) }
    + ["viewer.css", "viewer.js"].map { name in
      SiteFile(path: name, source: .copy(viewerFile(name)))
    }
}

/// The view's standalone page, at its board's URL, with each reference filled with the site's URL.
private func sitePage(
  of view: BoardView, contents: Contents, urls: ReferenceURLs
) throws(UnknownBoardError) -> SiteFile {
  let page = standalonePage(title: pageTitle(of: view.boardID, in: contents), view: view.html)
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
