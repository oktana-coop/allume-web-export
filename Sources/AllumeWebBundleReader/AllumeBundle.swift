import AllumeWebModels
import Foundation

/// An Allume bundle: the folder an export was written to, with its JSON decoded into the `Bundle…`
/// types but not yet read into the models. Those types decode only the keys the models need.
struct AllumeBundle {
  let folder: URL
  let metadata: BundleMetadata
  let contents: BundleContents

  var files: URL {
    folder.appending(path: "files")
  }

  init(contentsOf folder: URL) throws(UnreadableBundleError) {
    let metadataJSON = try read("metadata.json", in: folder)
    let contentsJSON = try read("contents.json", in: folder)

    self.folder = folder
    self.metadata = try decode(BundleMetadata.self, from: metadataJSON, file: "metadata.json")
    self.contents = try decode(BundleContents.self, from: contentsJSON, file: "contents.json")
  }

  func hasFile(named name: String) -> Bool {
    FileManager.default.fileExists(atPath: files.appending(path: name).path(percentEncoded: false))
  }

  /// Nil when the file is missing or isn't UTF-8.
  func text(ofFile name: String) -> String? {
    try? String(contentsOf: files.appending(path: name), encoding: .utf8)
  }

  func asset(named name: String) -> Asset {
    Asset(name: name, url: files.appending(path: name))
  }

  /// A comment's `user_id` matches no user in the export, but its `deviceId` does.
  func userID(ofDevice deviceID: String?) -> String? {
    guard let deviceID else {
      return nil
    }
    return contents.users?
      .sorted { first, second in first.key < second.key }
      .first { _, user in user.deviceIDs?.contains(deviceID) ?? false }?
      .key
  }
}

struct BundleMetadata: Decodable {
  let bundleVersion: Int

  enum CodingKeys: String, CodingKey {
    case bundleVersion = "bundle_version"
  }
}

struct BundleContents: Decodable {
  let documents: [String: BundleDocument]
  let root: String
  let users: [String: BundleUser]?
}

extension Optional where Wrapped == String {
  /// `nil` for an empty string too, as the POC treats `""` as missing.
  var nonEmpty: String? {
    flatMap { text in text.isEmpty ? nil : text }
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
