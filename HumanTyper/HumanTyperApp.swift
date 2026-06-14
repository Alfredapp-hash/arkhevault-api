import SwiftUI

@main
struct HumanTyperApp: App {
    @StateObject private var typingEngine = HumanTypingEngine()
    @StateObject private var profileStore = TypingProfileStore()
    @StateObject private var historyStore = RunHistoryStore()
    @StateObject private var preferences = AppPreferences()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(typingEngine)
                .environmentObject(profileStore)
                .environmentObject(historyStore)
                .environmentObject(preferences)
        }
        .defaultSize(width: 980, height: 760)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Human Typer") {
                    NotificationCenter.default.post(name: .showAbout, object: nil)
                }
            }
        }

        MenuBarExtra("Human Typer", systemImage: "keyboard") {
            MenuBarControlsView()
                .environmentObject(typingEngine)
                .environmentObject(preferences)
        }
    }
}

extension Notification.Name {
    static let showAbout = Notification.Name("humanTyper.showAbout")
}

struct MenuBarControlsView: View {
    @EnvironmentObject private var typingEngine: HumanTypingEngine
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(statusLabel)
                .font(.caption)
            Toggle("Dry Run", isOn: $preferences.dryRunEnabled)
            Button("Show Window") {
                NSApp.activate(ignoringOtherApps: true)
            }
            if isRunning {
                Button("Stop") { typingEngine.stop() }
            }
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(8)
    }

    private var isRunning: Bool {
        switch typingEngine.status {
        case .countdown, .typing, .stopping: return true
        default: return false
        }
    }

    private var statusLabel: String {
        switch typingEngine.status {
        case .idle: return "Ready"
        case .countdown(let r): return "Countdown: \(r)s"
        case .typing: return "Typing…"
        case .stopping: return "Stopping…"
        case .completed: return "Complete"
        case .cancelled: return "Cancelled"
        case .failed(let m): return m
        }
    }
}
