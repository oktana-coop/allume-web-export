import Foundation

package struct PublishedFile: Hashable, Sendable {
  /// Under `files/`, e.g. `favicons/github.com.png`.
  package let path: String
  package let source: URL

  package init(path: String, source: URL) {
    self.path = path
    self.source = source
  }
}
