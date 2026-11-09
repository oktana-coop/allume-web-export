import AllumeWebModels
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

/// The files an image card shows, when publishing has made some of them: the image on its board,
/// which may be a copy browsers can show, and a smaller copy for previews.
package struct ImageFiles: Hashable, Sendable {
  package let image: Asset
  package let thumbnail: Asset?

  package init(image: Asset, thumbnail: Asset?) {
    self.image = image
    self.thumbnail = thumbnail
  }
}
