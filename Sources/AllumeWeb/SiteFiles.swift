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

/// Every file of the standalone site: a page for each board, the files the pages refer to, under
/// `files/`, and the viewer's style sheet and script.
public func siteFiles(for contents: Contents) -> [SiteFile] {
  let (pages, files) = renderBoards(contents, favicons: [:])

  return pages.map { page in SiteFile(path: page.path, source: .text(page.html)) }
    + files.map { file in SiteFile(path: "files/\(file.path)", source: .copy(file.source)) }
    + ["viewer.css", "viewer.js"].map { name in
      SiteFile(path: name, source: .copy(viewerFile(name)))
    }
}

private func viewerFile(_ name: String) -> URL {
  guard let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Viewer")
  else {
    preconditionFailure("The package's resources have no Viewer/\(name).")
  }

  return url
}
