import AllumeWebModels
import Foundation

/// Writes the standalone site into the folder, in the theme, as `publish` does.
public func publishSite(
  _ contents: Contents, to folder: URL, replacingContents: Bool, faviconCache: URL?,
  previewWidth: Int, theme: SiteTheme
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  try await publish(
    contents, files: { boards in (siteFiles(from: boards, theme: theme), []) }, to: folder,
    replacingContents: replacingContents, faviconCache: faviconCache, previewWidth: previewWidth)
}
