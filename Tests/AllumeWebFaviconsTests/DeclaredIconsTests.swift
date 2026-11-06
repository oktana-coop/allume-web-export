import Foundation
import Testing

@testable import AllumeWebFavicons

@Suite struct DeclaredIconsTests {
  @Test func putLargeIconsFirstThenOtherIconsThenTouchIcons() throws {
    let html = """
      <html><head>
      <link rel="apple-touch-icon" href="/touch.png">
      <link rel="shortcut icon" href="/small.ico">
      <link rel="icon" type="image/png" sizes="16x16 64x64" href="/large.png">
      <link rel="stylesheet" href="/style.css">
      </head></html>
      """

    let icons = declaredIcons(in: html, at: try #require(URL(string: "https://ocaml.org/learn/")))

    #expect(
      icons.map(\.absoluteString) == [
        "https://ocaml.org/large.png", "https://ocaml.org/small.ico", "https://ocaml.org/touch.png",
      ])
  }

  @Test func leaveOutSVGAndAnythingButHTTPS() throws {
    let html = """
      <head>
      <link rel="icon" href="/icon.svg">
      <link rel="icon" type="image/svg+xml" href="/icon">
      <link rel="icon" href="http://ocaml.org/icon.png">
      <link rel="icon" href="data:image/png;base64,AAAA">
      <link rel="icon" href="javascript:alert(1)">
      <link rel="mask-icon" href="/mask.png">
      <link rel=icon href=https://cdn.ocaml.org/icon.png?v=1&amp;s=2>
      </head>
      """

    let icons = declaredIcons(in: html, at: try #require(URL(string: "https://ocaml.org/")))

    #expect(icons.map(\.absoluteString) == ["https://cdn.ocaml.org/icon.png?v=1&s=2"])
  }

  @Test func readOnlyTheHead() throws {
    let html = """
      <head><title>OCaml</title></head>
      <body><link rel="icon" href="/body.png"></body>
      """

    let icons = declaredIcons(in: html, at: try #require(URL(string: "https://ocaml.org/")))

    #expect(icons.isEmpty)
  }
}
