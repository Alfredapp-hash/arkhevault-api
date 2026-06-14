import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    @Published var dryRunEnabled: Bool {
        didSet { UserDefaults.standard.set(dryRunEnabled, forKey: Keys.dryRun) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.sound) }
    }

    @Published var adaptiveTimingEnabled: Bool {
        didSet { UserDefaults.standard.set(adaptiveTimingEnabled, forKey: Keys.adaptive) }
    }

    @Published var autoFocusTargetEnabled: Bool {
        didSet { UserDefaults.standard.set(autoFocusTargetEnabled, forKey: Keys.autoFocus) }
    }

    @Published var revisionErrorsEnabled: Bool {
        didSet { UserDefaults.standard.set(revisionErrorsEnabled, forKey: Keys.revision) }
    }

    private enum Keys {
        static let onboarding = "humanTyper.onboarding.complete"
        static let dryRun = "humanTyper.pref.dryRun"
        static let sound = "humanTyper.pref.sound"
        static let adaptive = "humanTyper.pref.adaptive"
        static let autoFocus = "humanTyper.pref.autoFocus"
        static let revision = "humanTyper.pref.revision"
    }

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.onboarding)
        dryRunEnabled = UserDefaults.standard.bool(forKey: Keys.dryRun)
        soundEnabled = UserDefaults.standard.bool(forKey: Keys.sound)
        adaptiveTimingEnabled = UserDefaults.standard.bool(forKey: Keys.adaptive)
        autoFocusTargetEnabled = UserDefaults.standard.bool(forKey: Keys.autoFocus)
        revisionErrorsEnabled = UserDefaults.standard.object(forKey: Keys.revision) as? Bool ?? true
    }
}
