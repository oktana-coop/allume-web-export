struct BundleUser: Decodable {
  let userFullName: String
  let color: String
  let deviceIDs: [String]?

  enum CodingKeys: String, CodingKey {
    case userFullName = "user_full_name"
    case color
    case deviceIDs = "device_ids"
  }
}
