import Foundation

/// Something that went wrong with favicons, which doesn't stop publishing.
package enum FaviconWarning: Equatable, Sendable {
  /// What wasn't written to the cache is fetched again next time.
  case cacheUnwritable(URL, reason: String)
}
