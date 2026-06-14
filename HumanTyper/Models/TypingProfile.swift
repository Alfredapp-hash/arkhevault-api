import Foundation

struct TypingProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var wordsPerMinute: Double
    var errorRate: Double
    var countdownSeconds: Int
    var documentMode: TypingDocumentMode
    var targetBundleID: String?

    init(
        id: UUID = UUID(),
        name: String,
        wordsPerMinute: Double = 65,
        errorRate: Double = 0.02,
        countdownSeconds: Int = 5,
        documentMode: TypingDocumentMode = .essay,
        targetBundleID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.wordsPerMinute = wordsPerMinute
        self.errorRate = errorRate
        self.countdownSeconds = countdownSeconds
        self.documentMode = documentMode
        self.targetBundleID = targetBundleID
    }

    func apply(to settings: inout TypingSettings) {
        settings.wordsPerMinute = wordsPerMinute
        settings.errorRate = errorRate
        settings.countdownSeconds = countdownSeconds
        settings.documentMode = documentMode
        settings.targetBundleID = targetBundleID
    }

    static func from(settings: TypingSettings, name: String) -> TypingProfile {
        TypingProfile(
            name: name,
            wordsPerMinute: settings.wordsPerMinute,
            errorRate: settings.errorRate,
            countdownSeconds: settings.countdownSeconds,
            documentMode: settings.documentMode,
            targetBundleID: settings.targetBundleID
        )
    }

    static let defaults: [TypingProfile] = [
        TypingProfile(name: "Slow Essay", wordsPerMinute: 45, errorRate: 0.015, documentMode: .essay),
        TypingProfile(name: "Natural Essay", wordsPerMinute: 65, errorRate: 0.02, documentMode: .essay),
        TypingProfile(name: "Quick Email", wordsPerMinute: 78, errorRate: 0.012, documentMode: .email),
        TypingProfile(name: "Fast Draft", wordsPerMinute: 95, errorRate: 0.025, documentMode: .notes),
        TypingProfile(name: "Code", wordsPerMinute: 72, errorRate: 0.008, documentMode: .code)
    ]
}

@MainActor
final class TypingProfileStore: ObservableObject {
    @Published private(set) var profiles: [TypingProfile] = []

    private let storageKey = "humanTyper.profiles"

    init() {
        load()
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([TypingProfile].self, from: data),
              !decoded.isEmpty else {
            profiles = TypingProfile.defaults
            save()
            return
        }
        profiles = decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func add(_ profile: TypingProfile) {
        profiles.append(profile)
        save()
    }

    func delete(_ profile: TypingProfile) {
        profiles.removeAll { $0.id == profile.id }
        save()
    }

    func update(_ profile: TypingProfile) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        profiles[index] = profile
        save()
    }
}
