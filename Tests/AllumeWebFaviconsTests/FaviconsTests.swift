import Foundation
import Testing
import UniformTypeIdentifiers

@testable import AllumeWebFavicons

@Suite struct FaviconsTests {
  @Test func fetchTheIconAHomePageDeclaresAsAPNGOfOurOwn() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://declared.example/": .body(
        Data(#"<head><link rel="icon" sizes="256x256" href="/icon.png"></head>"#.utf8)),
      "https://declared.example/icon.png": .body(try makeImage(sizes: [256], type: .png)),
    ])

    let (favicons, warnings) = await fetchFavicons(
      for: ["declared.example"], cache: cache, session: makeStubSession())

    let icon = try #require(favicons["declared.example"])
    #expect(icon == cache.appending(path: "declared.example.png"))
    #expect(try properties(of: Data(contentsOf: icon)).width == 128)
    #expect(warnings.isEmpty)
  }

  @Test func skipDeclaredSVGForFaviconICO() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://vector.example/": .body(
        Data(#"<head><link rel="icon" href="/icon.svg"></head>"#.utf8)),
      "https://vector.example/icon.svg": .body(Data("<svg><script>alert(1)</script></svg>".utf8)),
      "https://vector.example/favicon.ico": .body(try makeImage(sizes: [16, 32], type: .ico)),
    ])

    let (favicons, _) = await fetchFavicons(
      for: ["vector.example"], cache: cache, session: makeStubSession())

    #expect(favicons["vector.example"] != nil)
    #expect(
      StubSites.requests(to: "vector.example") == [
        "https://vector.example/", "https://vector.example/favicon.ico",
      ])
  }

  @Test func giveNoIconForAnythingButAnImage() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://script.example/favicon.ico": .body(Data("<svg><script>alert(1)</script></svg>".utf8))
    ])

    let (favicons, _) = await fetchFavicons(
      for: ["script.example"], cache: cache, session: makeStubSession())

    #expect(favicons.isEmpty)
    #expect(
      try FileManager.default.contentsOfDirectory(atPath: cache.path(percentEncoded: false)) == [
        "manifest.json"
      ])
  }

  @Test func followRedirectsToHTTPSOnPublicHosts() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://moved.example/favicon.ico": .redirect(to: "https://cdn.moved.example/icon.png"),
      "https://cdn.moved.example/icon.png": .body(try makeImage(sizes: [32], type: .png)),
    ])

    let (favicons, _) = await fetchFavicons(
      for: ["moved.example"], cache: cache, session: makeStubSession())

    #expect(favicons["moved.example"] != nil)
  }

  @Test func followNoRedirectToHTTPOrTheLocalNetwork() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://hops.example/": .redirect(to: "http://hops.example/"),
      "http://hops.example/": .body(Data(#"<head><link rel="icon" href="/icon.png"></head>"#.utf8)),
      "https://hops.example/favicon.ico": .redirect(to: "https://192.168.1.1/favicon.ico"),
      "https://192.168.1.1/favicon.ico": .body(try makeImage(sizes: [32], type: .png)),
    ])

    let (favicons, _) = await fetchFavicons(
      for: ["hops.example"], cache: cache, session: makeStubSession())

    #expect(favicons.isEmpty)
    #expect(StubSites.requests(to: "192.168.1.1").isEmpty)
    #expect(
      StubSites.requests(to: "hops.example").allSatisfy { request in request.hasPrefix("https:") })
  }

  @Test func refuseAnIconOverTheLimit() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    let huge = try makeImage(sizes: [32], type: .png) + Data(count: 300 * 1024)
    StubSites.serve(["https://huge.example/favicon.ico": .body(huge)])

    let (favicons, _) = await fetchFavicons(
      for: ["huge.example"], cache: cache, session: makeStubSession())

    #expect(favicons.isEmpty)
  }

  @Test func neverContactHostsThatArentPublicNames() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }

    let (favicons, _) = await fetchFavicons(
      for: ["localhost", "127.0.0.1", "printer.local"], cache: cache, session: makeStubSession())

    #expect(favicons.isEmpty)
    #expect(
      ["localhost", "127.0.0.1", "printer.local"].allSatisfy { host in
        StubSites.requests(to: host).isEmpty
      })
  }

  @Test func answerFromTheCacheOnceAHostIsKnown() async throws {
    let cache = try makeTemporaryFolder()
    defer { try? FileManager.default.removeItem(at: cache) }
    StubSites.serve([
      "https://cached.example/favicon.ico": .body(try makeImage(sizes: [32], type: .png))
    ])
    let first = await fetchFavicons(
      for: ["cached.example", "iconless.example"], cache: cache, session: makeStubSession())
    let requestsBefore =
      StubSites.requests(to: "cached.example").count
      + StubSites.requests(to: "iconless.example").count

    let second = await fetchFavicons(
      for: ["cached.example", "iconless.example"], cache: cache, session: makeStubSession())

    #expect(second.favicons == first.favicons)
    #expect(second.favicons.keys.sorted() == ["cached.example"])
    #expect(
      StubSites.requests(to: "cached.example").count
        + StubSites.requests(to: "iconless.example").count == requestsBefore)
  }
}
