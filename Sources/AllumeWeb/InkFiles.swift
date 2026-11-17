import AllumeWebModels
import Foundation

/// Copies of the boards' ink files, written into the folder, which show translucent ink as Allume
/// does, by file name. A file that can't be read or written isn't listed, and is shown as it is.
package func makeInkFiles(of contents: Contents, in folder: URL) -> [String: Asset] {
  let files = Set(
    contents.documents.flatMap { document -> [Asset] in
      guard case .board(let board) = document else {
        return []
      }
      return board.ink.map(\.file)
    })

  let copies = files.compactMap { file -> (String, Asset)? in
    let copy = folder.appending(path: file.name)
    guard
      !leavesFolder(file.name),
      let svg = try? String(contentsOf: file.url, encoding: .utf8),
      (try? FileManager.default.createDirectory(
        at: copy.deletingLastPathComponent(), withIntermediateDirectories: true)) != nil,
      (try? Data(darkeningTranslucentInk(in: svg).utf8).write(to: copy)) != nil
    else {
      return nil
    }

    return (file.name, Asset(name: file.name, url: copy))
  }
  return Dictionary(copies, uniquingKeysWith: { first, _ in first })
}

/// Allume draws translucent ink, such as a highlighter's, darkening what's under it, so that a
/// highlight never covers writing, whichever came first. Its SVGs give only those strokes a
/// `stroke-opacity`, so the SVG's root gets a rule darkening them, within the drawing alone: WebKit
/// would otherwise darken them against what's behind the image too, hiding them on a dark page. An
/// SVG without a root to put the rule in is left as it is.
func darkeningTranslucentInk(in svg: String) -> String {
  guard let root = svg.firstMatch(of: #/<svg\b[^>]*>/#), !root.output.hasSuffix("/>") else {
    return svg
  }

  return svg[..<root.range.upperBound] + translucentInkRule + svg[root.range.upperBound...]
}

private let translucentInkRule =
  "<style>svg { isolation: isolate; } path[stroke-opacity] { mix-blend-mode: darken; }</style>"
