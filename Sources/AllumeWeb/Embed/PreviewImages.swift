import AllumeWebImages
import AllumeWebRendering
import AllumeWebSnapshots
import Foundation

/// The exported board's preview, drawn as an image in each appearance.
package struct PreviewImages: Sendable {
  package let light: WebImage
  package let dark: WebImage
}

/// Twice the width of a page's widest column, which stays sharp on high-density screens.
private let imageWidth = 1600

/// The root board's preview drawn as images in light and dark, from a page made for it in a
/// temporary folder, with the viewer's style sheet and the files the preview shows. It's drawn at
/// the board's size, then scaled, as text drawn smaller than browsers' minimum font size would
/// overflow. Nil when WebKit can't draw it, or the board is empty.
func previewImages(of preview: BoardPreview, index: BoardsIndex) async -> PreviewImages? {
  guard preview.size.width > 0 && preview.size.height > 0 else {
    return nil
  }

  let folder = FileManager.default.temporaryDirectory.appending(
    path: "allume-web-export-preview-\(UUID())")
  defer { try? FileManager.default.removeItem(at: folder) }
  guard let page = try? writePreviewPage(of: preview, index: index, into: folder) else {
    return nil
  }

  let window = CGSize(width: preview.size.width, height: preview.size.height)
  guard
    let light = await snapshot(of: page, size: window, appearance: .light, width: imageWidth),
    let dark = await snapshot(of: page, size: window, appearance: .dark, width: imageWidth)
  else {
    return nil
  }

  return PreviewImages(light: light, dark: dark)
}

/// Writes the page, with the style sheet and the preview's files beside it, and returns its URL. A
/// file that can't be copied is left out, and drawn as missing.
private func writePreviewPage(of preview: BoardPreview, index: BoardsIndex, into folder: URL)
  throws -> URL
{
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  try FileManager.default.copyItem(
    at: viewerFile("allume.css"), to: folder.appending(path: "allume.css"))
  preview.files.filter { file in !leavesFolder(file.path) }.forEach { file in
    let destination = folder.appending(path: "files/\(file.path)")
    try? FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? FileManager.default.copyItem(at: file.source, to: destination)
  }

  let html = resolvingReferences(
    in: preview.html, urlPatterns: URLPatterns(files: "files"), index: index)
  let page = folder.appending(path: "preview.html")
  try Data(previewPage(showing: html).utf8).write(to: page)
  return page
}

/// A page showing the preview alone, in the system's appearance.
private func previewPage(showing preview: String) -> String {
  """
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="allume.css">
  <style>
  :root { color-scheme: light dark; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; }
  </style>
  </head>
  <body>
  \(preview)
  </body>
  </html>

  """
}
