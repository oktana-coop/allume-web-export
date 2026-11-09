import AllumeWebRendering

/// Every file of the folder a site embeds the board views from: `boards.json`, each board's view
/// under `boards/`, with its references resolved from the patterns or kept for the site to
/// resolve, the files the views refer to, under `files/`, and the viewer's style sheet and script.
package func embedFiles(from boards: RenderedBoards, urlPatterns: URLPatterns) -> [OutputFile] {
  let index = OutputFile(path: "boards.json", source: .text(boardsJSON(boards.index) + "\n"))
  let views = boards.views.map { view in
    let html = resolvingReferences(in: view, urlPatterns: urlPatterns, index: boards.index)
    return OutputFile(path: viewPath(of: view.boardID), source: .text(html + "\n"))
  }

  return [index] + views + referredFiles(of: boards) + viewerFiles()
}
