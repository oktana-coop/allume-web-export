import AllumeWebFavicons
import AllumeWebImages
import AllumeWebModels
import AllumeWebRendering
import Foundation

/// Writes the files made from the export's rendered boards into the folder, with its links'
/// favicons when there's a cache to keep them in. A folder with anything in it is only written to
/// when its contents are to be replaced, and a failed run leaves it as it was.
func publish(
  _ contents: Contents, files: (RenderedBoards) -> [OutputFile], to folder: URL,
  replacingContents: Bool, faviconCache: URL?
) async throws(UnwritableFolderError) -> (faviconCount: Int, warnings: [PublishingWarning]) {
  let (favicons, faviconWarnings) = await favicons(of: contents, cache: faviconCache)

  let imageFolder = FileManager.default.temporaryDirectory.appending(
    path: "allume-web-export-images-\(UUID())")
  defer { try? FileManager.default.removeItem(at: imageFolder) }

  let images = makeImageFiles(of: contents, in: imageFolder)

  let writingWarnings = try writeFolder(
    files(renderedBoards(for: contents, favicons: favicons, images: images)), to: folder,
    replacingContents: replacingContents)

  return (favicons.count, faviconWarnings + writingWarnings)
}

/// Previews show images at most about 120 px wide at 100%, so twice that stays sharp on
/// high-density screens.
private let thumbnailWidth = 256

/// The files made for each image card's file, written into the folder, by the image's file name:
/// a copy browsers can show, when they can't show the original, and a thumbnail, when the image is
/// wider than one. An image needing neither isn't listed, and is shown as it is.
package func makeImageFiles(of contents: Contents, in folder: URL) -> [String: ImageFiles] {
  let images = Dictionary(
    contents.documents.compactMap { document -> (String, URL)? in
      guard case .image(let image) = document else {
        return nil
      }

      return (image.file.name, image.file.url)
    },
    uniquingKeysWith: { first, _ in first })
  // Apart, since a copy and a thumbnail can have the same name.
  let thumbnailFolder = folder.appending(path: "thumbs")
  guard
    (try? FileManager.default.createDirectory(
      at: thumbnailFolder, withIntermediateDirectories: true)) != nil
  else {
    return [:]
  }

  let files = images.compactMap { name, url -> (String, ImageFiles)? in
    let copy = webCopy(of: url).flatMap { image in written(image, named: name, into: folder) }
    let thumbnail = thumbnail(of: url, width: thumbnailWidth).flatMap { image in
      written(image, named: name, into: thumbnailFolder)
    }
    guard copy != nil || thumbnail != nil else {
      return nil
    }

    return (name, ImageFiles(image: copy ?? Asset(name: name, url: url), thumbnail: thumbnail))
  }
  return Dictionary(uniqueKeysWithValues: files)
}

/// The web image written into the folder, named after the image's file, with its own format's
/// extension.
private func written(_ image: WebImage, named name: String, into folder: URL) -> Asset? {
  let file = folder.appending(
    path: "\((name as NSString).deletingPathExtension).\(image.format.fileExtension)")
  guard (try? image.data.write(to: file)) != nil else {
    return nil
  }

  return Asset(name: file.lastPathComponent, url: file)
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
