import AllumeWebModels
import Foundation
import Testing

@testable import AllumeWebBundleReader

@Suite struct UsersTests {
  @Test func readsTheFixturesUsersWithoutWarnings() throws {
    let bundle = try AllumeBundle(contentsOf: fixtureURL)

    let (users, warnings) = readUsers(in: bundle)

    let mira = users.values.first { user in user.name == "Mira Okafor" }
    let jonas = users.values.first { user in user.name == "Jonas Berg" }
    #expect(users.count == 2)
    #expect(mira?.color == RGBColor(red: 0x7f, green: 0xb3, blue: 0xd5))
    #expect(mira?.avatar?.name == "user_\(mira?.id.rawValue ?? "").png")
    #expect(jonas?.avatar == nil)
    #expect(warnings.isEmpty)
  }

  @Test func readsAnAvatarFileWithoutItsExtension() throws {
    let contents = makeContents(
      documents: "",
      users: ##"{"u" : {"user_full_name" : "Ada", "color" : "#000000", "device_ids" : []}}"##)

    let (users, warnings) = try withBundle(contents: contents, files: ["user_u": "PNG"]) {
      bundle in
      readUsers(in: bundle)
    }

    let avatar = users[User.ID(rawValue: "u")]?.avatar
    #expect(avatar?.name == "user_u.png")
    #expect(avatar?.url.path(percentEncoded: false).hasSuffix("/files/user_u") == true)
    #expect(warnings.isEmpty)
  }

  @Test func fallsBackToADefaultColor() throws {
    let contents = makeContents(
      documents: "",
      users: #"{"u" : {"user_full_name" : "Ada", "color" : "teal", "device_ids" : []}}"#)

    let (users, warnings) = try withBundle(contents: contents) { bundle in readUsers(in: bundle) }

    #expect(users[User.ID(rawValue: "u")]?.color == User.fallbackColor)
    #expect(warnings == [.invalidUserColor(User.ID(rawValue: "u"), color: "teal")])
  }
}
