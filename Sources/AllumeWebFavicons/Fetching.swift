import Foundation

/// A session for untrusted sites: no cookies, credentials or cache, short timeouts, and redirects
/// only to HTTPS on fetchable hosts.
func makeFaviconSession(protocolClasses: [AnyClass]? = nil) -> URLSession {
  let configuration = URLSessionConfiguration.ephemeral
  configuration.httpCookieStorage = nil
  configuration.httpShouldSetCookies = false
  configuration.urlCredentialStorage = nil
  configuration.urlCache = nil
  configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
  configuration.timeoutIntervalForRequest = 8
  configuration.timeoutIntervalForResource = 15
  configuration.httpAdditionalHeaders = [
    "User-Agent": "Mozilla/5.0 (compatible; allume-web-export)",
    "Accept": "text/html,image/*;q=0.9",
  ]
  configuration.protocolClasses = protocolClasses ?? configuration.protocolClasses

  return URLSession(configuration: configuration, delegate: RedirectPolicy(), delegateQueue: nil)
}

/// The body of a successful response from a fetchable URL, and the URL it finally came from. Past
/// the limit, it's cut there when truncating, and refused otherwise. The limit is applied while
/// the body arrives, so a huge one is never downloaded.
func fetch(_ url: URL, limit: Int, truncating: Bool, session: URLSession) async
  -> (data: Data, url: URL)?
{
  guard isFetchable(url),
    let (bytes, response) = try? await session.bytes(from: url),
    let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
    let finalURL = http.url, isFetchable(finalURL),
    truncating || http.expectedContentLength <= Int64(limit),
    let data = await firstBytes(of: bytes, upTo: limit + 1),
    truncating || data.count <= limit
  else {
    return nil
  }

  return (data.prefix(limit), finalURL)
}

/// Stops reading once it has as many bytes as asked for, which ends the download.
private func firstBytes(of bytes: URLSession.AsyncBytes, upTo count: Int) async -> Data? {
  try? await bytes.prefix(count).reduce(into: Data()) { data, byte in data.append(byte) }
}

/// Checks every redirect again, since a site may send us anywhere.
private final class RedirectPolicy: NSObject, URLSessionTaskDelegate, Sendable {
  func urlSession(
    _ session: URLSession, task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest
  ) async -> URLRequest? {
    request.url.map(isFetchable) == true ? request : nil
  }
}
