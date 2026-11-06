extension DefaultStringInterpolation {
  /// Writes `\(number: x)` in a string as the shortest digits that read back as the same number,
  /// as Swift writes them, but a whole number without its `.0`: `120`, `12.5`. Below 0.0001, Swift
  /// writes an exponent, which CSS and SVG accept.
  mutating func appendInterpolation(number: Double) {
    let text = number == 0 ? "0" : number.description

    appendLiteral(text.hasSuffix(".0") ? String(text.dropLast(2)) : text)
  }
}
