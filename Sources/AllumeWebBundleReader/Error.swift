import AllumeWebModels

package enum UnreadableBundleError: Error, Equatable, Sendable {
  case missingFile(String)
  /// A file given as the export that isn't a zip archive, by its name.
  case notAnArchive(String)
  case invalidJSON(file: String, reason: String)
  case invalidContents(InvalidContentsError)
}
