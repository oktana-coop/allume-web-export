import AllumeWebRendering

/// Every file of the folder a site embeds the board views from: `boards.json`, each board's view
/// under `boards/`, and the root board's preview, with their references resolved from the
/// patterns or kept for the site to resolve, the files they refer to, under `files/`, and the
/// viewer's style sheet and script.
package func embedFiles(from boards: RenderedBoards, urlPatterns: URLPatterns) -> [OutputFile] {
  let index = OutputFile(path: "boards.json", source: .text(boardsJSON(boards.index) + "\n"))
  let views = boards.views.map { view in
    let html = resolvingReferences(in: view.html, urlPatterns: urlPatterns, index: boards.index)
    return OutputFile(path: viewPath(of: view.boardID), source: .text(html + "\n"))
  }
  let previewHTML = resolvingReferences(
    in: boards.preview.html, urlPatterns: urlPatterns, index: boards.index)
  let preview = OutputFile(path: previewPath, source: .text(previewHTML + "\n"))
  let files = (boards.files + boards.preview.files).uniqued(on: \.path)

  return [index] + views + [preview] + referredFiles(files) + viewerFiles()
}
