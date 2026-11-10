import AllumeWebImages
import AllumeWebModels
import AllumeWebRendering
import AllumeWebSnapshots
import Foundation

/// A board's preview, drawn as an image in each appearance.
package struct PreviewImages: Sendable {
  package let light: WebImage
  package let dark: WebImage
}

/// For the exported board's preview: twice the width of a page's widest column, which stays sharp
/// on high-density screens.
let rootPreviewWidth = 1600

/// How wide board cards' preview images are by default, in pixels. Board cards are mostly 400 to
/// 800 px wide, so at 100% it's sharp on standard screens, and on high-density ones for cards up to
/// 512 px wide.
public let defaultPreviewWidth = 1024

/// Board previews drawn at once, each in a web view of its own.
private let previewBatchSize = 8

/// Each board's preview drawn as images for its cards, the width in pixels, written into the
/// folder's `previews/`. A preview's page shows the previews of its board's own board cards, so
/// they're drawn a nesting level of their boards at a time, from the lowest. A board WebKit can't
/// draw has none, and a warning.
package func makePreviewImageFiles(
  of contents: Contents, favicons: [String: Asset], images: [String: ImageFiles], width: Int,
  in folder: URL
) async -> (files: [CardPreview: PreviewImageFiles], warnings: [PublishingWarning]) {
  let sizes = cardPreviewSizes(contents)
  let previewFolder = folder.appending(path: "previews")
  guard
    (try? FileManager.default.createDirectory(
      at: previewFolder, withIntermediateDirectories: true)) != nil
  else {
    return ([:], sizes.keys.map { preview in .boardPreviewNotDrawn(boardID: preview.boardID) })
  }

  let page = { (preview: CardPreview, drawn: [CardPreview: PreviewImageFiles]) in
    sizes[preview].flatMap { size in
      renderCardPreview(
        preview, size: size, contents: contents, favicons: favicons, images: images,
        previews: drawn)
    }
  }
  let levels = Dictionary(grouping: sizes.keys) { preview in
    contents.hierarchy.nestingLevel(of: preview.boardID)
  }
  .sorted { a, b in a.key < b.key }.map(\.value)

  let files = await drawn(
    levels[...], page: page, index: boardsIndex(for: contents), width: width,
    into: previewFolder, drawnSoFar: [:])
  let warnings = sizes.keys.sorted { a, b in a.fileName < b.fileName }
    .filter { preview in files[preview] == nil }
    .map { preview in PublishingWarning.boardPreviewNotDrawn(boardID: preview.boardID) }

  return (files, warnings)
}

/// The previews drawn into the folder a level at a time, each level's pages showing the previews
/// drawn by then.
private func drawn(
  _ levels: ArraySlice<[CardPreview]>,
  page: (CardPreview, [CardPreview: PreviewImageFiles]) -> BoardPreview?, index: BoardsIndex,
  width: Int, into folder: URL, drawnSoFar: [CardPreview: PreviewImageFiles]
) async -> [CardPreview: PreviewImageFiles] {
  guard let level = levels.first else {
    return drawnSoFar
  }

  let pages = level.compactMap { preview -> (key: CardPreview, value: BoardPreview)? in
    page(preview, drawnSoFar).map { page in (preview, page) }
  }
  let images = await previewImages(ofEach: pages, index: index, width: width)
  let files = pages.compactMap { preview, page -> (CardPreview, PreviewImageFiles)? in
    (images[preview] ?? nil)
      .flatMap { images in written(images, of: preview, size: page.size, into: folder) }
      .map { files in (preview, files) }
  }

  return await drawn(
    levels.dropFirst(), page: page, index: index, width: width, into: folder,
    drawnSoFar: drawnSoFar.merging(files) { first, _ in first })
}

/// Each preview drawn as images, or nil when WebKit can't draw it, a batch of previews at a time.
private func previewImages(
  ofEach previews: some Collection<(key: CardPreview, value: BoardPreview)>, index: BoardsIndex,
  width: Int
) async -> [CardPreview: PreviewImages?] {
  guard !previews.isEmpty else {
    return [:]
  }

  let batch = await withTaskGroup(of: (preview: CardPreview, images: PreviewImages?).self) {
    group in
    for (cardPreview, preview) in previews.prefix(previewBatchSize) {
      group.addTask {
        (cardPreview, await previewImages(of: preview, index: index, width: width))
      }
    }
    return await group.reduce(into: [CardPreview: PreviewImages?]()) { drawn, result in
      drawn.updateValue(result.images, forKey: result.preview)
    }
  }
  let rest = await previewImages(
    ofEach: previews.dropFirst(previewBatchSize), index: index, width: width)
  return batch.merging(rest) { first, _ in first }
}

/// The images of the part of the board of the size, written into the folder, named after the
/// preview, followed by `-light` and `-dark` and their format's extension, e.g.
/// `<board-id>-light.jpg`. Nil if either can't be.
private func written(
  _ images: PreviewImages, of preview: CardPreview, size: Size, into folder: URL
) -> PreviewImageFiles? {
  let asset = { (image: WebImage, appearance: String) -> Asset? in
    let name = "\(preview.fileName)-\(appearance).\(image.format.fileExtension)"
    let file = folder.appending(path: name)
    return (try? image.data.write(to: file)).map { Asset(name: name, url: file) }
  }
  guard let light = asset(images.light, "light"), let dark = asset(images.dark, "dark") else {
    return nil
  }

  return PreviewImageFiles(light: light, dark: dark, size: size)
}

extension CardPreview {
  /// The board's ID, followed by the color, if any, e.g. `<board-id>-purple`.
  fileprivate var fileName: String {
    color.map { color in "\(boardID.rawValue)-\(color.rawValue)" } ?? boardID.rawValue
  }
}

/// The board's preview drawn as images in light and dark, the width in pixels, from a page made for
/// it in a temporary folder, with the viewer's style sheet and the files the preview shows. It's
/// drawn at the board's size, then scaled, as text drawn smaller than browsers' minimum font size
/// would overflow. Nil when WebKit can't draw it, or the board is empty.
func previewImages(of preview: BoardPreview, index: BoardsIndex, width: Int) async
  -> PreviewImages?
{
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
    let light = await snapshot(of: page, size: window, appearance: .light, width: width),
    let dark = await snapshot(of: page, size: window, appearance: .dark, width: width)
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

/// A page showing the preview alone, in the system's appearance. It never scrolls: a preview sized
/// in fractions of a pixel overflows the window a little, and its scrollbars would be drawn too.
private func previewPage(showing preview: String) -> String {
  """
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <link rel="stylesheet" href="allume.css">
  <style>
  :root { color-scheme: light dark; overflow: hidden; }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; }
  </style>
  </head>
  <body>
  \(preview)
  </body>
  </html>

  """
}
