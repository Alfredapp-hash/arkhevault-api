import Foundation

/// Models how people actually type long-form writing — letters, essays, emails —
/// with flow bursts, word-search hesitations, and planning pauses at natural boundaries.
struct NaturalWritingCadence {
  // MARK: - Configuration

  private let baseDelay: TimeInterval
  private let minimumDelay: TimeInterval = 0.03

  // MARK: - Mutable session state

  private var charactersTyped = 0
  private var wordsSinceLastMicroPause = 0
  private var sentencesSinceDeepThought = 0
  private var burstCharactersRemaining = 0
  private var currentWordLength = 0
  private var nextDeepThoughtAfterSentences: Int
  private var nextMicroPauseAfterWords: Int

  init(wordsPerMinute: Int) {
    let wpm = max(wordsPerMinute, 40)
    baseDelay = 60.0 / (Double(wpm) * 5.0)
    nextDeepThoughtAfterSentences = Int.random(in: 2...4)
    nextMicroPauseAfterWords = Int.random(in: 4...9)
  }

  // MARK: - Public API

  /// Pause *before* typing the next character (planning, sentence openers, new paragraphs).
  mutating func pauseBefore(
    character: Character,
    previous: Character?,
    at index: Int,
    allCharacters: [Character]
  ) -> TimeInterval {
    charactersTyped = index

    if index == 0 {
      return randomRange(0.9...2.2) * openingHesitationWeight
    }

    if isParagraphStart(character: character, previous: previous, at: index, in: allCharacters) {
      burstCharactersRemaining = 0
      return randomRange(1.4...3.8)
    }

    if isSentenceStart(character: character, previous: previous, before: index, in: allCharacters) {
      return randomRange(0.18...0.55)
    }

    if character == "\"" || character == "\u{201C}" {
      return randomRange(0.12...0.35)
    }

    return 0
  }

  /// Pause *after* typing a character (punctuation reflection, flow, fatigue).
  mutating func pauseAfter(
    character: Character,
    previous: Character?,
    next: Character?
  ) -> TimeInterval {
    charactersTyped += 1
    updateWordTracking(for: character)

    if let boundaryPause = pauseAfterBoundary(character: character, previous: previous, next: next) {
      return boundaryPause
    }

    if character == " " {
      return pauseAfterSpace()
    }

        return keystrokeDelay(for: character, previous: previous)
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
      burstCharactersRemaining = Int.random(in: 18...48)

      if sentencesSinceDeepThought >= nextDeepThoughtAfterSentences {
        sentencesSinceDeepThought = 0
        nextDeepThoughtAfterSentences = Int.random(in: 2...5)
        return randomRange(1.1...2.9)
      }

      if character == "." && next == "." {
        return randomRange(0.08...0.18)
      }

      return randomRange(0.45...1.35)

    case ",":
      return randomRange(0.14...0.42)

    case ";", ":":
      return randomRange(0.22...0.58)

    case "\n":
      if next == "\n" {
        return randomRange(0.05...0.12)
      }
      if previous == "\n" {
        return nil
      }
      return randomRange(0.28...0.75)

    case "-":
      return randomRange(0.08...0.22)

    default:
      return nil
    }
  }

  // MARK: - Word & flow pauses

  private mutating func pauseAfterSpace() -> TimeInterval {
    wordsSinceLastMicroPause += 1

    if wordsSinceLastMicroPause >= nextMicroPauseAfterWords {
      wordsSinceLastMicroPause = 0
      nextMicroPauseAfterWords = Int.random(in: 5...11)

      if Double.random(in: 0...1) < 0.55 {
        return randomRange(0.22...0.72)
      }
    }

    if Double.random(in: 0...1) < 0.08 {
      return randomRange(0.35...1.05)
    }

    return keystrokeDelay(for: " ", previous: nil)
  }

  private mutating func keystrokeDelay(for character: Character, previous: Character?) -> TimeInterval {
    var delay = baseDelay * logNormalMultiplier() * fatigueMultiplier()

    if burstCharactersRemaining > 0 {
      burstCharactersRemaining -= 1
      delay *= 0.72
    }

    if let previous, commonDigraphs.contains(String([previous, character])) {
      delay *= 0.84
    }

    if currentWordLength >= 7 {
      let longWordPenalty = 1.0 + Double(currentWordLength - 6) * 0.04
      delay *= longWordPenalty
    }

    if character.isUppercase && previous == " " {
      delay *= 1.12
    }

    return max(delay, minimumDelay)
  }

  private mutating func updateWordTracking(for character: Character) {
    if character.isLetter || character.isNumber || character == "'" {
      currentWordLength += 1
    } else {
      currentWordLength = 0
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
    let beforeSpace = characters[index - 2]
    return sentenceEnders.contains(beforeSpace)
  }

  // MARK: - Helpers

  private var openingHesitationWeight: Double {
    Double.random(in: 0.85...1.15)
  }

  private func fatigueMultiplier() -> Double {
    guard charactersTyped > 1_200 else { return 1.0 }
    let extra = min(0.18, Double(charactersTyped - 1_200) / 18_000)
    return 1.0 + extra
  }

  private func randomRange(_ range: ClosedRange<Double>) -> TimeInterval {
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

// MARK: - Duration estimation for UI

enum WritingCadenceEstimator {
  /// Rough wall-clock estimate including natural pauses for letters and essays.
  static func estimatedDuration(text: String, wordsPerMinute: Double, errorRate: Double) -> TimeInterval {
    guard !text.isEmpty else { return 0 }

    let characters = Array(text)
    let count = characters.count
    let basePerChar = 60.0 / (wordsPerMinute * 5.0)

    let typingTime = Double(count) * basePerChar * 1.1
    let sentenceEnds = characters.filter { [".", "!", "?"].contains($0) }.count
    let paragraphBreaks = countParagraphs(in: text)
    let wordCount = max(1, text.split { $0.isWhitespace || $0.isNewline }.count)

    let sentencePauses = Double(sentenceEnds) * 0.75
    let paragraphPauses = Double(paragraphBreaks) * 2.4
    let microPauses = Double(wordCount) * 0.06
    let deepThoughtPauses = Double(sentenceEnds) / 3.0 * 1.8
    let openingPause = 1.4
    let typoOverhead = Double(count) * errorRate * 0.5
    let fatigueOverhead = count > 1_200 ? Double(count - 1_200) * 0.0004 : 0

    return typingTime + sentencePauses + paragraphPauses + microPauses
      + deepThoughtPauses + openingPause + typoOverhead + fatigueOverhead
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
