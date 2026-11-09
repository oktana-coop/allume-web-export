import AllumeWebModels

extension Document.Board {
  package var displayLabel: String {
    label ?? "Untitled board"
  }
}
