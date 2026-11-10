import AllumeWeb
import AllumeWebBundleReader
import AllumeWebRendering
import Foundation
import ImageIO
import Testing

@Suite struct SampleExportTests {
  @Test func rendersTheExpectedPagesAndFiles() async throws {
    let boards = try await renderedSample()

    let siteFiles = siteFiles(from: boards, theme: .light)

    try compareWithExpectedFiles(
      comparableOutput(of: siteFiles), in: expectedURL.appending(path: "SampleExport"))
  }

  @Test func rendersTheExpectedFolderToEmbed() async throws {
    let boards = try await renderedSample()

    let embedFiles = embedFiles(from: boards, urlPatterns: URLPatterns(), previewImages: nil)

    try compareWithExpectedFiles(
      comparableOutput(of: embedFiles), in: expectedURL.appending(path: "SampleEmbed"))
  }

  @Test func resolvesEveryReferenceToEmbedFromThePatterns() async throws {
    let boards = try await renderedSample()
    let urlPatterns = URLPatterns(board: "/boards/{slug}/", files: "/allume/files")

    let embedFiles = embedFiles(from: boards, urlPatterns: urlPatterns, previewImages: nil)

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
      contents, to: folder, replacingContents: false, faviconCache: nil,
      previewWidth: defaultPreviewWidth, theme: .light)

    #expect(warnings.isEmpty)
    #expect(Set(try filePaths(in: folder)) == Set(pages + files + ["allume.css", "allume.js"]))
    #expect(
      try pages.allSatisfy { page in
        try Data(contentsOf: folder.appending(path: page))
          == Data(contentsOf: expected.appending(path: page))
      })
  }
  @Test func publishesTheBoardsPreviewAsImagesToEmbed() async throws {
    let (contents, _) = try readBundle(at: fixtureURL)
    let folder = FileManager.default.temporaryDirectory.appending(
      path: "SampleExportTests-\(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (_, warnings) = try await publishEmbed(
      contents, to: folder, replacingContents: false, faviconCache: nil,
      previewWidth: defaultPreviewWidth, boardURL: nil, filesURL: nil)

    #expect(warnings.isEmpty)
    let index = try String(contentsOf: folder.appending(path: "boards.json"), encoding: .utf8)
    #expect(index.contains(#""light" : "preview-light.jpg""#))
    #expect(
      try ["preview-light.jpg", "preview-dark.jpg"].allSatisfy { name in
        try imageWidth(of: folder.appending(path: name)) == 1600
      })
  }
}

/// How many pixels wide the image in the file is.
private func imageWidth(of file: URL) throws -> Int? {
  let source = try #require(CGImageSourceCreateWithURL(file as CFURL, nil))
  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
  return properties?[kCGImagePropertyPixelWidth] as? Int
}

/// The sample's boards, rendered as publishing renders them, with its images' files and its board
/// cards' preview images, but no favicons, which would need the network. The files are gone once it
/// returns, which the tests that compare only text and paths don't read.
private func renderedSample() async throws -> RenderedBoards {
  let (contents, _) = try readBundle(at: fixtureURL)
  let folder = FileManager.default.temporaryDirectory.appending(
    path: "SampleExportTests-\(UUID())")
  defer { try? FileManager.default.removeItem(at: folder) }

  let images = makeImageFiles(of: contents, in: folder)
  let (previews, _) = await makePreviewImageFiles(
    of: contents, favicons: [:], images: images, width: defaultPreviewWidth, in: folder)

  return renderedBoards(for: contents, favicons: [:], images: images, previews: previews)
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
