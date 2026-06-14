import SwiftUI

@main
struct HumanTyperApp: App {
    @StateObject private var typingEngine = HumanTypingEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(typingEngine)
        }
        .defaultSize(width: 960, height: 720)
        .windowResizability(.contentMinSize)
    }
}
