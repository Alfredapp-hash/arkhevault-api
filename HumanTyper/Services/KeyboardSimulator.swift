import Cocoa
import CoreGraphics

struct KeyStroke {
    let keyCode: CGKeyCode
    let flags: CGEventFlags
}

enum KeyCodeMap {
    private static let baseMap: [Character: KeyStroke] = [
        "a": KeyStroke(keyCode: 0x00, flags: []),
        "b": KeyStroke(keyCode: 0x0B, flags: []),
        "c": KeyStroke(keyCode: 0x08, flags: []),
        "d": KeyStroke(keyCode: 0x02, flags: []),
        "e": KeyStroke(keyCode: 0x0E, flags: []),
        "f": KeyStroke(keyCode: 0x03, flags: []),
        "g": KeyStroke(keyCode: 0x05, flags: []),
        "h": KeyStroke(keyCode: 0x04, flags: []),
        "i": KeyStroke(keyCode: 0x22, flags: []),
        "j": KeyStroke(keyCode: 0x26, flags: []),
        "k": KeyStroke(keyCode: 0x28, flags: []),
        "l": KeyStroke(keyCode: 0x25, flags: []),
        "m": KeyStroke(keyCode: 0x2E, flags: []),
        "n": KeyStroke(keyCode: 0x2D, flags: []),
        "o": KeyStroke(keyCode: 0x1F, flags: []),
        "p": KeyStroke(keyCode: 0x23, flags: []),
        "q": KeyStroke(keyCode: 0x0C, flags: []),
        "r": KeyStroke(keyCode: 0x0F, flags: []),
        "s": KeyStroke(keyCode: 0x01, flags: []),
        "t": KeyStroke(keyCode: 0x11, flags: []),
        "u": KeyStroke(keyCode: 0x20, flags: []),
        "v": KeyStroke(keyCode: 0x09, flags: []),
        "w": KeyStroke(keyCode: 0x0D, flags: []),
        "x": KeyStroke(keyCode: 0x07, flags: []),
        "y": KeyStroke(keyCode: 0x10, flags: []),
        "z": KeyStroke(keyCode: 0x06, flags: []),
        "0": KeyStroke(keyCode: 0x1D, flags: []),
        "1": KeyStroke(keyCode: 0x12, flags: []),
        "2": KeyStroke(keyCode: 0x13, flags: []),
        "3": KeyStroke(keyCode: 0x14, flags: []),
        "4": KeyStroke(keyCode: 0x15, flags: []),
        "5": KeyStroke(keyCode: 0x17, flags: []),
        "6": KeyStroke(keyCode: 0x16, flags: []),
        "7": KeyStroke(keyCode: 0x1A, flags: []),
        "8": KeyStroke(keyCode: 0x1C, flags: []),
        "9": KeyStroke(keyCode: 0x19, flags: []),
        " ": KeyStroke(keyCode: 0x31, flags: []),
        "\n": KeyStroke(keyCode: 0x24, flags: []),
        "\t": KeyStroke(keyCode: 0x30, flags: []),
        ".": KeyStroke(keyCode: 0x2F, flags: []),
        ",": KeyStroke(keyCode: 0x2B, flags: []),
        ";": KeyStroke(keyCode: 0x29, flags: []),
        "'": KeyStroke(keyCode: 0x27, flags: []),
        "[": KeyStroke(keyCode: 0x21, flags: []),
        "]": KeyStroke(keyCode: 0x1E, flags: []),
        "\\": KeyStroke(keyCode: 0x2A, flags: []),
        "/": KeyStroke(keyCode: 0x2C, flags: []),
        "-": KeyStroke(keyCode: 0x1B, flags: []),
        "=": KeyStroke(keyCode: 0x18, flags: []),
        "`": KeyStroke(keyCode: 0x32, flags: []),
        "!": KeyStroke(keyCode: 0x12, flags: .maskShift),
        "@": KeyStroke(keyCode: 0x13, flags: .maskShift),
        "#": KeyStroke(keyCode: 0x14, flags: .maskShift),
        "$": KeyStroke(keyCode: 0x15, flags: .maskShift),
        "%": KeyStroke(keyCode: 0x17, flags: .maskShift),
        "^": KeyStroke(keyCode: 0x16, flags: .maskShift),
        "&": KeyStroke(keyCode: 0x1A, flags: .maskShift),
        "*": KeyStroke(keyCode: 0x1C, flags: .maskShift),
        "(": KeyStroke(keyCode: 0x1D, flags: .maskShift),
        ")": KeyStroke(keyCode: 0x19, flags: .maskShift),
        "?": KeyStroke(keyCode: 0x2C, flags: .maskShift),
        ":": KeyStroke(keyCode: 0x29, flags: .maskShift),
        "\"": KeyStroke(keyCode: 0x27, flags: .maskShift),
        "{": KeyStroke(keyCode: 0x21, flags: .maskShift),
        "}": KeyStroke(keyCode: 0x1E, flags: .maskShift),
        "|": KeyStroke(keyCode: 0x2A, flags: .maskShift),
        "_": KeyStroke(keyCode: 0x1B, flags: .maskShift),
        "+": KeyStroke(keyCode: 0x18, flags: .maskShift),
        "~": KeyStroke(keyCode: 0x32, flags: .maskShift),
        "<": KeyStroke(keyCode: 0x2B, flags: .maskShift),
        ">": KeyStroke(keyCode: 0x2F, flags: .maskShift),
    ]

