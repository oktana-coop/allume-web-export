import AllumeWeb
import AllumeWebBundleReader
import AllumeWebRendering
import Foundation
import Testing

@Suite struct SampleExportTests {
  @Test func rendersTheExpectedPagesAndFiles() throws {
    let (contents, _) = try readBundle(at: fixtureURL)

    let (pages, files) = renderBoards(contents, favicons: [:])

    let output = [String: String](
      uniqueKeysWithValues: pages.map { page in (page.path, page.html) }
        + [("files.txt", files.map(\.path).joined(separator: "\n") + "\n")])
    try compareWithExpectedFiles(output, in: expectedURL.appending(path: "SampleExport"))
  }

  @Test func publishesItsSiteIntoAFolder() async throws {
    let (contents, _) = try readBundle(at: fixtureURL)
    let folder = FileManager.default.temporaryDirectory.appending(
      path: "SampleExportTests-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }
    let expected = expectedURL.appending(path: "SampleExport")
    let pages = try FileManager.default.contentsOfDirectory(
      atPath: expected.path(percentEncoded: false)
    )
    .filter { name in name.hasSuffix(".html") }
    let files = try String(contentsOf: expected.appending(path: "files.txt"), encoding: .utf8)
      .split(separator: "\n").map { path in "files/\(path)" }

    let (_, warnings) = try await publishSite(
      contents, to: folder, replacingContents: false, faviconCache: nil)

    #expect(warnings.isEmpty)
    #expect(Set(try filePaths(in: folder)) == Set(pages + files + ["viewer.css", "viewer.js"]))
    #expect(
      try pages.allSatisfy { page in
        try Data(contentsOf: folder.appending(path: page))
          == Data(contentsOf: expected.appending(path: page))
      })
  }
}

/// The paths of the files in the folder and the folders inside it.
private func filePaths(in folder: URL) throws -> [String] {
  try (FileManager.default.subpathsOfDirectory(atPath: folder.path(percentEncoded: false))).filter {
    path in
    try folder.appending(path: path).resourceValues(forKeys: [.isDirectoryKey]).isDirectory
      == false
  }
}
