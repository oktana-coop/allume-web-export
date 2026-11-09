import AllumeWebModels
import Foundation

/// Writes the folder a site embeds the board views from, as `publish` does.
public func publishEmbed(
  _ contents: Contents, to folder: URL, replacingContents: Bool, faviconCache: URL?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  try await publish(
    contents, files: embedFiles(from:), to: folder, replacingContents: replacingContents,
    faviconCache: faviconCache)
}
