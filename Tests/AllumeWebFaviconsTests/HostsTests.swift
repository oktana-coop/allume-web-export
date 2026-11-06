import Foundation
import Testing

@testable import AllumeWebFavicons

@Suite struct HostsTests {
  @Test(arguments: ["github.com", "blog.ploeh.dk", "en.wikibooks.org", "xn--bcher-kva.example"])
  func fetchesPublicNames(host: String) {
    #expect(isFetchable(host))
  }

  @Test(arguments: [
    "localhost", "intranet", "printer.local", "app.localhost", "build.internal", "nas.lan",
    "router.home.arpa", "127.0.0.1", "10.0.0.1", "0x7f.0.0.1", "::1", "a..b", "../etc", ".com",
    "GitHub.com", "user@github.com", String(repeating: "a", count: 64) + ".com",
  ])
  func refusesEverythingElse(host: String) {
    #expect(!isFetchable(host))
  }

  @Test(arguments: [
    "http://github.com/", "https://user@github.com/", "https://github.com:8443/",
    "https://127.0.0.1/", "file:///etc/hosts", "data:image/png;base64,AAAA",
  ])
  func fetchesOnlyHTTPSURLsOnTheDefaultPort(url: String) throws {
    let url = try #require(URL(string: url))

    #expect(!isFetchable(url))
  }

  @Test func fetchesAnHTTPSURLWhateverTheHostsCase() throws {
    let url = try #require(URL(string: "https://GitHub.com/favicon.ico"))

    #expect(isFetchable(url))
  }
}
