import Foundation

struct AdaptiveTimingController {
    private(set) var multiplier: Double = 1.0

    mutating func registerPause(_ delay: TimeInterval, enabled: Bool) {
        guard enabled else { return }
        if delay < 0.04 {
            multiplier = min(1.35, multiplier + 0.02)
        } else if delay > 0.8 {
            multiplier = max(1.0, multiplier - 0.01)
        }
    }

    func adjusted(_ delay: TimeInterval) -> TimeInterval {
        delay * multiplier
    }
}
