import AllumeWebFavicons
import AllumeWebModels
import AllumeWebRendering
import Foundation

/// Writes the standalone site into the folder, with its links' favicons when there's a cache to
/// keep them in. A folder with anything in it is only written to when its contents are to be
/// replaced, and a failed run leaves it as it was.
public func publishSite(
  _ contents: Contents, to folder: URL, replacingContents: Bool, faviconCache: URL?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  let (favicons, faviconWarnings) = await favicons(of: contents, cache: faviconCache)
  let writingWarnings = try writeFolder(
    siteFiles(from: renderedBoards(for: contents, favicons: favicons)), to: folder,
    replacingContents: replacingContents)

  return (favicons.count, faviconWarnings + writingWarnings)
}

/// The hosts whose icons the link cards show.
func linkHosts(in contents: Contents) -> Set<String> {
  Set(
    contents.documents.compactMap { document in
      guard case .link(let link) = document else {
        return nil
      }
      return faviconHost(of: link.url)
    })
}

/// Each link host's icon, from the cache or fetched into it. None without a cache.
private func favicons(of contents: Contents, cache: URL?) async
  -> (favicons: [String: Asset], warnings: [PublishingWarning])
{
  guard let cache else {
    return ([:], [])
  }

  let (icons, warnings) = await fetchFavicons(for: linkHosts(in: contents), cache: cache)
  return (
    icons.mapValues { url in Asset(name: url.lastPathComponent, url: url) },
    warnings.map { warning in
      switch warning {
      case .cacheUnwritable(let url, let reason): .faviconCacheUnwritable(url, reason: reason)
      }
    }
  )
}
