import Foundation

/// Whether the host is a public name to fetch from. IP addresses, including forms like
/// `0x7f.0.0.1`, and names that only mean something on a local network are refused, so links can't
/// reach into it.
func isFetchable(_ host: String) -> Bool {
  let labels = host.split(separator: ".", omittingEmptySubsequences: false)

  return host.count <= 253 && labels.count >= 2
    && labels.allSatisfy { label in
      !label.isEmpty && label.count <= 63 && label.allSatisfy(hostCharacters.contains)
    }
    && labels.last?.first.map(("a"..."z").contains) == true
    && !localSuffixes.contains { suffix in host.hasSuffix(suffix) }
}

/// Whether the URL is HTTPS on its default port, on a fetchable host, with no user or password.
func isFetchable(_ url: URL) -> Bool {
  url.scheme == "https" && url.user == nil && url.password == nil
    && (url.port == nil || url.port == 443)
    && url.host().map { host in isFetchable(host.lowercased()) } == true
}

private let hostCharacters = Set("abcdefghijklmnopqrstuvwxyz0123456789-")

private let localSuffixes = [".localhost", ".local", ".internal", ".lan", ".home.arpa"]