    private static let qwertyNeighbors: [Character: [Character]] = [
        "a": ["q", "w", "s", "z"],
        "b": ["v", "g", "h", "n"],
        "c": ["x", "d", "f", "v"],
        "d": ["s", "e", "r", "f", "c", "x"],
        "e": ["w", "s", "d", "r"],
        "f": ["d", "r", "t", "g", "v", "c"],
        "g": ["f", "t", "y", "h", "b", "v"],
        "h": ["g", "y", "u", "j", "n", "b"],
        "i": ["u", "j", "k", "o"],
        "j": ["h", "u", "i", "k", "m", "n"],
        "k": ["j", "i", "o", "l", "m"],
        "l": ["k", "o", "p", ";"],
        "m": ["n", "j", "k", ","],
        "n": ["b", "h", "j", "m"],
        "o": ["i", "k", "l", "p"],
        "p": ["o", "l", ";", "["],
        "q": ["w", "a", "1", "2"],
        "r": ["e", "d", "f", "t"],
        "s": ["a", "w", "e", "d", "x", "z"],
        "t": ["r", "f", "g", "y"],
        "u": ["y", "h", "j", "i"],
        "v": ["c", "f", "g", "b"],
        "w": ["q", "a", "s", "e"],
        "x": ["z", "s", "d", "c"],
        "y": ["t", "g", "h", "u"],
        "z": ["a", "s", "x"],
    ]

    static func event(for character: Character) -> KeyStroke? {
        if let stroke = baseMap[character] {
            return stroke
        }

        let lower = String(character).lowercased()
        guard let lowerChar = lower.first, let stroke = baseMap[lowerChar] else {
            return nil
        }

        if character.isUppercase {
            return KeyStroke(keyCode: stroke.keyCode, flags: [.maskShift])
        }
        return stroke
    }

    static func nearbyTypo(for character: Character) -> Character? {
        let lookup = character.isLetter ? Character(String(character).lowercased()) : character
        guard let neighbors = qwertyNeighbors[lookup], !neighbors.isEmpty else {
            return nil
        }
        let typo = neighbors.randomElement()!
        return character.isUppercase ? Character(typo.uppercased()) : typo
    }
}

final class KeyboardSimulator {
    static let shared = KeyboardSimulator()

    private let backspaceKeyCode: CGKeyCode = 0x33
    private let minimumInterKeyDelay: TimeInterval = 0.03

    private init() {}

    func typeCharacter(_ character: Character) {
        guard let stroke = KeyCodeMap.event(for: character) else { return }
        postKeyStroke(stroke)
        Thread.sleep(forTimeInterval: minimumInterKeyDelay)
    }

    func backspace() {
        postKey(keyCode: backspaceKeyCode, flags: [])
        Thread.sleep(forTimeInterval: minimumInterKeyDelay)
    }

    private func postKeyStroke(_ stroke: KeyStroke) {
        postKey(keyCode: stroke.keyCode, flags: stroke.flags)
    }

    private func postKey(keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }
}
