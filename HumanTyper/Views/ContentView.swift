import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var typingEngine: HumanTypingEngine
    @EnvironmentObject private var profileStore: TypingProfileStore
    @EnvironmentObject private var historyStore: RunHistoryStore
    @EnvironmentObject private var preferences: AppPreferences

    @State private var sourceText = ""
    @State private var textSelection = TextSelectionState()
    @State private var typingQueue: [TypingQueueItem] = []
    @State private var settings = TypingSettings()
    @State private var hasAccessibility = AccessibilityChecker.isTrusted
    @State private var showOnboarding = false
    @State private var showHistory = false
    @State private var showAbout = false
    @State private var showSummary = false
    @State private var selectedProfileID: UUID?

    private var isRunning: Bool {
        switch typingEngine.status {
        case .countdown, .typing, .stopping: return true
        default: return false
        }
    }

    private var textToType: String? {
        TextRunResolver.resolveText(
            fullText: sourceText,
            scope: settings.runScope,
            selection: textSelection,
            queue: typingQueue
        )
    }

    private var canStart: Bool {
        textToType != nil && hasAccessibility
    }

    private var startButtonTitle: String {
        switch settings.runScope {
        case .fullText: return "Type All Text"
        case .selection:
            if let selected = textSelection.selectedText(in: sourceText) {
                return "Type Selection (\(selected.count))"
            }
            return "Type Selection"
        case .fromCursor:
            if let text = textToType { return "Type From Cursor (\(text.count))" }
            return "Type From Cursor"
        case .queued:
            let count = typingQueue.map(\.text.count).reduce(0, +)
            return "Type Queue (\(count))"
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

                    if let warning = typingEngine.focusWarning {
                        focusWarningBanner(warning)
                    }

                    StatusIndicatorView(
                        status: typingEngine.status,
                        progress: typingEngine.progress,
                        totalCharacters: typingEngine.totalCharacters,
                        typedCharacters: typingEngine.typedCharacters,
                        countdownTotal: typingEngine.countdownTotal
                    )

                    PermissionsChecklistView(
                        hasAccessibility: hasAccessibility,
                        layoutName: KeyboardLayoutService.currentLayoutName,
                        targetAppName: FocusMonitor.frontmostApplicationName,
                        dryRun: preferences.dryRunEnabled
                    )

                    if preferences.dryRunEnabled {
                        DryRunLogView(log: typingEngine.latestLog)
                    }

                    HStack(alignment: .top, spacing: AppTheme.Spacing.xl) {
                        SourceTextEditorView(
                            text: $sourceText,
                            selection: $textSelection,
                            runScope: $settings.runScope,
                            queue: $typingQueue,
                            isDisabled: isRunning,
                            settings: settings
                        )
                        .frame(maxWidth: .infinity)

                        ControlsPanelView(
                            settings: $settings,
                            profileStore: profileStore,
                            selectedProfileID: $selectedProfileID,
                            preferences: preferences,
                            isDisabled: isRunning,
                            canStart: canStart,
                            isRunning: isRunning,
                            startButtonTitle: startButtonTitle,
                            onStart: startTyping,
                            onStop: { typingEngine.stop() },
                            onClear: {
                                sourceText = ""
                                textSelection = TextSelectionState()
                                typingQueue = []
                            },
                            onShowHistory: { showHistory = true },
                            onShowAbout: { showAbout = true }
                        )
                        .frame(width: 360)
                    }
                }
                .padding(AppTheme.Spacing.xxl)
            }
        }
        .frame(minWidth: 940, minHeight: 720)
        .onAppear {
            hasAccessibility = AccessibilityChecker.requestAccess(prompt: false)
            showOnboarding = !preferences.hasCompletedOnboarding
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibility = AccessibilityChecker.isTrusted
        }
        .onChange(of: typingEngine.status) { _, newStatus in
            if case .completed(let summary) = newStatus {
                historyStore.add(summary)
                showSummary = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAbout)) { _ in
            showAbout = true
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding) {
                preferences.hasCompletedOnboarding = true
            }
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(historyStore: historyStore)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showSummary) {
            if let summary = typingEngine.lastSummary {
                RunSummarySheet(summary: summary, log: typingEngine.latestLog)
            }
        }
    }

    private func startTyping() {
        guard let text = textToType else { return }
        typingEngine.start(
            text: text,
            scope: settings.runScope,
            settings: settings,
            preferences: preferences
        )
    }

    private func focusWarningBanner(_ message: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.warning)
            Text(message)
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.md, style: .continuous)
                .fill(AppTheme.warning.opacity(0.1))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HumanTypingEngine())
        .environmentObject(TypingProfileStore())
        .environmentObject(RunHistoryStore())
        .environmentObject(AppPreferences())
        .frame(width: 980, height: 760)
}
