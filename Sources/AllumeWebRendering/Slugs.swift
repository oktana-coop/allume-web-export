import AllumeWebModels
import CryptoKit
import Foundation

/// Each board's slug: its label's slug, then `-` and a code hashed from its ID, so a slug depends
/// only on its board. Boards that would share a slug get their whole ID instead of the code.
package func slugs(in contents: Contents) -> [Document.ID: String] {
  let boards = contents.hierarchy.boardIDs.map { boardID in
    (id: boardID, label: slugify(contents.board(boardID)?.displayLabel ?? ""))
  }
  let codedSlugs = boards.map { board in "\(board.label)-\(slugCode(of: board.id))" }
  let counts = Dictionary(codedSlugs.map { slug in (slug, 1) }, uniquingKeysWith: +)

  return Dictionary(
    uniqueKeysWithValues: zip(boards, codedSlugs).map { board, slug in
      (board.id, counts[slug] == 1 ? slug : "\(board.label)-\(board.id.rawValue)")
    })
}

/// Lowercase ASCII letters and digits, with `-` between runs of them, at most 60 characters long,
/// or `board` when nothing is left. Accented letters keep their base letter.
func slugify(_ text: String) -> String {
  let withoutMarks = text.decomposedStringWithCompatibilityMapping.unicodeScalars.filter {
    scalar in !(0x300...0x36F).contains(scalar.value)
  }
  let words = String(String.UnicodeScalarView(withoutMarks)).lowercased().unicodeScalars
    .split { scalar in !("a"..."z").contains(scalar) && !("0"..."9").contains(scalar) }
    .map { word in String(word) }

  let cut = String(words.joined(separator: "-").prefix(60))
  let slug = cut.hasSuffix("-") ? String(cut.dropLast()) : cut

  return slug.isEmpty ? "board" : slug
}

/// 6 characters in base 36, from the first 8 bytes of the ID's SHA-256 read as a big-endian number.
private func slugCode(of boardID: Document.ID) -> String {
  let digest = SHA256.hash(data: Data(boardID.rawValue.utf8))
  let number = digest.prefix(8).reduce(UInt64(0)) { number, byte in number << 8 | UInt64(byte) }
  let code = String(number % 2_176_782_336, radix: 36)  // 36⁶

  return String(repeating: "0", count: 6 - code.count) + code
}
