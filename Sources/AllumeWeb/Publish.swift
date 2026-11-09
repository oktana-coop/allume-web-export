import AllumeWebFavicons
import AllumeWebModels
import AllumeWebRendering
import AllumeWebThumbnails
import Foundation

/// Writes the files made from the export's rendered boards into the folder, with its links'
/// favicons when there's a cache to keep them in. A folder with anything in it is only written to
/// when its contents are to be replaced, and a failed run leaves it as it was.
func publish(
  _ contents: Contents, files: (RenderedBoards) -> [OutputFile], to folder: URL,
  replacingContents: Bool, faviconCache: URL?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  let (favicons, faviconWarnings) = await favicons(of: contents, cache: faviconCache)

  let thumbnailFolder = FileManager.default.temporaryDirectory.appending(
    path: "allume-web-export-thumbnails-\(UUID())")
  defer { try? FileManager.default.removeItem(at: thumbnailFolder) }

  let thumbnails = makeThumbnails(of: contents, in: thumbnailFolder)

  let writingWarnings = try writeFolder(
    files(renderedBoards(for: contents, favicons: favicons, thumbnails: thumbnails)), to: folder,
    replacingContents: replacingContents)

  return (favicons.count, faviconWarnings + writingWarnings)
}

/// Previews show images at most about 120 px wide at 100%, so twice that stays sharp on
/// high-density screens.
private let thumbnailWidth = 256

/// The thumbnail of each image card's file wider than a thumbnail, written into the folder, by the
/// image's file name. An image without one is shown as it is.
package func makeThumbnails(of contents: Contents, in folder: URL) -> [String: Asset] {
  let images = Dictionary(
    contents.documents.compactMap { document -> (String, URL)? in
      guard case .image(let image) = document else {
        return nil
      }

      return (image.file.name, image.file.url)
    },
    uniquingKeysWith: { first, _ in first })

  guard
    (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true))
      != nil
  else {
    return [:]
  }

  let thumbnails = images.compactMap { name, url -> (String, Asset)? in
    guard let thumbnail = thumbnail(of: url, width: thumbnailWidth) else {
      return nil
    }

    let file = folder.appending(
      path: "\((name as NSString).deletingPathExtension).\(thumbnail.format.fileExtension)")
    guard (try? thumbnail.data.write(to: file)) != nil else {
      return nil
    }

    return (name, Asset(name: file.lastPathComponent, url: file))
  }
  return Dictionary(uniqueKeysWithValues: thumbnails)
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
