import AllumeWebModels
import AllumeWebRendering
import Testing

@testable import AllumeWeb

@Suite struct SiteURLsTests {
  @Test func nameTheRootsPageIndexAndTheOthersAfterTheirSlugs() throws {
    let contents = try makeContents(with: [makeBoard("functional", label: "Functional")])
    let slug = try #require(slugs(in: contents)[Document.ID(rawValue: "functional")])

    let urls = siteURLs(for: boardsIndex(for: contents))

    #expect(
      urls.boards == [
        Document.ID(rawValue: "root"): "index.html",
        Document.ID(rawValue: "functional"): "\(slug).html",
      ])
    #expect(urls.files == "files/")
  }
}
