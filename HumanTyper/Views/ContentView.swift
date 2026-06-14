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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            accessibilityBanner
            sourceSection
            controlsSection
            actionButtons
            statusSection
        }
        .padding(20)
        .onAppear {
            hasAccessibility = AccessibilityChecker.requestAccess(prompt: false)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            hasAccessibility = AccessibilityChecker.isTrusted
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Human Typer")
                .font(.largeTitle.bold())
            Text("Paste text, click Start, then switch to Word or any app before the countdown ends.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var accessibilityBanner: some View {
        if !hasAccessibility {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accessibility access required")
                        .font(.headline)
                    Text("Human Typer needs permission to type into other apps.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Open Settings") {
                    _ = AccessibilityChecker.requestAccess(prompt: true)
                    AccessibilityChecker.openSystemSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(12)
            .background(Color.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Source text")
                .font(.headline)
            TextEditor(text: $sourceText)
                .font(.body.monospaced())
                .frame(minHeight: 180)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3))
                )
                .disabled(isRunning)
        }
    }

    private var controlsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Speed")
                    .frame(width: 100, alignment: .leading)
                Slider(value: $settings.wordsPerMinute, in: TypingSettings.wpmRange, step: 5)
                Text("\(Int(settings.wordsPerMinute)) WPM")
                    .frame(width: 72, alignment: .trailing)
                    .monospacedDigit()
            }

            HStack {
                Text("Error rate")
                    .frame(width: 100, alignment: .leading)
                Slider(value: $settings.errorRate, in: TypingSettings.errorRateRange, step: 0.005)
                Text("\(Int(settings.errorRate * 100))%")
                    .frame(width: 72, alignment: .trailing)
                    .monospacedDigit()
            }

            HStack {
                Text("Countdown")
                    .frame(width: 100, alignment: .leading)
                Stepper("\(settings.countdownSeconds) seconds", value: $settings.countdownSeconds, in: TypingSettings.countdownRange)
            }
        }
        .disabled(isRunning)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Start") {
                typingEngine.start(text: sourceText, settings: settings)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning || sourceText.isEmpty || !hasAccessibility)

            Button("Stop") {
                typingEngine.stop()
            }
            .buttonStyle(.bordered)
            .disabled(!isRunning)

            Spacer()

            Button("Clear") {
                sourceText = ""
            }
            .disabled(isRunning || sourceText.isEmpty)
        }
    }

    private var statusSection: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
            Text(statusMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var statusMessage: String {
        switch typingEngine.status {
        case .idle:
            return "Ready — paste text and click Start."
        case .countdown(let remaining):
            return "Switch to your target app now… \(remaining)"
        case .typing:
            return "Typing…"
        case .completed:
            return "Done."
        case .cancelled:
            return "Cancelled."
        case .failed(let message):
            return message
        }
    }

    private var statusIcon: String {
        switch typingEngine.status {
        case .idle:
            return "circle"
        case .countdown:
            return "timer"
        case .typing:
            return "keyboard"
        case .completed:
            return "checkmark.circle.fill"
        case .cancelled:
            return "stop.circle"
        case .failed:
            return "xmark.octagon.fill"
        }
    }

    private var statusColor: Color {
        switch typingEngine.status {
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .orange
        case .countdown, .typing:
            return .blue
        case .idle:
            return .secondary
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HumanTypingEngine())
}
