import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var typingEngine: HumanTypingEngine

    @State private var sourceText = ""
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

    private var canStart: Bool {
        !sourceText.isEmpty && hasAccessibility
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
                            isDisabled: isRunning,
                            settings: settings
                        )
                        .frame(maxWidth: .infinity)

                        ControlsPanelView(
                            settings: $settings,
                            isDisabled: isRunning,
                            canStart: canStart,
                            isRunning: isRunning,
                            onStart: { typingEngine.start(text: sourceText, settings: settings) },
                            onStop: { typingEngine.stop() },
                            onClear: { sourceText = "" }
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

    private var statusKey: String {
        switch typingEngine.status {
        case .idle: return "idle"
        case .countdown(let r): return "cd-\(r)"
        case .typing: return "typing-\(typingEngine.typedCharacters)"
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
