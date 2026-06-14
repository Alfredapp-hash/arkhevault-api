import Foundation

/// Models essay-writing rhythm: WPM rises and falls in waves, warms up inside
/// paragraphs, peaks mid-thought, and slows for planning at natural boundaries.
struct NaturalWritingCadence {
    // MARK: - Configuration

    private let baseDelay: TimeInterval
    private let minimumDelay: TimeInterval = 0.03

    // MARK: - Velocity model

    private enum VelocityPhase: Equatable {
        case warmingUp
        case flowing
        case careful
        case recovering
        case concluding
    }

    private var velocityMultiplier = 0.78
    private var targetVelocity = 0.78
    private var phase: VelocityPhase = .warmingUp

    // MARK: - Session state

    private var charactersTyped = 0
    private var wordsSinceLastMicroPause = 0
    private var sentencesSinceDeepThought = 0
    private var burstCharactersRemaining = 0
    private var currentWordLength = 0
    private var charactersInParagraph = 0
    private var charactersInSentence = 0
    private var wordsInParagraph = 0
    private var nextDeepThoughtAfterSentences: Int
    private var nextMicroPauseAfterWords: Int

    private let documentMode: TypingDocumentMode
    private let fullText: String
    private var currentWord = ""

    init(wordsPerMinute: Int, documentMode: TypingDocumentMode = .essay, fullText: String = "") {
        let wpm = max(wordsPerMinute, 40)
        self.documentMode = documentMode
        self.fullText = fullText
        baseDelay = 60.0 / (Double(wpm) * 5.0) / documentMode.velocityMultiplier
        nextDeepThoughtAfterSentences = Int.random(in: 2...4)
        nextMicroPauseAfterWords = Int.random(in: 4...9)
    }

    // MARK: - Public API

    mutating func pauseBefore(
        character: Character,
        previous: Character?,
        at index: Int,
        allCharacters: [Character]
    ) -> TimeInterval {
        if index == 0 {
            resetVelocity(for: .warmingUp, multiplier: randomRange(0.58...0.74))
            return randomRange(0.9...2.2) * Double.random(in: 0.85...1.15)
        }

        updateVelocityContext(
            character: character,
            previous: previous,
            at: index,
            in: allCharacters,
            moment: .before
        )

        if isParagraphStart(character: character, previous: previous, at: index, in: allCharacters) {
            charactersInParagraph = 0
            wordsInParagraph = 0
            burstCharactersRemaining = 0
            resetVelocity(for: .warmingUp, multiplier: randomRange(0.55...0.72))
            return randomRange(1.4...3.8) * documentMode.pauseMultiplier
        }

        if isSentenceStart(character: character, previous: previous, before: index, in: allCharacters) {
            charactersInSentence = 0
            nudgeVelocity(target: randomRange(0.68...0.88), phase: .warmingUp)
            return randomRange(0.18...0.55)
        }

        if character == "\"" || character == "\u{201C}" {
            nudgeVelocity(target: randomRange(0.75...0.92), phase: .careful)
            return randomRange(0.12...0.35)
        }

        return 0
    }

    mutating func pauseAfter(
        character: Character,
        previous: Character?,
        next: Character?
    ) -> TimeInterval {
        charactersTyped += 1
        charactersInParagraph += 1
        charactersInSentence += 1
        updateWordTracking(for: character)

        if character == " " {
            wordsInParagraph += 1
        }

        updateVelocityContext(
            character: character,
            previous: previous,
            at: charactersTyped - 1,
            in: [],
            moment: .after
        )

        if let boundaryPause = pauseAfterBoundary(character: character, previous: previous, next: next) {
            return boundaryPause
        }

        if character == " " {
            return pauseAfterSpace()
        }

        return keystrokeDelay(for: character, previous: previous, at: charactersTyped - 1)
    }

    // MARK: - Velocity engine

    private enum VelocityMoment {
        case before
        case after
    }

    private mutating func updateVelocityContext(
        character: Character,
        previous: Character?,
        at index: Int,
        in allCharacters: [Character],
        moment: VelocityMoment
    ) {
        switch moment {
        case .before:
            applyParagraphArc()
            applySentenceArc()
        case .after:
            if currentWordLength >= 8 {
                nudgeVelocity(target: randomRange(0.62...0.82), phase: .careful)
            } else if charactersInSentence > 12 && charactersInSentence < 55 {
                nudgeVelocity(target: randomRange(1.08...1.38), phase: .flowing)
            }
        }

        applyEssayWave()
        smoothVelocityTowardTarget()

        if character == " " && wordsInParagraph > 18 && Double.random(in: 0...1) < 0.12 {
            nudgeVelocity(target: randomRange(0.7...0.9), phase: .concluding)
        }

        _ = index
        _ = previous
        _ = allCharacters
    }

