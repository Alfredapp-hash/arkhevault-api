import Foundation

@MainActor
final class HumanTypingEngine: ObservableObject {
    @Published private(set) var status: TypingStatus = .idle
    @Published private(set) var progress: Double = 0
    @Published private(set) var totalCharacters: Int = 0
    @Published private(set) var typedCharacters: Int = 0
    @Published private(set) var countdownTotal: Int = 5
    @Published private(set) var activeScope: TypingRunScope = .fullText
    @Published private(set) var latestLog = TypingRunLog()
    @Published private(set) var focusWarning: String?
    @Published private(set) var lastSummary: RunSummary?

    private var typingTask: Task<Void, Never>?
    private let sessionRunner = TypingSessionRunner()

    func start(
        text: String,
        scope: TypingRunScope,
        settings: TypingSettings,
        preferences: AppPreferences
    ) {
        guard !text.isEmpty else {
            status = .failed(scopeFailureMessage(scope))
            return
        }

        guard AccessibilityChecker.isTrusted else {
            status = .failed("Accessibility access is required. Enable it in System Settings.")
            return
        }

        if preferences.autoFocusTargetEnabled {
            if let bundleID = settings.targetBundleID {
                _ = FocusMonitor.activateTarget(bundleID: bundleID)
            } else if settings.documentMode == .essay {
                _ = FocusMonitor.activateMicrosoftWord()
            }
        }

        stop()
        activeScope = scope
        countdownTotal = settings.countdownSeconds
        totalCharacters = text.count
        typedCharacters = 0
        progress = 0
        latestLog = TypingRunLog()
        focusWarning = nil
        status = .countdown(remaining: settings.countdownSeconds)

        let configuration = TypingSessionConfiguration(
            text: text,
            scope: scope,
            settings: settings,
            dryRun: preferences.dryRunEnabled,
            soundEnabled: preferences.soundEnabled,
            adaptiveTimingEnabled: preferences.adaptiveTimingEnabled,
            revisionErrorsEnabled: preferences.revisionErrorsEnabled
        )

        typingTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await runCountdown(seconds: settings.countdownSeconds, settings: settings)
                status = .typing(scope: scope)

                let result = try await sessionRunner.run(configuration: configuration) { typed, total in
                    await MainActor.run {
                        self.typedCharacters = typed
                        self.totalCharacters = total
                        self.progress = Double(typed) / Double(max(total, 1))
                    }
                } onLog: { log in
                    await MainActor.run { self.latestLog = log }
                }

                if !Task.isCancelled {
                    lastSummary = result.summary
                    status = .completed(summary: result.summary)
                    progress = 1
                    typedCharacters = text.count
                }
            } catch is CancellationError {
                status = .cancelled
            } catch {
                status = .failed(error.localizedDescription)
            }
        }
    }

    func stop() {
        if case .typing = status {
            status = .stopping
        }
        typingTask?.cancel()
        typingTask = nil
        if case .stopping = status {
            status = .cancelled
        } else if case .countdown = status {
            status = .cancelled
        }
    }

    private func runCountdown(seconds: Int, settings: TypingSettings) async throws {
        for remaining in stride(from: seconds, through: 1, by: -1) {
            try Task.checkCancellation()
            status = .countdown(remaining: remaining)
            updateFocusWarning(settings: settings)
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }

    private func updateFocusWarning(settings: TypingSettings) {
        if FocusMonitor.isHumanTyperFrontmost {
            focusWarning = "Switch to your target app — Human Typer is still frontmost."
        } else if let bundleID = settings.targetBundleID,
                  !FocusMonitor.isTargetFocused(bundleID: bundleID) {
            focusWarning = "Expected target app is not focused."
        } else {
            focusWarning = nil
        }
    }

    private func scopeFailureMessage(_ scope: TypingRunScope) -> String {
        switch scope {
        case .fullText: return "Paste some text first."
        case .selection: return "Highlight some text in the editor first."
        case .fromCursor: return "Place the cursor or highlight from where typing should begin."
        case .queued: return "Add one or more sections to the queue first."
        }
    }
}
