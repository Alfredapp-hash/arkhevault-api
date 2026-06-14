import AppKit
import SwiftUI

struct TextSelectionState: Equatable {
    var range: NSRange = NSRange(location: NSNotFound, length: 0)

    var hasSelection: Bool {
        range.location != NSNotFound && range.length > 0
    }

    func selectedText(in fullText: String) -> String? {
        guard hasSelection else { return nil }
        let nsText = fullText as NSString
        guard NSMaxRange(range) <= nsText.length else { return nil }
        let substring = nsText.substring(with: range)
        return substring.isEmpty ? nil : substring
    }
}

struct SelectableTextEditor: NSViewRepresentable {
    @Binding var text: String
    @Binding var selection: TextSelectionState
    var isDisabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        configure(textView, context: context)
        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.parent = self
        textView.isEditable = !isDisabled
        textView.isSelectable = true

        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            if selected.location <= (text as NSString).length {
                textView.setSelectedRange(selected)
            }
        }
    }

    private func configure(_ textView: NSTextView, context: Context) {
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 4, height: 8)
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SelectableTextEditor

        init(parent: SelectableTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            sync(from: notification)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            syncSelection(from: notification)
        }

        private func sync(from notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            parent.selection.range = textView.selectedRange()
        }

        private func syncSelection(from notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.selection.range = textView.selectedRange()
        }
    }
}
