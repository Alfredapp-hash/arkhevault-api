import SwiftUI

struct ControlsPanelView: View {
    @Binding var settings: TypingSettings
    @ObservedObject var profileStore: TypingProfileStore
    @Binding var selectedProfileID: UUID?
    @ObservedObject var preferences: AppPreferences
    let isDisabled: Bool
    let canStart: Bool
    let isRunning: Bool
    let startButtonTitle: String
    let onStart: () -> Void
    let onStop: () -> Void
    let onClear: () -> Void
    let onShowHistory: () -> Void
    let onShowAbout: () -> Void

    @State private var profileName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            Label("Typing Profile", systemImage: "slider.horizontal.3")
                .font(AppTheme.headlineFont())

            profileSection

            Picker("Document mode", selection: $settings.documentMode) {
                ForEach(TypingDocumentMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .disabled(isDisabled)

            Text(settings.documentMode.description)
                .font(AppTheme.captionFont())
                .foregroundStyle(AppTheme.textTertiary)

            slidersSection
            optionsSection
            Divider().overlay(AppTheme.borderSubtle)
            actionSection
            footerLinks
        }
        .premiumCard()
    }

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Picker("Saved profile", selection: $selectedProfileID) {
                Text("Custom").tag(UUID?.none)
                ForEach(profileStore.profiles) { profile in
                    Text(profile.name).tag(Optional(profile.id))
                }
            }
            .onChange(of: selectedProfileID) { _, newValue in
                if let id = newValue, let profile = profileStore.profiles.first(where: { $0.id == id }) {
                    var updated = settings
                    profile.apply(to: &updated)
                    settings = updated
                }
            }

            HStack {
                TextField("Profile name", text: $profileName)
                    .textFieldStyle(.roundedBorder)
                Button("Save") {
                    let profile = TypingProfile.from(settings: settings, name: profileName.isEmpty ? "My Profile" : profileName)
                    profileStore.add(profile)
                    selectedProfileID = profile.id
                }
                .disabled(isDisabled)
            }
        }
    }

    private var slidersSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            PremiumSliderControl(
                icon: "speedometer",
                title: "Average WPM",
                subtitle: "Real speed varies with essay flow and pauses",
                value: $settings.wordsPerMinute,
                range: TypingSettings.wpmRange,
                step: 5,
                valueLabel: "\(Int(settings.wordsPerMinute))",
                tint: AppTheme.accent
            )
            PremiumSliderControl(
                icon: "exclamationmark.bubble",
                title: "Natural Errors",
                subtitle: "Typos, doubles, and word revisions",
                value: Binding(get: { settings.errorRate * 100 }, set: { settings.errorRate = $0 / 100 }),
                range: 0...10,
                step: 0.5,
                valueLabel: String(format: "%.1f%%", settings.errorRate * 100),
                tint: AppTheme.accentWarm
            )
            CountdownStepperControl(seconds: $settings.countdownSeconds, range: TypingSettings.countdownRange)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Toggle("Dry run (no keystrokes)", isOn: $preferences.dryRunEnabled)
            Toggle("Revision errors", isOn: $preferences.revisionErrorsEnabled)
            Toggle("Adaptive timing", isOn: $preferences.adaptiveTimingEnabled)
            Toggle("Keystroke sounds", isOn: $preferences.soundEnabled)
            Toggle("Auto-focus Microsoft Word", isOn: $preferences.autoFocusTargetEnabled)
        }
        .font(AppTheme.captionFont())
        .disabled(isDisabled)
    }

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Button(action: onStart) {
                HStack {
                    Image(systemName: preferences.dryRunEnabled ? "eye" : "play.fill")
                    Text(preferences.dryRunEnabled ? "Preview Run" : startButtonTitle)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!canStart || isRunning)
            .keyboardShortcut(.return, modifiers: .command)

            HStack {
                Button("Stop", action: onStop).buttonStyle(SecondaryActionButtonStyle()).disabled(!isRunning)
                Button("Clear", action: onClear).buttonStyle(SecondaryActionButtonStyle()).disabled(isRunning)
            }
        }
    }

    private var footerLinks: some View {
        HStack {
            Button("History", action: onShowHistory)
            Button("About", action: onShowAbout)
            Spacer()
        }
        .buttonStyle(GhostActionButtonStyle())
    }
}
