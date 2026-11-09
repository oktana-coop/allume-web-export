import AllumeWebRendering

/// Every file of the folder a site embeds the board views from: `boards.json`, each board's view
/// under `boards/`, with its references kept for the site to fill, the files the views refer to,
/// under `files/`, and the viewer's style sheet and script.
package func embedFiles(from boards: RenderedBoards) -> [OutputFile] {
  let index = OutputFile(path: "boards.json", source: .text(boardsJSON(boards.index) + "\n"))
  let views = boards.views.map { view in
    OutputFile(path: viewPath(of: view.boardID), source: .text(view.html + "\n"))
  }

  return [index] + views + referredFiles(of: boards) + viewerFiles()
}
