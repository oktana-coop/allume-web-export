import AllumeWebModels
import AllumeWebRendering

/// The board's view as a page of its own, with the viewer's style sheet and script. The view takes
/// the page's font, and fills the window.
func standalonePage(title: String, view: String) -> String {
  """
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>\(escaped(title))</title>
  <link rel="stylesheet" href="allume.css">
  <style>
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
func pageTitle(of boardID: Document.ID, in contents: Contents) -> String {
  let label = { (boardID: Document.ID) in contents.board(boardID)?.displayLabel ?? "" }

  return boardID == contents.rootID
    ? label(boardID)
    : "\(label(boardID)) | \(label(contents.rootID))"
}
