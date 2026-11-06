import Foundation

/// Something publishing left out, which doesn't stop it.
public enum PublishingWarning: Equatable, Sendable {
  /// A file to copy whose source is missing, so the site goes without it.
  case missingFile(path: String, source: URL)
}
