import Foundation

@MainActor
final class HumanTypingEngine: ObservableObject {
    @Published private(set) var status: TypingStatus = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var totalCharacters: Int = 0
    @Published private(set) var typedCharacters: Int = 0
    @Published private(set) var countdownTotal: Int = 5

    private var typingTask: Task<Void, Never>?

    func start(text: String, settings: TypingSettings) {
        guard !text.isEmpty else {
            status = .failed("Paste some text first.")
            return
        }

        guard AccessibilityChecker.isTrusted else {
            status = .failed("Accessibility access is required. Enable it in System Settings.")
            return
        }

        stop()
        countdownTotal = settings.countdownSeconds
        totalCharacters = text.count
        typedCharacters = 0
        progress = 0
        status = .countdown(remaining: settings.countdownSeconds)

        let countdownSeconds = settings.countdownSeconds
        let characterCount = text.count

        typingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await runCountdown(seconds: countdownSeconds)
                status = .typing
                try await Self.typeText(text, settings: settings) { index in
                    await MainActor.run {
                        self.typedCharacters = index
                        self.totalCharacters = characterCount
                        self.progress = Double(index) / Double(max(characterCount, 1))
                    }
                }
                if !Task.isCancelled {
                    status = .completed
                    progress = 1
                    typedCharacters = characterCount
                }
            } catch is CancellationError {
                status = .cancelled
            } catch {
                status = .failed(error.localizedDescription)
            }
        }
    }

    func stop() {
        typingTask?.cancel()
        typingTask = nil
        if case .typing = status {
            status = .cancelled
        } else if case .countdown = status {
            status = .cancelled
        }
    }

    private func runCountdown(seconds: Int) async throws {
        for remaining in stride(from: seconds, through: 1, by: -1) {
            try Task.checkCancellation()
            status = .countdown(remaining: remaining)
            try await Self.sleep(seconds: 1)
        }
    }

    private nonisolated static func typeText(
        _ text: String,
        settings: TypingSettings,
        onProgress: @escaping @Sendable (Int) async -> Void
    ) async throws {
        let keyboard = KeyboardSimulator.shared
        var context = HumanTypingContext(wordsPerMinute: Int(settings.wordsPerMinute))
        var previousCharacter: Character?
        let total = text.count
        var index = 0

        for character in text {
            try Task.checkCancellation()

            if shouldMakeTypo(settings: settings, character: character) {
                try await performTypoSequence(
                    intended: character,
                    context: &context,
                    previousCharacter: previousCharacter,
                    keyboard: keyboard
                )
            } else {
                keyboard.typeCharacter(character)
                try await sleep(seconds: context.nextDelay(after: character, previous: previousCharacter))
            }

            index += 1
            await onProgress(index)

            previousCharacter = character
        }

        if total == 0 {
            await onProgress(0)
        }
    }

    private nonisolated static func shouldMakeTypo(settings: TypingSettings, character: Character) -> Bool {
        guard settings.errorRate > 0 else { return false }
        guard character.isLetter || character.isNumber else { return false }
        guard KeyCodeMap.nearbyTypo(for: character) != nil else { return false }
        return Double.random(in: 0..<1) < settings.errorRate
    }

    private nonisolated static func performTypoSequence(
        intended: Character,
        context: inout HumanTypingContext,
        previousCharacter: Character?,
        keyboard: KeyboardSimulator
    ) async throws {
        guard let typo = KeyCodeMap.nearbyTypo(for: intended) else {
            keyboard.typeCharacter(intended)
            try await sleep(seconds: context.nextDelay(after: intended, previous: previousCharacter))
            return
        }

        keyboard.typeCharacter(typo)
        try await sleep(seconds: Double.random(in: 0.15...0.40))

        keyboard.backspace()
        try await sleep(seconds: Double.random(in: 0.08...0.18))

        keyboard.typeCharacter(intended)
        try await sleep(seconds: context.nextDelay(after: intended, previous: typo))
    }

    private nonisolated static func sleep(seconds: TimeInterval) async throws {
        let clamped = max(seconds, 0.03)
        let nanoseconds = UInt64(clamped * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

private struct HumanTypingContext {
    private enum Constants {
        static let logNormalSigma = 0.35
        static let punctuationMultiplier = 1.35
        static let digraphMultiplier = 0.85
        static let thinkingWordInterval = 12
        static let thinkingPauseRange: ClosedRange<Double> = 0.3...0.8
        static let commonDigraphs: Set<String> = [
            "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
            "ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar"
        ]
        static let punctuation: Set<Character> = [".", ",", "!", "?", ";", ":"]
    }

    let baseDelay: TimeInterval
    var wordsSincePause = 0

    init(wordsPerMinute: Int) {
        let normalizedWPM = max(wordsPerMinute, 40)
        baseDelay = 60.0 / (Double(normalizedWPM) * 5.0)
    }

    mutating func nextDelay(after character: Character, previous: Character?) -> TimeInterval {
        if character == " " {
            wordsSincePause += 1
            if wordsSincePause >= Constants.thinkingWordInterval {
                wordsSincePause = 0
                return Double.random(in: Constants.thinkingPauseRange)
            }
        }

        var delay = baseDelay * logNormalMultiplier()

        if let previous, Constants.commonDigraphs.contains(String([previous, character])) {
            delay *= Constants.digraphMultiplier
        }

        if Constants.punctuation.contains(character) {
            delay *= Constants.punctuationMultiplier
        }

        return max(delay, 0.03)
    }

    private func logNormalMultiplier() -> Double {
        let normal = Double.random(in: -1...1) * Constants.logNormalSigma
        return exp(normal).clamped(to: 0.7...1.4)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
