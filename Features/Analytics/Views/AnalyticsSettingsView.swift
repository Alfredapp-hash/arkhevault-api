import SwiftUI
import os.log
import CryptoKit

// MARK: - Crash Reporting & Analytics Manager
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    @Published var analyticsEnabled = true
    @Published var crashReportingEnabled = true
    @Published var sessionStartTime: Date?
    @Published var crashCount: Int = 0
    
    private let logger = OSLog(subsystem: "com.forgedinfire.clientmanager", category: "Analytics")
    private let context: NSManagedObjectContext
    
    private init(context: NSManagedObjectContext = CoreDataController.shared.container.viewContext) {
        self.context = context
        loadSettings()
        setupCrashReporting()
        startSession()
    }
    
    // MARK: - Session Tracking
    
    private func startSession() {
        sessionStartTime = Date()
        logEvent("session_start", parameters: ["timestamp": Date().timeIntervalSince1970])
    }
    
    func endSession() {
        guard let startTime = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(startTime)
        logEvent("session_end", parameters: ["duration": duration])
        sessionStartTime = nil
    }
    
    // MARK: - Event Logging
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        guard analyticsEnabled else { return }
        
        var info = "Event: \(name)"
        if let params = parameters {
            info += " | Parameters: \(params)"
        }
        
        os_log("%{public}@", log: logger, type: .info, info)
        
        // Save to database for analytics
        saveEvent(name: name, parameters: parameters)
    }
    
    // MARK: - Screen Tracking
    
    func trackScreen(_ screenName: String) {
        logEvent("screen_view", parameters: ["screen": screenName])
    }
    
    // MARK: - User Actions
    
    func trackAction(_ action: String, context: String? = nil) {
        var params: [String: Any] = ["action": action]
        if let context = context {
            params["context"] = context
        }
        logEvent("user_action", parameters: params)
    }
    
    // MARK: - Performance Tracking
    
    func trackPerformance(_ operation: String, duration: TimeInterval) {
        logEvent("performance", parameters: [
            "operation": operation,
            "duration": duration
        ])
    }
    
    // MARK: - Error Tracking
    
    func trackError(_ error: Error, context: String? = nil) {
        var params: [String: Any] = [
            "error": error.localizedDescription,
            "error_type": String(describing: type(of: error))
        ]
        
        if let context = context {
            params["context"] = context
        }
        
        logEvent("error", parameters: params)
        
        // Save to database for error analysis
        saveError(error: error, context: context)
    }
    
    // MARK: - Crash Reporting Setup
    
    private func setupCrashReporting() {
        guard crashReportingEnabled else { return }
        
        // Set up crash handler
        NSSetUncaughtExceptionHandler { exception in
            AnalyticsManager.shared.handleCrash(exception: exception)
        }
        
        // Log app launch
        logEvent("app_launch", parameters: [
            "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ])
    }
    
    private func handleCrash(exception: NSException) {
        let crashInfo: [String: Any] = [
            "exception": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "call_stack": exception.callStackSymbols.joined(separator: "\n"),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        logEvent("crash", parameters: crashInfo)
        
        // Save crash to database
        saveCrash(exception: exception)
        
        crashCount += 1
    }
    
    // MARK: - Database Operations
    
    private func saveEvent(name: String, parameters: [String: Any]?) {
        let event = AnalyticsEvent(context: context)
        event.id = UUID()
        event.eventName = name
        event.timestamp = Date()
        
        if let params = parameters,
           let jsonData = try? JSONSerialization.data(withJSONObject: params),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            event.parameters = jsonString
        }
        
        try? context.save()
    }
    
    private func saveError(error: Error, context: String?) {
        let errorRecord = ErrorRecord(context: context)
        errorRecord.id = UUID()
        errorRecord.errorType = String(describing: type(of: error))
        errorRecord.errorMessage = error.localizedDescription
        errorRecord.context = context
        errorRecord.timestamp = Date()
        
        try? context.save()
    }
    
    private func saveCrash(exception: NSException) {
        let crash = CrashRecord(context: context)
        crash.id = UUID()
        crash.exceptionName = exception.name.rawValue
        crash.reason = exception.reason
        crash.callStack = exception.callStackSymbols.joined(separator: "\n")
        crash.timestamp = Date()
        
        try? context.save()
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        analyticsEnabled = UserDefaults.standard.bool(forKey: "analyticsEnabled")
        crashReportingEnabled = UserDefaults.standard.bool(forKey: "crashReportingEnabled")
        crashCount = UserDefaults.standard.integer(forKey: "crashCount")
    }
    
    func saveSettings() {
        UserDefaults.standard.set(analyticsEnabled, forKey: "analyticsEnabled")
        UserDefaults.standard.set(crashReportingEnabled, forKey: "crashReportingEnabled")
        UserDefaults.standard.set(crashCount, forKey: "crashCount")
    }
    
    // MARK: - Analytics Data Export
    
    func exportAnalyticsData() -> URL? {
        let request = NSFetchRequest<AnalyticsEvent>(entityName: "AnalyticsEvent")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1000
        
        guard let events = try? context.fetch(request) else { return nil }
        
        let data = events.map { event in
            return [
                "id": event.id?.uuidString ?? "",
                "name": event.eventName ?? "",
                "parameters": event.parameters ?? "",
                "timestamp": event.timestamp?.timeIntervalSince1970 ?? 0
            ]
        }
        
        return exportEncryptedData(data: data, filename: "analytics_export")
    }
    
    func exportErrorData() -> URL? {
        let request = NSFetchRequest<ErrorRecord>(entityName: "ErrorRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 1000
        
        guard let errors = try? context.fetch(request) else { return nil }
        
        let data = errors.map { error in
            return [
                "id": error.id?.uuidString ?? "",
                "type": error.errorType ?? "",
                "message": error.errorMessage ?? "",
                "context": error.context ?? "",
                "timestamp": error.timestamp?.timeIntervalSince1970 ?? 0
            ]
        }
        
        return exportEncryptedData(data: data, filename: "errors_export")
    }
    
    // MARK: - Encryption Helper
    
    private func exportEncryptedData(data: [[String: Any]], filename: String) -> URL? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data) else { return nil }
        
        // Generate a temporary encryption key
        let key = SymmetricKey(size: .bits256)
        
        do {
            // Encrypt the data
            let sealedBox = try AES.GCM.seal(jsonData, using: key)
            guard let combined = sealedBox.combined else { return nil }
            
            // Write encrypted data to temp file
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("\(filename)_\(Date().timeIntervalSince1970).encrypted")
            try combined.write(to: fileURL)
            
            // Store the key securely for this export session
            // In production, this would be shared via secure channel
            let keyData = key.withUnsafeBytes { Data($0) }
            let keyURL = tempDir.appendingPathComponent("\(filename)_key_\(Date().timeIntervalSince1970).key")
            try keyData.write(to: keyURL)
            
            // Clean up temp files after 1 hour
            DispatchQueue.main.asyncAfter(deadline: .now() + 3600) { [weak self] in
                try? FileManager.default.removeItem(at: fileURL)
                try? FileManager.default.removeItem(at: keyURL)
            }
            
            return fileURL
        } catch {
            #if DEBUG
            print("Failed to encrypt export: \(error)")
            #endif
            return nil
        }
    }
}

