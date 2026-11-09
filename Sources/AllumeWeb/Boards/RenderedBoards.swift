import AllumeWebModels
import AllumeWebRendering
import Foundation

/// The published boards as rendered: their index, each board's view, with its references kept,
/// and the files the views refer to. `embed` writes them to a folder, and the site is made from
/// them.
package struct RenderedBoards: Sendable {
  package let index: BoardsIndex
  /// In breadth-first order from the root.
  package let views: [BoardView]
  package let files: [PublishedFile]
}

/// The boards published from the export, rendered. The favicons are each link host's icon, and
/// the thumbnails, which previews show, each image's by its file name.
package func renderedBoards(
  for contents: Contents, favicons: [String: Asset], thumbnails: [String: Asset]
) -> RenderedBoards {
  let (views, files) = renderBoards(contents, favicons: favicons, thumbnails: thumbnails)

  return RenderedBoards(index: boardsIndex(for: contents), views: views, files: files)
}

/// The files the views refer to, under `files/`.
func referredFiles(of boards: RenderedBoards) -> [OutputFile] {
  boards.files.map { file in OutputFile(path: "files/\(file.path)", source: .copy(file.source)) }
}

/// The viewer's style sheet and script, for pages to include.
func viewerFiles() -> [OutputFile] {
  ["allume.css", "allume.js"].map { name in
    OutputFile(path: name, source: .copy(viewerFile(name)))
  }
}

private func viewerFile(_ name: String) -> URL {
  guard let url = Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Viewer")
  else {
    preconditionFailure("The package's resources have no Viewer/\(name).")
  }

  return url
}