  /// Essay writers ramp up through a paragraph, peak mid-argument, then ease off.
    private mutating func applyParagraphArc() {
        switch charactersInParagraph {
        case 0...18:
            let progress = Double(charactersInParagraph) / 18.0
            let target = 0.68 + progress * 0.42
            nudgeVelocity(target: target, phase: .warmingUp)
        case 19...90:
            nudgeVelocity(target: randomRange(1.02...1.32), phase: .flowing)
        case 91...140:
            nudgeVelocity(target: randomRange(0.88...1.08), phase: .recovering)
        default:
            nudgeVelocity(target: randomRange(0.78...0.98), phase: .concluding)
        }
    }

    /// Within a sentence: cautious opener → confident middle → release at end.
    private mutating func applySentenceArc() {
        switch charactersInSentence {
        case 0...6:
            targetVelocity = min(targetVelocity, randomRange(0.72...0.9))
        case 7...40:
            if phase != .careful {
                targetVelocity = max(targetVelocity, randomRange(1.0...1.28))
            }
        default:
            targetVelocity = min(targetVelocity, randomRange(0.82...1.0))
        }
    }

    /// Slow oscillation mimics how real essay WPM drifts over minutes.
    private mutating func applyEssayWave() {
        let slowWave = sin(Double(charactersTyped) / 110.0) * 0.11
        let fastWave = sin(Double(charactersTyped) / 28.0) * 0.05
        targetVelocity = (targetVelocity + slowWave + fastWave).clamped(to: 0.52...1.42)
    }

    private mutating func resetVelocity(for newPhase: VelocityPhase, multiplier: Double) {
        phase = newPhase
        targetVelocity = multiplier
        velocityMultiplier = multiplier
    }

    private mutating func nudgeVelocity(target: Double, phase newPhase: VelocityPhase) {
        phase = newPhase
        targetVelocity = target.clamped(to: 0.52...1.42)
    }

    private mutating func smoothVelocityTowardTarget() {
        let inertia = phase == .flowing ? 0.18 : 0.12
        velocityMultiplier += (targetVelocity - velocityMultiplier) * inertia
        velocityMultiplier = velocityMultiplier.clamped(to: 0.52...1.42)
    }

    // MARK: - Boundary pauses

    private mutating func pauseAfterBoundary(
        character: Character,
        previous: Character?,
        next: Character?
    ) -> TimeInterval? {
        switch character {
        case ".", "!", "?":
            sentencesSinceDeepThought += 1
            charactersInSentence = 0
            burstCharactersRemaining = Int.random(in: 20...55)
            resetVelocity(for: .recovering, multiplier: randomRange(0.7...0.88))

            if sentencesSinceDeepThought >= nextDeepThoughtAfterSentences {
                sentencesSinceDeepThought = 0
                nextDeepThoughtAfterSentences = Int.random(in: 2...5)
                resetVelocity(for: .careful, multiplier: randomRange(0.55...0.72))
                return randomRange(1.1...2.9)
            }

            if character == "." && next == "." {
                return randomRange(0.08...0.18)
            }

            return randomRange(0.45...1.35)

        case ",":
            nudgeVelocity(target: randomRange(0.78...0.95), phase: .recovering)
            return randomRange(0.14...0.42)

        case ";", ":":
            nudgeVelocity(target: randomRange(0.7...0.88), phase: .careful)
            return randomRange(0.22...0.58)

        case "\n":
            if next == "\n" {
                return randomRange(0.05...0.12)
            }
            if previous == "\n" {
                return nil
            }
            nudgeVelocity(target: randomRange(0.75...0.92), phase: .recovering)
            return randomRange(0.28...0.75)

        case "-":
            return randomRange(0.08...0.22)

        default:
            return nil
        }
    }

    // MARK: - Word pauses

    private mutating func pauseAfterSpace() -> TimeInterval {
        wordsSinceLastMicroPause += 1

        if wordsSinceLastMicroPause >= nextMicroPauseAfterWords {
            wordsSinceLastMicroPause = 0
            nextMicroPauseAfterWords = Int.random(in: 5...11)
            nudgeVelocity(target: randomRange(0.6...0.8), phase: .careful)

            if Double.random(in: 0...1) < 0.55 {
                return randomRange(0.22...0.72)
            }
        }

        if Double.random(in: 0...1) < 0.08 {
            nudgeVelocity(target: randomRange(0.58...0.78), phase: .careful)
            return randomRange(0.35...1.05)
        }

        return keystrokeDelay(for: " ", previous: nil, at: charactersTyped)
    }

