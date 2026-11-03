import Foundation

extension Document {
  public struct Comment: Equatable, Sendable {
    public let id: ID
    public let text: String
    public let authorID: User.ID?
    public let modifiedAt: Date

    public init(id: ID, text: String, authorID: User.ID?, modifiedAt: Date) {
      self.id = id
      self.text = text
      self.authorID = authorID
      self.modifiedAt = modifiedAt
    }
  }
}
