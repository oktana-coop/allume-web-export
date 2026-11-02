extension AllumeBundle {
  struct Metadata: Decodable {
    let bundleVersion: Int

    enum CodingKeys: String, CodingKey {
      case bundleVersion = "bundle_version"
    }
  }

  struct Contents: Decodable {
    let documents: [String: Document]
    let root: String
    let users: [String: User]?
  }

  struct User: Decodable {
    let userFullName: String
    let color: String
    let deviceIDs: [String]?

    enum CodingKeys: String, CodingKey {
      case userFullName = "user_full_name"
      case color
      case deviceIDs = "device_ids"
    }
  }
}
