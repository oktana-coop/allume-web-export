import AllumeWebModels
import AllumeWebRendering

/// Whether the standalone site is light, dark, or follows the reader's system.
public enum SiteTheme: Sendable {
  case light
  case dark
  case system

  /// As CSS's `color-scheme`, which the board's view follows.
  var colorScheme: String {
    switch self {
    case .light: "light"
    case .dark: "dark"
    case .system: "light dark"
    }
  }
}

/// The board's view as a page of its own, with the viewer's style sheet and script. The view takes
/// the page's font and theme, and fills the window.
func standalonePage(title: String, view: String, theme: SiteTheme) -> String {
  """
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>\(escaped(title))</title>
  <link rel="stylesheet" href="allume.css">
  <style>
  :root { color-scheme: \(theme.colorScheme); }
  body { margin: 0; font-family: system-ui, -apple-system, 'Segoe UI', sans-serif; }
  main { height: 100dvh; }
  </style>
  </head>
  <body>
  <main>
  \(view)
  </main>
  <script src="allume.js"></script>
  </body>
  </html>

  """
}

/// The board's label, then the root's, except on the root's own page.
func pageTitle(of boardID: Document.ID, in index: BoardsIndex) -> String {
  let label = { (boardID: Document.ID) in index.boards[boardID]?.label ?? "" }

  return boardID == index.root
    ? label(boardID)
    : "\(label(boardID)) | \(label(index.root))"
}
