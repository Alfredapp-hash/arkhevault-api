import Foundation

enum KeyboardLayoutService {
    static var currentLayoutName: String {
        KeyCodeMap.event(for: "a") != nil ? "QWERTY (mapped)" : "System"
    }

    static func keyStroke(for character: Character) -> KeyStroke? {
        KeyCodeMap.event(for: character)
    }
}
