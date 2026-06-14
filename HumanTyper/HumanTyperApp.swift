import SwiftUI

@main
struct HumanTyperApp: App {
    @StateObject private var typingEngine = HumanTypingEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(typingEngine)
                .frame(minWidth: 520, minHeight: 560)
        }
        .windowResizability(.contentSize)
    }
}
