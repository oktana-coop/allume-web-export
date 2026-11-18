import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct ExportArchiveTests {
  @Test func decompressesAnExportIntoTheFolderNamedAfterItsBoard() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    // As Allume writes it: the export's folder zipped, named .muse.
    let archive = try makeArchive(
      of: fixtureURL, keepingItsFolder: true, at: folder, named: "Sample.muse")

    let exportFolder = try decompressExport(at: archive, into: folder.appending(path: "out"))

    #expect(exportFolder.lastPathComponent == "SampleExport")
    // Files are where each folder has them, so the documents are compared by ID.
    #expect(
      try readBundle(at: exportFolder).contents.documents.map(\.id)
        == readBundle(at: fixtureURL).contents.documents.map(\.id))
  }

  @Test func decompressesAnArchiveOfTheExportsFilesAlone() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let archive = try makeArchive(
      of: fixtureURL, keepingItsFolder: false, at: folder, named: "Sample.zip")
    let out = folder.appending(path: "out")

    let exportFolder = try decompressExport(at: archive, into: out)

    #expect(exportFolder == out)
    #expect(
      try readBundle(at: exportFolder).contents.rootID == readBundle(at: fixtureURL).contents.rootID
    )
  }

  @Test func rejectsAFileThatIsntAZipArchive() throws {
    let folder = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: folder) }
    let notes = folder.appending(path: "notes.txt")
    try Data("Not an export".utf8).write(to: notes)

    #expect(throws: UnreadableBundleError.notAnArchive("notes.txt")) {
      try decompressExport(at: notes, into: folder.appending(path: "out"))
    }
  }
}

/// A zip archive of the folder, made with `ditto` as the Finder's Compress makes them: with the
/// folder itself around its contents, or its contents alone.
private func makeArchive(of source: URL, keepingItsFolder: Bool, at folder: URL, named name: String)
  throws -> URL
{
  let archive = folder.appending(path: name)
  let ditto = Process()
  ditto.executableURL = URL(filePath: "/usr/bin/ditto")
  ditto.arguments =
    ["-c", "-k"] + (keepingItsFolder ? ["--keepParent"] : [])
    + [source.path(percentEncoded: false), archive.path(percentEncoded: false)]
  try ditto.run()
  ditto.waitUntilExit()
  try #require(ditto.terminationStatus == 0)
  return archive
}

private func makeTemporaryFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "Export archive \(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}
