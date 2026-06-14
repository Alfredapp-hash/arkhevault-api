import Foundation

@MainActor
final class HumanTypingEngine: ObservableObject {
    @Published private(set) var status: TypingStatus = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var totalCharacters: Int = 0
    @Published private(set) var typedCharacters: Int = 0
    @Published private(set) var countdownTotal: Int = 5
    @Published private(set) var activeScope: TypingRunScope = .fullText

    private var typingTask: Task<Void, Never>?

    func start(text: String, scope: TypingRunScope, settings: TypingSettings) {
        guard !text.isEmpty else {
            status = .failed(scope == .selection
                ? "Highlight some text in the editor first."
                : "Paste some text first.")
            return
        }

        guard AccessibilityChecker.isTrusted else {
            status = .failed("Accessibility access is required. Enable it in System Settings.")
            return
        }

        stop()
        activeScope = scope
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
                status = .typing(scope: scope)
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
        let characters = Array(text)
        var cadence = NaturalWritingCadence(wordsPerMinute: Int(settings.wordsPerMinute))
        var previousCharacter: Character?

        for index in characters.indices {
            try Task.checkCancellation()

            let character = characters[index]
            let nextCharacter = index + 1 < characters.count ? characters[index + 1] : nil

            let beforePause = cadence.pauseBefore(
                character: character,
                previous: previousCharacter,
                at: index,
                allCharacters: characters
            )
            if beforePause > 0 {
                try await sleep(seconds: beforePause)
            }

            if shouldMakeTypo(settings: settings, character: character) {
                try await performTypoSequence(
                    intended: character,
                    cadence: &cadence,
                    previousCharacter: previousCharacter,
                    keyboard: keyboard
                )
            } else {
                keyboard.typeCharacter(character)
                let afterPause = cadence.pauseAfter(
                    character: character,
                    previous: previousCharacter,
                    next: nextCharacter
                )
                try await sleep(seconds: afterPause)
            }

            await onProgress(index + 1)
            previousCharacter = character
        }

        if characters.isEmpty {
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
        cadence: inout NaturalWritingCadence,
        previousCharacter: Character?,
        keyboard: KeyboardSimulator
    ) async throws {
        guard let typo = KeyCodeMap.nearbyTypo(for: intended) else {
            keyboard.typeCharacter(intended)
            let afterPause = cadence.pauseAfter(character: intended, previous: previousCharacter, next: nil)
            try await sleep(seconds: afterPause)
            return
        }

        keyboard.typeCharacter(typo)
        try await sleep(seconds: Double.random(in: 0.18...0.45))

        keyboard.backspace()
        try await sleep(seconds: Double.random(in: 0.10...0.24))

        keyboard.typeCharacter(intended)
        let afterPause = cadence.pauseAfter(character: intended, previous: typo, next: nil)
        try await sleep(seconds: afterPause)
    }

    private nonisolated static func sleep(seconds: TimeInterval) async throws {
        let clamped = max(seconds, 0.03)
        let nanoseconds = UInt64(clamped * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
