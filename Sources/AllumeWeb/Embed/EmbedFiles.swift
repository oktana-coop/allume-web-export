import AllumeWebImages
import AllumeWebRendering

/// Every file of the folder a site embeds the board views from: `boards.json`, each board's view
/// under `boards/`, with its references resolved from the patterns or kept for the site to
/// resolve, the exported board's preview images when there are any, the files the views refer to,
/// under `files/`, and the viewer's style sheet and script.
package func embedFiles(
  from boards: RenderedBoards, urlPatterns: URLPatterns, previewImages: PreviewImages?
) -> [OutputFile] {
  let preview = previewImages.map { images in
    (
      light: imageFile(images.light, named: "preview-light"),
      dark: imageFile(images.dark, named: "preview-dark")
    )
  }
  let index = BoardsIndex(
    root: boards.index.root, boards: boards.index.boards,
    preview: preview.map { files in
      BoardsIndex.Preview(light: files.light.path, dark: files.dark.path)
    })

  let indexFile = OutputFile(path: "boards.json", source: .text(boardsJSON(index) + "\n"))
  let views = boards.views.map { view in
    let html = resolvingReferences(in: view.html, urlPatterns: urlPatterns, index: boards.index)
    return OutputFile(path: viewPath(of: view.boardID), source: .text(html + "\n"))
  }
  let previewFiles = preview.map { files in [files.light, files.dark] } ?? []

  return [indexFile] + views + previewFiles + referredFiles(boards.files) + viewerFiles()
}

/// The image as a file named after its format, e.g. `preview-light.jpg`.
private func imageFile(_ image: WebImage, named name: String) -> OutputFile {
  OutputFile(path: "\(name).\(image.format.fileExtension)", source: .data(image.data))
}
