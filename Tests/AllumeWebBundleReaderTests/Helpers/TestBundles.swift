import Foundation

@testable import AllumeWebBundleReader

/// Writes a bundle to a temporary folder, with `files` in its `files` folder, and removes it once
/// `body` returns.
func withBundleFolder<T>(
  metadata: String = #"{"bundle_version" : 6}"#,
  contents: String,
  files: [String: String] = [:],
  _ body: (URL) throws -> T
) throws -> T {
  let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
  try FileManager.default.createDirectory(
    at: folder.appending(path: "files"), withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: folder) }

  try Data(metadata.utf8).write(to: folder.appending(path: "metadata.json"))
  try Data(contents.utf8).write(to: folder.appending(path: "contents.json"))
  try files.forEach { name, text in
    try Data(text.utf8).write(to: folder.appending(path: "files/\(name)"))
  }

  return try body(folder)
}

/// Like `withBundleFolder`, but hands `body` the opened bundle.
func withBundle<T>(
  contents: String,
  files: [String: String] = [:],
  _ body: (AllumeBundle) throws -> T
) throws -> T {
  try withBundleFolder(contents: contents, files: files) { folder in
    try body(AllumeBundle(contentsOf: folder))
  }
}

/// A `contents.json` holding the given entries of `documents`.
func makeContents(documents: String, users: String = "{}") -> String {
  #"{"documents" : {\#(documents)}, "root" : "root", "users" : \#(users)}"#
}
