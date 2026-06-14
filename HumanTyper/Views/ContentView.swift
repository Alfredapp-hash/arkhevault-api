import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var typingEngine: HumanTypingEngine

    @State private var sourceText = ""
    @State private var textSelection = TextSelectionState()
    @State private var settings = TypingSettings()
    @State private var hasAccessibility = AccessibilityChecker.isTrusted

    private var isRunning: Bool {
        switch typingEngine.status {
        case .countdown, .typing:
            return true
        default:
            return false
        }
    }

    private var textToType: String? {
        switch settings.runScope {
        case .fullText:
            return sourceText.isEmpty ? nil : sourceText
        case .selection:
            return textSelection.selectedText(in: sourceText)
        }
    }

    private var canStart: Bool {
        textToType != nil && hasAccessibility
    }

    private var startButtonTitle: String {
        switch settings.runScope {
        case .fullText:
            return "Type All Text"
        case .selection:
            if let selected = textSelection.selectedText(in: sourceText) {
                return "Type Selection (\(selected.count))"
            }
            return "Type Selection"
        }
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    AppHeaderView(hasAccessibility: hasAccessibility)

                    if !hasAccessibility {
                        AccessibilityBannerView {
                            _ = AccessibilityChecker.requestAccess(prompt: true)
                            AccessibilityChecker.openSystemSettings()
                        }
                    }

                    StatusIndicatorView(
                        status: typingEngine.status,
                        progress: typingEngine.progress,
                        totalCharacters: typingEngine.totalCharacters,
                        typedCharacters: typingEngine.typedCharacters,
                        countdownTotal: typingEngine.countdownTotal
                    )

                    HStack(alignment: .top, spacing: AppTheme.Spacing.xl) {
                        SourceTextEditorView(
                            text: $sourceText,
                            selection: $textSelection,
                            runScope: $settings.runScope,
                            isDisabled: isRunning,
                            settings: settings
                        )
                        .frame(maxWidth: .infinity)

                        ControlsPanelView(
                            settings: $settings,
                            isDisabled: isRunning,
                            canStart: canStart,
                            isRunning: isRunning,
                            startButtonTitle: startButtonTitle,
                            onStart: startTyping,
                            onStop: { typingEngine.stop() },
                            onClear: {
                                sourceText = ""
                                textSelection = TextSelectionState()
                            }
                        )
                        .frame(width: 340)
                    }
                }
                .padding(AppTheme.Spacing.xxl)
            }
        }
        .frame(minWidth: 900, minHeight: 680)
        .onAppear {
            hasAccessibility = AccessibilityChecker.requestAccess(prompt: false)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibility = AccessibilityChecker.isTrusted
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: hasAccessibility)
        .animation(.spring(response: 0.45, dampingFraction: 0.86), value: statusKey)
    }

    private func startTyping() {
        guard let text = textToType else { return }
        typingEngine.start(text: text, scope: settings.runScope, settings: settings)
    }

    private var statusKey: String {
        switch typingEngine.status {
        case .idle: return "idle"
        case .countdown(let r): return "cd-\(r)"
        case .typing(let scope): return "typing-\(scope)-\(typingEngine.typedCharacters)"
        case .completed: return "done"
        case .cancelled: return "cancel"
        case .failed(let m): return "fail-\(m)"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HumanTypingEngine())
        .frame(width: 960, height: 720)
}
