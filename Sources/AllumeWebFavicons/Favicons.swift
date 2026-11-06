import Foundation

/// Each host's icon, as a PNG of our own in the cache. Hosts the cache doesn't know are fetched
/// from their site over HTTPS, and hosts that aren't public names get none.
package func fetchFavicons(for hosts: Set<String>, cache: URL) async
  -> (favicons: [String: URL], warnings: [FaviconWarning])
{
  await fetchFavicons(for: hosts, cache: cache, session: makeFaviconSession())
}

func fetchFavicons(for hosts: Set<String>, cache: URL, session: URLSession) async
  -> (favicons: [String: URL], warnings: [FaviconWarning])
{
  let known = readManifest(in: cache)
  let unknown = hosts.filter { host in
    isFetchable(host) && (known[host] == nil || (known[host] == true && !isCached(host, in: cache)))
  }

  let fetched = await fetchIcons(of: unknown.sorted(), session: session)
  let icons = fetched.compactMapValues { $0 }
  let warnings = write(
    icons, manifest: known.merging(fetched.mapValues { icon in icon != nil }) { _, new in new },
    in: cache)

  let favicons = hosts.filter { host in isCached(host, in: cache) }
    .map { host in (host, iconURL(of: host, in: cache)) }
  return (Dictionary(uniqueKeysWithValues: favicons), warnings)
}

/// The host's icon, from the first that works of the two its home page declares best, then
/// `/favicon.ico`.
func fetchIcon(of host: String, session: URLSession) async -> Data? {
  guard let home = URL(string: "https://\(host)/"),
    let fallback = URL(string: "https://\(host)/favicon.ico")
  else {
    return nil
  }

  let page = await fetch(home, limit: maxPageBytes, truncating: true, session: session)
  let declared =
    page.map { page in declaredIcons(in: String(decoding: page.data, as: UTF8.self), at: page.url) }
    ?? []
  let candidates = declared.filter { url in url != fallback }.prefix(2) + [fallback]
  return await firstIcon(among: candidates[...], session: session)
}

/// Only the `<head>` is read, and it comes first.
private let maxPageBytes = 512 * 1024

private let maxIconBytes = 256 * 1024

/// How many hosts are fetched at once.
private let batchSize = 8

private func isCached(_ host: String, in cache: URL) -> Bool {
  FileManager.default.fileExists(atPath: iconURL(of: host, in: cache).path(percentEncoded: false))
}

/// Each host's icon, or nil for a host without one, a batch of hosts at a time.
private func fetchIcons(of hosts: [String], session: URLSession) async -> [String: Data?] {
  guard !hosts.isEmpty else {
    return [:]
  }

  let batch = await withTaskGroup(of: (String, Data?).self) { group in
    for host in hosts.prefix(batchSize) {
      group.addTask { (host, await fetchIcon(of: host, session: session)) }
    }
    return await group.reduce(into: [String: Data?]()) { icons, result in
      icons[result.0] = .some(result.1)
    }
  }
  let rest = await fetchIcons(of: Array(hosts.dropFirst(batchSize)), session: session)
  return batch.merging(rest) { first, _ in first }
}

private func firstIcon(among candidates: ArraySlice<URL>, session: URLSession) async -> Data? {
  guard let candidate = candidates.first else {
    return nil
  }

  if let icon = await fetch(candidate, limit: maxIconBytes, truncating: false, session: session)
    .flatMap({ response in reencodedIcon(response.data) })
  {
    return icon
  }
  return await firstIcon(among: candidates.dropFirst(), session: session)
}
