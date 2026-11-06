import Foundation

/// Which hosts the cache knows: those with an icon, and those without. Empty when it can't be read.
func readManifest(in cache: URL) -> [String: Bool] {
  (try? Data(contentsOf: manifestURL(in: cache))).flatMap { data in
    try? JSONDecoder().decode([String: Bool].self, from: data)
  } ?? [:]
}

func iconURL(of host: String, in cache: URL) -> URL {
  cache.appending(path: "\(host).png")
}

/// Writes the fetched icons, then the manifest. A failure stops there and is only a warning:
/// publishing goes on, and what wasn't written is fetched again next time.
func write(_ icons: [String: Data], manifest: [String: Bool], in cache: URL) -> [FaviconWarning] {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

  do {
    try FileManager.default.createDirectory(at: cache, withIntermediateDirectories: true)
    for (host, icon) in icons {
      try icon.write(to: iconURL(of: host, in: cache), options: .atomic)
    }
    try encoder.encode(manifest).write(to: manifestURL(in: cache), options: .atomic)
    return []
  } catch {
    return [.cacheUnwritable(cache, reason: error.localizedDescription)]
  }
}

private func manifestURL(in cache: URL) -> URL {
  cache.appending(path: "manifest.json")
}
