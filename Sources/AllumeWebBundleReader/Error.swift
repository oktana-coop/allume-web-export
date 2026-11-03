import AllumeWebModels

package enum UnreadableBundleError: Error, Equatable, Sendable {
  case missingFile(String)
  case invalidJSON(file: String, reason: String)
  case invalidContents(InvalidContentsError)
}
