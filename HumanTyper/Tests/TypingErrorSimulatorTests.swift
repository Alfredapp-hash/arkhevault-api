import XCTest
@testable import HumanTyper

final class TypingErrorSimulatorTests: XCTestCase {
    func testNoErrorWhenRateZero() {
        var simulator = TypingErrorSimulator()
        var settings = TypingSettings()
        settings.errorRate = 0
        let kind = simulator.errorKind(
            for: "a",
            previous: nil,
            settings: settings,
            revisionEnabled: true,
            afterLongPause: false
        )
        XCTAssertEqual(kind, .none)
    }

    func testNearbyKeyPossibleWithRate() {
        var simulator = TypingErrorSimulator()
        var settings = TypingSettings()
        settings.errorRate = 1.0
        let kind = simulator.errorKind(
            for: "a",
            previous: nil,
            settings: settings,
            revisionEnabled: false,
            afterLongPause: true
        )
        XCTAssertNotEqual(kind, .none)
    }
}
