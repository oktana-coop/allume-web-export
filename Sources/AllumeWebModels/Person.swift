public struct Person: Equatable, Sendable {
  public let id: ID
  public let name: String
  public let color: RGBColor
  public let avatar: Asset?

  public init(id: ID, name: String, color: RGBColor, avatar: Asset?) {
    self.id = id
    self.name = name
    self.color = color
    self.avatar = avatar
  }

  public struct ID: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
}