    private mutating func keystrokeDelay(for character: Character, previous: Character?, at index: Int) -> TimeInterval {
        var delay = (baseDelay / velocityMultiplier) * logNormalMultiplier() * fatigueMultiplier()

        let segment = TextStructureAnalyzer.segment(at: index, in: fullText)
        delay *= TextStructureAnalyzer.pauseMultiplier(for: segment, mode: documentMode)

        if !currentWord.isEmpty {
            delay *= WordFrequencyService.delayMultiplier(forWord: currentWord)
        }

        if burstCharactersRemaining > 0 {
            burstCharactersRemaining -= 1
            delay *= 0.68
        }

        if let previous, commonDigraphs.contains(String([previous, character])) {
            delay *= 0.84
        }

        if currentWordLength >= 7 {
            let longWordPenalty = 1.0 + Double(currentWordLength - 6) * 0.045
            delay *= longWordPenalty
        }

        if character.isUppercase && previous == " " {
            delay *= 1.1
        }

        return max(delay, minimumDelay)
    }

    private mutating func updateWordTracking(for character: Character) {
        if character.isLetter || character.isNumber || character == "'" {
            currentWordLength += 1
            currentWord.append(character)
        } else {
            currentWordLength = 0
            currentWord = ""
        }
    }

    // MARK: - Context detection

    private func isParagraphStart(
        character: Character,
        previous: Character?,
        at index: Int,
        in characters: [Character]
    ) -> Bool {
        guard character.isLetter || character.isNumber else { return false }
        guard previous == "\n", index >= 2 else { return false }
        return characters[index - 2] == "\n"
    }

    private func isSentenceStart(
        character: Character,
        previous: Character?,
        before index: Int,
        in characters: [Character]
    ) -> Bool {
        guard character.isUppercase, previous == " ", index >= 2 else { return false }
        return sentenceEnders.contains(characters[index - 2])
    }

    // MARK: - Helpers

    private func fatigueMultiplier() -> Double {
        guard charactersTyped > 1_200 else { return 1.0 }
        let extra = min(0.18, Double(charactersTyped - 1_200) / 18_000)
        return 1.0 + extra
    }

    private func randomRange(_ range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }

    private func logNormalMultiplier() -> Double {
        let sigma = 0.32
        let normal = Double.random(in: -1...1) * sigma
        return exp(normal).clamped(to: 0.68...1.38)
    }

    private let sentenceEnders: Set<Character> = [".", "!", "?"]
    private let commonDigraphs: Set<String> = [
        "th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
        "ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar",
        "st", "to", "nt", "ng", "se", "ha", "as", "ou", "io", "le"
    ]
}

// MARK: - Duration estimation

enum WritingCadenceEstimator {
    static func estimatedDuration(text: String, wordsPerMinute: Double, errorRate: Double) -> TimeInterval {
        guard !text.isEmpty else { return 0 }

        let characters = Array(text)
        let count = characters.count
        let basePerChar = 60.0 / (wordsPerMinute * 5.0)

        let typingTime = Double(count) * basePerChar * 1.18
        let sentenceEnds = characters.filter { [".", "!", "?"].contains($0) }.count
        let paragraphBreaks = countParagraphs(in: text)
        let wordCount = max(1, text.split { $0.isWhitespace || $0.isNewline }.count)

        let sentencePauses = Double(sentenceEnds) * 0.75
        let paragraphPauses = Double(paragraphBreaks) * 2.4
        let microPauses = Double(wordCount) * 0.06
        let deepThoughtPauses = Double(sentenceEnds) / 3.0 * 1.8
        let velocityVariationOverhead = Double(count) * basePerChar * 0.14
        let openingPause = 1.4
        let typoOverhead = Double(count) * errorRate * 0.5
        let fatigueOverhead = count > 1_200 ? Double(count - 1_200) * 0.0004 : 0

        return typingTime + sentencePauses + paragraphPauses + microPauses
            + deepThoughtPauses + velocityVariationOverhead + openingPause
            + typoOverhead + fatigueOverhead
    }

    private static func countParagraphs(in text: String) -> Int {
        let blocks = text.components(separatedBy: "\n\n").filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return max(blocks.count - 1, 0)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