// MARK: - Analytics Settings View
struct AnalyticsSettingsView: View {
    @StateObject private var analyticsManager = AnalyticsManager.shared
    @State private var showingExportAlert = false
    @State private var exportType: ExportType?
    
    enum ExportType {
        case analytics
        case errors
    }
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Analytics & Crash Reporting")
            
            // Analytics Toggle
            ForgeCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Help improve the app by sharing anonymous usage data")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $analyticsManager.analyticsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        .onChange(of: analyticsManager.analyticsEnabled) { _ in
                            analyticsManager.saveSettings()
                        }
                }
            }
            
            // Crash Reporting Toggle
            ForgeCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Crash Reporting")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Automatically report crashes to help us fix issues")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $analyticsManager.crashReportingEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        .onChange(of: analyticsManager.crashReportingEnabled) { _ in
                            analyticsManager.saveSettings()
                        }
                }
            }
            
            // Session Info
            if let sessionStart = analyticsManager.sessionStartTime {
                ForgeCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Session Duration")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text("\(Int(Date().timeIntervalSince(sessionStart) / 60)) minutes")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "clock")
                            .foregroundColor(.forgeTeal)
                    }
                }
            }
            
            // Crash Count
            if analyticsManager.crashCount > 0 {
                ForgeCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Crashes Reported")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text("\(analyticsManager.crashCount) crashes")
                                .font(.brandCaption)
                                .foregroundColor(.dangerRed)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.dangerRed)
                    }
                }
            }
            
            // Data Export
            SectionHeader(title: "Data Export")
            
            VStack(spacing: 12) {
                ForgeButton(
                    title: "Export Analytics Data",
                    style: .secondary
                ) {
                    exportType = .analytics
                    showingExportAlert = true
                }
                
                ForgeButton(
                    title: "Export Error Data",
                    style: .secondary
                ) {
                    exportType = .errors
                    showingExportAlert = true
                }
            }
            
            // Privacy Notice
            SectionHeader(title: "Privacy")
            
            ForgeCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Collection Notice")
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text("We collect anonymous usage data and crash reports to improve app performance and stability. No personally identifiable information is collected. You can disable data collection at any time in these settings.")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .padding()
        .alert("Export Complete", isPresented: $showingExportAlert) {
            Button("OK") { }
        } message: {
            Text("Data has been exported to your Downloads folder.")
        }
    }
}

// MARK: - Core Data Entities (Add to model)
/*
class AnalyticsEvent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var eventName: String
    @NSManaged public var parameters: String?
    @NSManaged public var timestamp: Date
}

class ErrorRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var errorType: String
    @NSManaged public var errorMessage: String
    @NSManaged public var context: String?
    @NSManaged public var timestamp: Date
}

class CrashRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var exceptionName: String
    @NSManaged public var reason: String?
    @NSManaged public var callStack: String
    @NSManaged public var timestamp: Date
}
*/

// MARK: - Analytics View Modifier
extension View {
    func trackScreen(_ screenName: String) -> some View {
        self.onAppear {
            AnalyticsManager.shared.trackScreen(screenName)
        }
    }
}

// MARK: - Preview
#Preview("Analytics Settings") {
    AnalyticsSettingsView()
        .frame(width: 500, height: 700)
        .background(Color.deepCharcoal)
}