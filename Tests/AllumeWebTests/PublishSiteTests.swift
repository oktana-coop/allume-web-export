import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWeb

@Suite struct PublishSiteTests {
  @Test func fetchesFaviconsForTheHostsOfWebLinks() throws {
    let contents = try makeContents(with: [
      makeLink("haskell", url: "https://www.Haskell.org/"),
      makeLink("ocaml", url: "https://ocaml.org/docs"),
      makeLink("ocaml again", url: "http://ocaml.org/"),
      makeLink("no scheme", url: "example.com/talks/lambda"),
      makeLink("mail", url: "mailto:someone@example.com"),
    ])

    let hosts = linkHosts(in: contents)

    #expect(hosts == ["www.haskell.org", "ocaml.org"])
  }

  @Test func leavesFaviconsOutWithoutACache() async throws {
    let contents = try makeContents(with: [makeLink("ocaml", url: "https://ocaml.org/")])
    let folder = FileManager.default.temporaryDirectory.appending(path: "Publish site \(UUID())")
    defer { try? FileManager.default.removeItem(at: folder) }

    let (faviconCount, warnings) = try await publishSite(
      contents, to: folder, replacingContents: false, faviconCache: nil,
      previewWidth: defaultPreviewWidth, theme: .light)

    #expect(faviconCount == 0)
    #expect(warnings.isEmpty)
    #expect(
      !FileManager.default.fileExists(
        atPath: folder.appending(path: "files").path(percentEncoded: false)))
  }
}
