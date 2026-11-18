import Foundation

/// Decompresses an export as Allume writes it, a zip archive whatever its extension, into the
/// folder, and returns the export's folder there: the one with `contents.json`, which Allume
/// archives in a folder named after the board. Without one, it's the folder itself, so reading it
/// reports what's missing.
package func decompressExport(at archive: URL, into folder: URL) throws(UnreadableBundleError)
  -> URL
{
  let ditto = Process()
  ditto.executableURL = URL(filePath: "/usr/bin/ditto")
  ditto.arguments = [
    "-x", "-k", archive.path(percentEncoded: false), folder.path(percentEncoded: false),
  ]
  ditto.standardError = FileHandle.nullDevice
  guard (try? ditto.run()) != nil else {
    throw .notAnArchive(archive.lastPathComponent)
  }
  ditto.waitUntilExit()
  guard ditto.terminationStatus == 0 else {
    throw .notAnArchive(archive.lastPathComponent)
  }

  let folders =
    [folder]
    + ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil))
      ?? [])
  return folders.first { candidate in
    FileManager.default.fileExists(
      atPath: candidate.appending(path: "contents.json").path(percentEncoded: false))
  } ?? folder
}
