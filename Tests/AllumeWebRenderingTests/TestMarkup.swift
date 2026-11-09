import Foundation

/// HTML written over indented lines, joined the way it's rendered: without the indentation, and
/// without breaks around tags. A line that continues a tag or text is joined with a space.
func markup(_ lines: String) -> String {
  lines.split(separator: "\n")
    .map { line in line.trimmingCharacters(in: .whitespaces) }
    .filter { line in !line.isEmpty }
    .reduce("") { joined, line in
      joined.isEmpty || joined.hasSuffix(">") || line.hasPrefix("<")
        ? joined + line : joined + " " + line
    }
}

/// An icon as cards and menus draw it, without a class.
func iconMarkup(_ name: String) -> String {
  markup(
    #"""
    <svg width="14" height="14" aria-hidden="true"><use href="#allume-icon-\#(name)"/></svg>
    """#)
}

let copyButtonMarkup = markup(
  #"""
  <button type="button" class="allume-copy" aria-label="Copy text">
    <svg class="allume-icon-copy" width="14" height="14" aria-hidden="true">
      <use href="#allume-icon-copy"/>
    </svg>
    <svg class="allume-icon-copied" width="14" height="14" aria-hidden="true">
      <use href="#allume-icon-copied"/>
    </svg>
  </button>
  """#)
