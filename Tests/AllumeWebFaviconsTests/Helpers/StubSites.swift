import Foundation
import os

@testable import AllumeWebFavicons

/// Plays the websites the tests fetch from, so that no test touches the network. Each test serves
/// its own hosts, since tests run in parallel.
final class StubSites: URLProtocol {
  enum Answer: Sendable {
    case body(Data)
    case redirect(to: String)
  }

  private static let answers = OSAllocatedUnfairLock<[String: Answer]>(initialState: [:])
  private static let requests = OSAllocatedUnfairLock<[String]>(initialState: [])

  static func serve(_ answers: [String: Answer]) {
    Self.answers.withLock { known in known.merge(answers) { _, new in new } }
  }

  /// The URLs requested from the host, in order.
  static func requests(to host: String) -> [String] {
    requests.withLock { requests in
      requests.filter { request in URL(string: request)?.host() == host }
    }
  }

  override class func canInit(with request: URLRequest) -> Bool {
    true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    request
  }

  override func startLoading() {
    guard let url = request.url else {
      return
    }
    Self.requests.withLock { requests in requests.append(url.absoluteString) }

    switch Self.answers.withLock({ answers in answers[url.absoluteString] }) {
    case .body(let data)?:
      respond(to: url, status: 200, headers: [:], body: data)
    case .redirect(let target)?:
      guard let targetURL = URL(string: target),
        let response = HTTPURLResponse(
          url: url, statusCode: 302, httpVersion: "HTTP/1.1", headerFields: ["Location": target])
      else {
        return
      }
      client?.urlProtocol(
        self, wasRedirectedTo: URLRequest(url: targetURL), redirectResponse: response)
      respond(to: url, status: 302, headers: ["Location": target], body: Data())
    case nil:
      respond(to: url, status: 404, headers: [:], body: Data())
    }
  }

  override func stopLoading() {}

  private func respond(to url: URL, status: Int, headers: [String: String], body: Data) {
    guard
      let response = HTTPURLResponse(
        url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)
    else {
      return
    }
    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: body)
    client?.urlProtocolDidFinishLoading(self)
  }
}

/// A session that fetches from the stub sites instead of the network.
func makeStubSession() -> URLSession {
  makeFaviconSession(protocolClasses: [StubSites.self])
}

func makeTemporaryFolder() throws -> URL {
  let folder = FileManager.default.temporaryDirectory.appending(path: "Favicons \(UUID())")
  try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
  return folder
}
