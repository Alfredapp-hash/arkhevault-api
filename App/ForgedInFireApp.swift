import SwiftUI

@main
struct ForgedInFireApp: App {
    @StateObject private var dataController = CoreDataController.shared
    @StateObject private var authenticationManager = AuthenticationManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authenticationManager.isAuthenticated {
                MainWindow()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authenticationManager)
            } else {
                LoginView()
                    .environment(\.managedObjectContext, dataController.container.viewContext)
                    .environmentObject(authenticationManager)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}