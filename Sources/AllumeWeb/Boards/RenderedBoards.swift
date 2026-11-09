import AllumeWebModels
import AllumeWebRendering
import Foundation

/// The published boards as rendered: their index, each board's view, with its references kept,
/// the files the views refer to, and the root board's preview. `embed` writes them to a folder,
/// and the site is made from them.
package struct RenderedBoards: Sendable {
  package let index: BoardsIndex
  /// In breadth-first order from the root.
  package let views: [BoardView]
  package let files: [PublishedFile]
  package let preview: BoardPreview
}

/// The boards published from the export, rendered. The favicons are each link host's icon, and
/// the images each image's files, by its file name.
package func renderedBoards(
  for contents: Contents, favicons: [String: Asset], images: [String: ImageFiles]
) -> RenderedBoards {
  let (views, files) = renderBoards(contents, favicons: favicons, images: images)
  let preview = renderRootPreview(contents, favicons: favicons, images: images)

  return RenderedBoards(
    index: boardsIndex(for: contents), views: views, files: files, preview: preview)
}

/// The files, under `files/`.
func referredFiles(_ files: [PublishedFile]) -> [OutputFile] {
  files.map { file in OutputFile(path: "files/\(file.path)", source: .copy(file.source)) }
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
