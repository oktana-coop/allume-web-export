import AllumeWebModels
import Foundation

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

/// Every user, as the models have them.
func readUsers(in bundle: AllumeBundle) -> (users: [User.ID: User], warnings: [BundleWarning]) {
  let results = (bundle.contents.users ?? [:])
    .sorted { first, second in first.key < second.key }
    .map { id, json in User.read(json, id: User.ID(rawValue: id), in: bundle) }

  return (
    Dictionary(uniqueKeysWithValues: results.map { result in (result.user.id, result.user) }),
    results.flatMap { result in result.warnings }
  )
}

extension User {
  /// The color the POC gives an author without one.
  static let fallbackColor = RGBColor(red: 0xd8, green: 0xb6, blue: 0x82)

  /// A color that isn't `#rrggbb` falls back to `fallbackColor`, with a warning. The avatar is the
  /// file `user_<id>`, when there is one, named with the `.png` it lacks.
  static func read(_ json: BundleUser, id: User.ID, in bundle: AllumeBundle)
    -> (user: User, warnings: [BundleWarning])
  {
    let color = rgbColor(hex: json.color)
    let avatarFile = "user_\(id.rawValue)"
    let avatar =
      bundle.hasFile(named: avatarFile)
      ? Asset(name: "\(avatarFile).png", url: bundle.files.appending(path: avatarFile)) : nil

    let user = User(
      id: id, name: json.userFullName, color: color ?? fallbackColor, avatar: avatar)

    return (user, color == nil ? [.invalidUserColor(id, color: json.color)] : [])
  }
}

/// Nil unless it's `#` and six hexadecimal digits.
private func rgbColor(hex: String) -> RGBColor? {
  guard hex.count == 7, hex.first == "#", let value = UInt32(hex.dropFirst(), radix: 16) else {
    return nil
  }
  return RGBColor(
    red: UInt8((value >> 16) & 0xff), green: UInt8((value >> 8) & 0xff), blue: UInt8(value & 0xff))
}
