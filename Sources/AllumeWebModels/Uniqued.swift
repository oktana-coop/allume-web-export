extension Sequence {
  /// Keeps the first element for each key, in order.
  func uniqued<Key: Hashable>(on key: (Element) -> Key) -> [Element] {
    let elements = Array(self)
    let firstIndices = Dictionary(
      elements.enumerated().map { index, element in (key(element), index) },
      uniquingKeysWith: { first, _ in first }
    )
    return elements.indices
      .filter { index in firstIndices[key(elements[index])] == index }
      .map { index in elements[index] }
  }
}
