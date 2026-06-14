import AppKit
import CoreGraphics

final class PasteInjector {
    static let shared = PasteInjector()

    private init() {}

    @discardableResult
    func paste(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else { return false }

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)

        Thread.sleep(forTimeInterval: 0.05)
        return true
    }
}
