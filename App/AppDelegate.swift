import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure app appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        // Configure window behavior
        if let window = NSApp.windows.first {
            window.title = "Arkhe Vault - Client Management"
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // Keep app running in dock
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            // Create new window if none exist
            return true
        }
        return false
    }
}