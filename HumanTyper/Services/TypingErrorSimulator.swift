import Foundation

enum TypingErrorKind: Equatable {
    case none
    case nearbyKey
    case transposition
    case doubledLetter
    case revision(wordLength: Int)
}

struct TypingErrorSimulator {
    private var recentTypo = false
    private var charactersSinceTypo = 0

    mutating func errorKind(
        for character: Character,
        previous: Character?,
        settings: TypingSettings,
        revisionEnabled: Bool,
        afterLongPause: Bool
    ) -> TypingErrorKind {
        charactersSinceTypo += 1

        guard character.isLetter || character.isNumber else { return .none }

        let baseRate = settings.errorRate * settings.documentMode.errorMultiplier
        guard baseRate > 0 else { return .none }

        var rate = baseRate
        if character.isUppercase || character.isNumber { rate *= 1.35 }
        if afterLongPause { rate *= 1.5 }
        if recentTypo || charactersSinceTypo < 8 { rate *= 0.35 }

        if revisionEnabled,
           character == " ",
           let previous,
           previous.isLetter,
           Double.random(in: 0...1) < settings.documentMode.revisionProbability {
            return .revision(wordLength: Int.random(in: 3...7))
        }

        guard Double.random(in: 0...1) < rate else { return .none }

        let roll = Double.random(in: 0...1)
        if roll < 0.45, let previous, previous.isLetter, character.isLetter {
            recentTypo = true
            charactersSinceTypo = 0
            return .transposition
        }
        if roll < 0.62, character.isLetter {
            recentTypo = true
            charactersSinceTypo = 0
            return .doubledLetter
        }
        if KeyCodeMap.nearbyTypo(for: character) != nil {
            recentTypo = true
            charactersSinceTypo = 0
            return .nearbyKey
        }

        return .none
    }

    mutating func markTypoResolved() {
        recentTypo = false
    }
}
