import AllumeWebModels
import Foundation

/// Writes the folder a site embeds the board views from, as `publish` does, resolving the views'
/// references from the site's patterns: each board's URL, with `{slug}` standing for its slug, and
/// where it serves the folder's `files/`. A kind of reference without a pattern is kept. The
/// exported board's preview is drawn as images with WebKit.
public func publishEmbed(
  _ contents: Contents, to folder: URL, replacingContents: Bool, faviconCache: URL?,
  boardURL: String?, filesURL: String?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  let urlPatterns = URLPatterns(board: boardURL, files: filesURL)

  return try await publish(
    contents,
    files: { boards in
      let images = await previewImages(of: boards.preview, index: boards.index)
      let warnings: [PublishingWarning] = images == nil ? [.previewNotDrawn] : []
      return (embedFiles(from: boards, urlPatterns: urlPatterns, previewImages: images), warnings)
    }, to: folder, replacingContents: replacingContents, faviconCache: faviconCache)
}
