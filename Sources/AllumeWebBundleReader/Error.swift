package enum UnreadableBundleError: Error, Equatable, Sendable {
  case missingFile(String)
  case invalidJSON(file: String, reason: String)
}
