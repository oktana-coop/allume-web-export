import Testing

@testable import AllumeWebRendering

@Suite struct NumbersTests {
  @Test func writeWholeNumbersWithoutAFraction() {
    #expect("\(number: 120)" == "120")
    #expect("\(number: -3)" == "-3")
    #expect("\(number: 0)" == "0")
    #expect("\(number: -0.0)" == "0")
  }

  @Test func writeTheShortestDigitsThatReadBack() {
    #expect("\(number: 12.5)" == "12.5")
    #expect("\(number: 0.1)" == "0.1")
    #expect("\(number: 1.0 / 3.0)" == "0.3333333333333333")
    #expect("\(number: 0.09737661182747888)" == "0.09737661182747888")
  }

  @Test func writeTinyNumbersWithAnExponent() {
    #expect("\(number: 0.00001)" == "1e-05")
  }

  @Test func fitInsideStyles() {
    let style = "left:\(number: 120)px;top:\(number: 7.5)px"

    #expect(style == "left:120px;top:7.5px")
  }
}
