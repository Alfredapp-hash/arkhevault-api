import Foundation

struct TypingSessionConfiguration {
    let text: String
    let scope: TypingRunScope
    let settings: TypingSettings
    let dryRun: Bool
    let soundEnabled: Bool
    let adaptiveTimingEnabled: Bool
    let revisionErrorsEnabled: Bool
}

struct TypingSessionRunner {
    struct Result {
        let summary: RunSummary
        let log: TypingRunLog
    }

    func run(
        configuration: TypingSessionConfiguration,
        onProgress: @escaping @Sendable (Int, Int) async -> Void,
        onLog: @escaping @Sendable (TypingRunLog) async -> Void
    ) async throws -> Result {
        let startedAt = Date()
        var log = TypingRunLog()
        var typoCount = 0
        var revisionCount = 0
        var pauseCount = 0

        let keyboard = KeyboardSimulator.shared
        let characters = Array(configuration.text)
        var cadence = NaturalWritingCadence(
            wordsPerMinute: Int(configuration.settings.wordsPerMinute),
            documentMode: configuration.settings.documentMode,
            fullText: configuration.text
        )
        var errorSimulator = TypingErrorSimulator()
        var adaptive = AdaptiveTimingController()
        var previousCharacter: Character?
        var typedSinceRevision: [Character] = []
        var lastPauseWasLong = false

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
                let delay = adaptive.adjusted(beforePause)
                log.append(.pause, detail: "before \(character)", delay: delay)
                pauseCount += 1
                lastPauseWasLong = delay > 0.6
                try await sleep(seconds: delay)
            }

            let errorKind = errorSimulator.errorKind(
                for: character,
                previous: previousCharacter,
                settings: configuration.settings,
                revisionEnabled: configuration.revisionErrorsEnabled,
                afterLongPause: lastPauseWasLong
            )

            switch errorKind {
            case .none:
                keyboard.typeCharacter(character, dryRun: configuration.dryRun)
                logEvent(for: keyboard, character: character, log: &log)
                TypingSoundPlayer.playKeystroke(enabled: configuration.soundEnabled)
                typedSinceRevision.append(character)

            case .nearbyKey:
                typoCount += 1
                try await performNearbyTypo(
                    intended: character,
                    keyboard: keyboard,
                    dryRun: configuration.dryRun,
                    log: &log,
                    sound: configuration.soundEnabled
                )
                errorSimulator.markTypoResolved()
                typedSinceRevision.append(character)

            case .transposition:
                typoCount += 1
                try await performNearbyTypo(
                    intended: character,
                    keyboard: keyboard,
                    dryRun: configuration.dryRun,
                    log: &log,
                    sound: configuration.soundEnabled
                )
                errorSimulator.markTypoResolved()
                typedSinceRevision.append(character)

            case .doubledLetter:
                typoCount += 1
                keyboard.typeCharacter(character, dryRun: configuration.dryRun)
                keyboard.typeCharacter(character, dryRun: configuration.dryRun)
                log.append(.typo, detail: "doubled \(character)")
                try await sleep(seconds: Double.random(in: 0.15...0.35))
                keyboard.backspace(dryRun: configuration.dryRun)
                log.append(.backspace, detail: "fix double")
                keyboard.typeCharacter(character, dryRun: configuration.dryRun)
                errorSimulator.markTypoResolved()
                typedSinceRevision.append(character)

            case .revision(let wordLength):
                revisionCount += 1
                let rewriteCount = min(wordLength, typedSinceRevision.count)
                if rewriteCount > 0 {
                    try await performRevision(
                        rewriteCount: rewriteCount,
                        intendedSpace: character,
                        keyboard: keyboard,
                        dryRun: configuration.dryRun,
                        buffer: &typedSinceRevision,
                        log: &log
                    )
                } else {
                    keyboard.typeCharacter(character, dryRun: configuration.dryRun)
                    typedSinceRevision.append(character)
                }
            }

            let afterPause = cadence.pauseAfter(
                character: character,
                previous: previousCharacter,
                next: nextCharacter
            )
            let adjustedAfter = adaptive.adjusted(afterPause)
            adaptive.registerPause(adjustedAfter, enabled: configuration.adaptiveTimingEnabled)
            if adjustedAfter > 0.05 {
                log.append(.pause, detail: "after \(character)", delay: adjustedAfter)
                pauseCount += 1
                lastPauseWasLong = adjustedAfter > 0.6
            }
            try await sleep(seconds: adjustedAfter)

            await onProgress(index + 1, characters.count)
            if index % 5 == 0 { await onLog(log) }

            previousCharacter = character
        }

        let finishedAt = Date()
        let duration = finishedAt.timeIntervalSince(startedAt)
        let words = max(1.0, Double(configuration.text.split { $0.isWhitespace || $0.isNewline }.count))
        let estimatedWPM = (words / duration) * 60.0

        let summary = RunSummary(
            startedAt: startedAt,
            finishedAt: finishedAt,
            scope: configuration.scope,
            documentMode: configuration.settings.documentMode,
            characterCount: characters.count,
            typoCount: typoCount,
            revisionCount: revisionCount,
            pauseCount: pauseCount,
            estimatedWPM: estimatedWPM,
            dryRun: configuration.dryRun,
            targetAppName: FocusMonitor.frontmostApplicationName,
            textPreview: String(configuration.text.prefix(80))
        )

        await onLog(log)
        return Result(summary: summary, log: log)
    }

    private func logEvent(for keyboard: KeyboardSimulator, character: Character, log: inout TypingRunLog) {
        if keyboard.lastMethod == "paste" {
            log.append(.paste, detail: String(character))
        } else {
            log.append(.character, detail: String(character))
        }
    }

    private func performNearbyTypo(
        intended: Character,
        keyboard: KeyboardSimulator,
        dryRun: Bool,
        log: inout TypingRunLog,
        sound: Bool
    ) async throws {
        let typo = KeyCodeMap.nearbyTypo(for: intended) ?? intended
        keyboard.typeCharacter(typo, dryRun: dryRun)
        log.append(.typo, detail: "\(typo) instead of \(intended)")
        TypingSoundPlayer.playKeystroke(enabled: sound)
        try await sleep(seconds: Double.random(in: 0.18...0.45))
        keyboard.backspace(dryRun: dryRun)
        log.append(.backspace, detail: "fix typo")
        try await sleep(seconds: Double.random(in: 0.10...0.24))
        keyboard.typeCharacter(intended, dryRun: dryRun)
        log.append(.character, detail: String(intended))
    }

    private func performRevision(
        rewriteCount: Int,
        intendedSpace: Character,
        keyboard: KeyboardSimulator,
        dryRun: Bool,
        buffer: inout [Character],
        log: inout TypingRunLog
    ) async throws {
        let removed = Array(buffer.suffix(rewriteCount))
        buffer.removeLast(rewriteCount)
        log.append(.revision, detail: "rethink \(String(removed))")
        try await sleep(seconds: Double.random(in: 0.35...0.9))

        for _ in removed {
            keyboard.backspace(dryRun: dryRun)
        }
        try await sleep(seconds: Double.random(in: 0.12...0.28))

        for char in removed {
            keyboard.typeCharacter(char, dryRun: dryRun)
            buffer.append(char)
            try await sleep(seconds: Double.random(in: 0.03...0.08))
        }

        keyboard.typeCharacter(intendedSpace, dryRun: dryRun)
        buffer.append(intendedSpace)
    }

    private func sleep(seconds: TimeInterval) async throws {
        let clamped = max(seconds, 0.03)
        try await Task.sleep(nanoseconds: UInt64(clamped * 1_000_000_000))
    }
}
