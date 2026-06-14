import XCTest
@testable import HumanTyper

final class NaturalWritingCadenceTests: XCTestCase {
    func testOpeningPause() {
        var cadence = NaturalWritingCadence(wordsPerMinute: 60, documentMode: .essay, fullText: "Hello")
        let pause = cadence.pauseBefore(character: "H", previous: nil, at: 0, allCharacters: Array("Hello"))
        XCTAssertGreaterThan(pause, 0.5)
    }

    func testParagraphStartDetected() {
        let text = "First\n\nSecond"
        let chars = Array(text)
        var cadence = NaturalWritingCadence(wordsPerMinute: 60, documentMode: .essay, fullText: text)
        let index = text.distance(from: text.startIndex, to: text.firstIndex(of: "S")!)
        let pause = cadence.pauseBefore(
            character: "S",
            previous: "\n",
            at: index,
            allCharacters: chars
        )
        XCTAssertGreaterThan(pause, 1.0)
    }
}
