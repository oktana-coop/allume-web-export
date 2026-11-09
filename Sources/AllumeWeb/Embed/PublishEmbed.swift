import AllumeWebModels
import Foundation

/// Writes the folder a site embeds the board views from, as `publish` does, resolving the views'
/// references from the site's patterns: each board's URL, with `{slug}` standing for its slug, and
/// where it serves the folder's `files/`. A kind of reference without a pattern is kept.
public func publishEmbed(
  _ contents: Contents, to folder: URL, replacingContents: Bool, faviconCache: URL?,
  boardURL: String?, filesURL: String?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  let urlPatterns = URLPatterns(board: boardURL, files: filesURL)

  return try await publish(
    contents, files: { boards in embedFiles(from: boards, urlPatterns: urlPatterns) }, to: folder,
    replacingContents: replacingContents, faviconCache: faviconCache)
}
