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

/// A board's preview as its cards show it: on their color, when they have one.
package struct CardPreview: Hashable, Sendable {
  package let boardID: Document.ID
  package let color: CardColor?

  package init(boardID: Document.ID, color: CardColor?) {
    self.boardID = boardID
    self.color = color
  }
}

/// A board's preview drawn as an image in each appearance, which its cards show.
package struct PreviewImageFiles: Hashable, Sendable {
  package let light: Asset
  package let dark: Asset

  package init(light: Asset, dark: Asset) {
    self.light = light
    self.dark = dark
  }
}
