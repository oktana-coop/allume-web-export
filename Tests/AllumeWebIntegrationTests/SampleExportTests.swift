import AllumeWeb
import AllumeWebBundleReader
import Foundation
import Testing

@Suite struct SampleExportTests {
  @Test func rendersTheExpectedPagesAndFiles() throws {
    let (contents, _) = try readBundle(at: fixtureURL)

    let siteFiles = siteFiles(from: renderedBoards(for: contents, favicons: [:]))

    try compareWithExpectedFiles(
      comparableOutput(of: siteFiles), in: expectedURL.appending(path: "SampleExport"))
  }

  @Test func rendersTheExpectedFolderToEmbed() throws {
    let (contents, _) = try readBundle(at: fixtureURL)

    let embedFiles = embedFiles(
      from: renderedBoards(for: contents, favicons: [:]), urlPatterns: URLPatterns())

    try compareWithExpectedFiles(
      comparableOutput(of: embedFiles), in: expectedURL.appending(path: "SampleEmbed"))
  }

  @Test func resolvesEveryReferenceToEmbedFromThePatterns() throws {
    let (contents, _) = try readBundle(at: fixtureURL)
    let urlPatterns = URLPatterns(board: "/boards/{slug}/", files: "/allume/files")

    let embedFiles = embedFiles(
      from: renderedBoards(for: contents, favicons: [:]), urlPatterns: urlPatterns)

    let withReferences = embedFiles.filter { file in
      guard case .text(let text) = file.source else { return false }
      return text.contains("allume:")
    }
    #expect(withReferences.map(\.path) == [])
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
    #expect(Set(try filePaths(in: folder)) == Set(pages + files + ["allume.css", "allume.js"]))
    #expect(
      try pages.allSatisfy { page in
        try Data(contentsOf: folder.appending(path: page))
          == Data(contentsOf: expected.appending(path: page))
      })
  }
}

/// The files written as text, by path, and `files.txt`, listing the paths of those copied under
/// `files/`, whose bytes the test doesn't compare.
private func comparableOutput(of files: [OutputFile]) -> [String: String] {
  let texts = files.compactMap { file -> (String, String)? in
    guard case .text(let text) = file.source else { return nil }
    return (file.path, text)
  }
  let copied = files.map(\.path).filter { path in path.hasPrefix("files/") }
    .map { path in String(path.dropFirst("files/".count)) }

  return [String: String](
    uniqueKeysWithValues: texts + [("files.txt", copied.joined(separator: "\n") + "\n")])
}
