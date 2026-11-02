import Foundation

/// An Allume bundle: the folder an export was written to, with its JSON decoded but not yet
/// translated into the models. Each nested type decodes only the keys the translation uses.
struct AllumeBundle {
  let folder: URL
  let metadata: Metadata
  let contents: Contents

  init(contentsOf folder: URL) throws(UnreadableBundleError) {
    let metadataJSON = try read("metadata.json", in: folder)
    let contentsJSON = try read("contents.json", in: folder)

    self.folder = folder
    self.metadata = try decode(Metadata.self, from: metadataJSON, file: "metadata.json")
    self.contents = try decode(Contents.self, from: contentsJSON, file: "contents.json")
  }
}

private func read(_ file: String, in folder: URL) throws(UnreadableBundleError) -> Data {
  do {
    return try Data(contentsOf: folder.appending(path: file))
  } catch {
    throw .missingFile(file)
  }
}

private func decode<T: Decodable>(
  _ type: T.Type, from json: Data, file: String
) throws(UnreadableBundleError) -> T {
  do {
    return try JSONDecoder().decode(type, from: json)
  } catch {
    throw .invalidJSON(file: file, reason: describe(error))
  }
}

/// Says where decoding failed, as a path of keys and indices, then what went wrong there, e.g.
/// `documents.a.cards.Index 1.position_x: Expected to decode Double but found a string instead.`
private func describe(_ error: any Error) -> String {
  switch error as? DecodingError {
  // Every kind of decoding error carries a context: where it failed, and what went wrong.
  case .typeMismatch(_, let context),
    .valueNotFound(_, let context),
    .keyNotFound(_, let context),
    .dataCorrupted(let context):
    let path = context.codingPath.map { key in key.stringValue }.joined(separator: ".")

    return path.isEmpty ? context.debugDescription : "\(path): \(context.debugDescription)"

  // Not a decoding error, or a kind of decoding error a later Swift adds.
  default:
    return error.localizedDescription
  }
}
