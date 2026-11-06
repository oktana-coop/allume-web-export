@testable import AllumeWebRendering

/// A resolver that shows which reference it was given.
func describe(_ reference: Reference) -> String {
  switch reference {
  case .board(let boardID, let cardID):
    "board:\(boardID.rawValue)" + (cardID.map { cardID in "#\(cardID.rawValue)" } ?? "")
  case .file(let file):
    "file:\(file.path)"
  }
}
