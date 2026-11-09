import AllumeWebImages
import CoreGraphics
import Foundation
import WebKit

#if canImport(AppKit)
  import AppKit
#else
  import UIKit
#endif

/// The light or dark appearance of the system a page is drawn on.
package enum Appearance: Sendable {
  case light
  case dark
}

/// The page in the file as WebKit draws it in a window of the size, in CSS pixels, once its images
/// have loaded, scaled to the width in pixels. The appearance is the system's, which a page that
/// declares `color-scheme: light dark` follows, as do SVG images. The page's own scripts don't run.
/// Nil when the page can't be loaded or drawn.
@MainActor
package func snapshot(of page: URL, size: CGSize, appearance: Appearance, width: Int) async
  -> WebImage?
{
  let configuration = WKWebViewConfiguration()
  configuration.defaultWebpagePreferences.allowsContentJavaScript = false
  let webView = WKWebView(frame: CGRect(origin: .zero, size: size), configuration: configuration)
  setAppearance(appearance, of: webView)
  let navigation = Navigation()
  webView.navigationDelegate = navigation

  let loaded = await withCheckedContinuation { continuation in
    navigation.continuation = continuation
    webView.loadFileURL(page, allowingReadAccessTo: page.deletingLastPathComponent())
  }
  guard loaded else {
    return nil
  }

  // Lazy images load only once shown, which a window that isn't on screen may never do.
  _ = try? await webView.callAsyncJavaScript(
    """
    await Promise.all([...document.images].map((image) => {
      image.loading = 'eager';
      return image.decode().catch(() => {});
    }));
    """, contentWorld: .defaultClient)
  guard let drawn = try? await webView.takeSnapshot(configuration: nil),
    let image = cgImage(of: drawn), let scaled = scaled(image, toWidth: width)
  else {
    return nil
  }

  return encoded(scaled)
}

/// Whether the page loaded, once WebKit says.
@MainActor
private final class Navigation: NSObject, WKNavigationDelegate {
  var continuation: CheckedContinuation<Bool, Never>?

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    resume(loaded: true)
  }

  func webView(
    _ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error
  ) {
    resume(loaded: false)
  }

  func webView(
    _ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: any Error
  ) {
    resume(loaded: false)
  }

  private func resume(loaded: Bool) {
    continuation?.resume(returning: loaded)
    continuation = nil
  }
}

@MainActor
private func setAppearance(_ appearance: Appearance, of webView: WKWebView) {
  #if canImport(AppKit)
    webView.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
  #else
    webView.overrideUserInterfaceStyle = appearance == .dark ? .dark : .light
  #endif
}

#if canImport(AppKit)
  private func cgImage(of image: NSImage) -> CGImage? {
    image.cgImage(forProposedRect: nil, context: nil, hints: nil)
  }
#else
  private func cgImage(of image: UIImage) -> CGImage? {
    image.cgImage
  }
#endif

/// The image redrawn the width wide, keeping its proportions. The snapshot is as many pixels wide
/// as the screen's density makes it.
private func scaled(_ image: CGImage, toWidth width: Int) -> CGImage? {
  let height = Int((Double(image.height) * Double(width) / Double(image.width)).rounded())
  guard let space = CGColorSpace(name: CGColorSpace.sRGB),
    let context = CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space,
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
  else {
    return nil
  }

  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  return context.makeImage()
}
