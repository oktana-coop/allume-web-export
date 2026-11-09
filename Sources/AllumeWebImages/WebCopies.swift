import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// The image at the URL, at its full size, as a web image, when browsers can't show its format, as
/// with HEIC. Nil when they can, or the image can't be read.
package func webCopy(of image: URL) -> WebImage? {
  guard let source = CGImageSourceCreateWithURL(image as CFURL, nil),
    let type = CGImageSourceGetType(source).flatMap({ type in UTType(type as String) }),
    !webFormats.contains(where: { format in type.conforms(to: format) }),
    let size = displayedSize(of: source),
    let drawn = drawnImage(from: source, longerSide: max(size.width, size.height))
  else {
    return nil
  }

  return encoded(drawn)
}

/// The formats every current browser shows. SVG, which ImageIO doesn't read, is kept too.
private let webFormats: [UTType] = [.png, .jpeg, .gif, .webP]
