import Foundation

/// Something publishing left out, which doesn't stop it.
public enum PublishingWarning: Equatable, Sendable {
  /// A file to copy whose source is missing, so the output goes without it.
  case missingFile(path: String, source: URL)
  /// What wasn't written to the favicon cache is fetched again next time.
  case faviconCacheUnwritable(URL, reason: String)
}
