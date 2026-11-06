import Foundation

/// The icons a page's `<head>` declares, best first: icons of 32 px or more, then other icons, then
/// Apple's touch icons. Only `https:` ones, and no SVG, which would be refused anyway. The page is
/// only scanned, never rendered or run.
func declaredIcons(in html: String, at pageURL: URL) -> [URL] {
  let head =
    html.firstRange(of: /<\/head/.ignoresCase()).map { end in html[..<end.lowerBound] }
    ?? html[...]

  return head.matches(of: /<link\b[^>]*>/.ignoresCase())
    .compactMap { match in candidate(String(match.output), at: pageURL) }
    .enumerated()
    .sorted { a, b in (a.element.rank, a.offset) < (b.element.rank, b.offset) }
    .map { _, candidate in candidate.url }
}

private func candidate(_ tag: String, at pageURL: URL) -> (url: URL, rank: Int)? {
  let rel = Set(
    (attribute("rel", of: tag) ?? "").lowercased().split(whereSeparator: \.isWhitespace))
  guard let href = attribute("href", of: tag),
    let url = URL(string: href, relativeTo: pageURL)?.absoluteURL, url.scheme == "https",
    !(attribute("type", of: tag) ?? "").lowercased().contains("svg"),
    !url.path(percentEncoded: false).lowercased().hasSuffix(".svg")
  else {
    return nil
  }

  if rel.contains("icon") {
    return (url, (largestSize(in: tag) ?? 0) >= 32 ? 0 : 1)
  }
  return rel.contains("apple-touch-icon") ? (url, 2) : nil
}

/// The width of the largest of the `sizes` it declares, as in `sizes="16x16 32x32"`.
private func largestSize(in tag: String) -> Int? {
  (attribute("sizes", of: tag) ?? "").matches(of: /(\d+)[xX]\d+/)
    .compactMap { match in Int(match.output.1) }.max()
}

private func attribute(_ name: String, of tag: String) -> String? {
  guard
    let pattern = try? Regex(#"\s\#(name)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))"#),
    let match = tag.firstMatch(of: pattern.ignoresCase())
  else {
    return nil
  }

  return (1...3).lazy.compactMap { index in match.output[index].substring }.first
    .map { value in value.replacingOccurrences(of: "&amp;", with: "&") }
}
