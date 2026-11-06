import AllumeWebBundleReader
import AllumeWebRendering
import Testing

@Suite struct LanguagesTests {
  @Test func rendersTheExpectedPagesAndFiles() throws {
    let (contents, _) = try readBundle(at: fixtureURL)

    let (pages, files) = renderBoards(contents, favicons: [:])

    let output = [String: String](
      uniqueKeysWithValues: pages.map { page in (page.path, page.html) }
        + [("files.txt", files.map(\.path).joined(separator: "\n") + "\n")])
    try compareWithExpectedFiles(output, in: expectedURL.appending(path: "Languages"))
  }
}
