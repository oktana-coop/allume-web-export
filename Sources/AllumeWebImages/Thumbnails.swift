import CoreGraphics
import Foundation
import ImageIO

/// The image at the URL, scaled down to the width with its aspect ratio kept, as JPEG, or as PNG
/// when any of its pixels is transparent. Nil when the image is no wider than that already, or
/// can't be read.
package func thumbnail(of image: URL, width: Int) -> WebImage? {
  guard let source = CGImageSourceCreateWithURL(image as CFURL, nil),
    let size = displayedSize(of: source), size.width > width,
    let scaled = drawnImage(from: source, longerSide: longerSide(of: size, scaledTo: width))
  else {
    return nil
  }

  return encoded(scaled)
}

/// The longer side's length once the width is scaled to the given one, which is how ImageIO sizes
/// thumbnails.
private func longerSide(of size: (width: Int, height: Int), scaledTo width: Int) -> Int {
  Int((Double(width) * Double(max(size.width, size.height)) / Double(size.width)).rounded())
}
