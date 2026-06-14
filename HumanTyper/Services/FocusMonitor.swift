import AppKit

enum FocusMonitor {
    static var frontmostApplicationName: String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }

    static var frontmostBundleID: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    static var isHumanTyperFrontmost: Bool {
        frontmostBundleID == Bundle.main.bundleIdentifier
    }

    static func isTargetFocused(bundleID: String?) -> Bool {
        guard let bundleID else { return !isHumanTyperFrontmost }
        return frontmostBundleID == bundleID
    }

    @discardableResult
    static func activateTarget(bundleID: String?) -> Bool {
        guard let bundleID else { return false }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        return apps.first?.activate(options: [.activateIgnoringOtherApps]) ?? false
    }

    static func activateMicrosoftWord() -> Bool {
        activateTarget(bundleID: "com.microsoft.Word")
    }
}
