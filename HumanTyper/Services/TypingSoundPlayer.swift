import AppKit

enum TypingSoundPlayer {
    static func playKeystroke(enabled: Bool) {
        guard enabled else { return }
        if let sound = NSSound(named: "Tink") {
            sound.volume = 0.2
            sound.play()
        }
    }
}
