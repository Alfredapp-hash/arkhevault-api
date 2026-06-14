import XCTest
@testable import HumanTyper

final class TextRunResolverTests: XCTestCase {
    func testFullText() {
        let text = "Hello world"
        let result = TextRunResolver.resolveText(
            fullText: text,
            scope: .fullText,
            selection: TextSelectionState(),
            queue: []
        )
        XCTAssertEqual(result, text)
    }

    func testSelection() {
        let text = "Hello world"
        var selection = TextSelectionState()
        selection.range = NSRange(location: 6, length: 5)
        let result = TextRunResolver.resolveText(
            fullText: text,
            scope: .selection,
            selection: selection,
            queue: []
        )
        XCTAssertEqual(result, "world")
    }

    func testFromCursor() {
        let text = "Hello world"
        var selection = TextSelectionState()
        selection.range = NSRange(location: 6, length: 0)
        let result = TextRunResolver.resolveText(
            fullText: text,
            scope: .fromCursor,
            selection: selection,
            queue: []
        )
        XCTAssertEqual(result, "world")
    }

    func testQueue() {
        let items = [
            TypingQueueItem(text: "Hi", label: "A"),
            TypingQueueItem(text: " there", label: "B")
        ]
        let result = TextRunResolver.resolveText(
            fullText: "",
            scope: .queued,
            selection: TextSelectionState(),
            queue: items
        )
        XCTAssertEqual(result, "Hi there")
    }
}
