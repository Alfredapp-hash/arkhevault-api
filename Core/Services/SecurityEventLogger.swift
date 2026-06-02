import Foundation
import os.log

// MARK: - Security Event Logger
/// Centralized security audit logging for authentication and security events
/// Logs are written to both OSLog (for system logging) and local file (for audit trail)
class SecurityEventLogger {
    static let shared = SecurityEventLogger()
    
    private let logger = OSLog(subsystem: "com.forgedinfire.clientmanager", category: "Security")
    private let logQueue = DispatchQueue(label: "com.forgedinfire.securitylog", qos: .utility)
    private let logFileURL: URL
    
    private init() {
        // Create log file in app support directory
        let fileManager = FileManager.default
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            logFileURL = fileManager.temporaryDirectory.appendingPathComponent("security.log")
            return
        }
        
        let appFolder = appSupport.appendingPathComponent("ForgedInFire")
        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)
        
        logFileURL = appFolder.appendingPathComponent("security_events.log")
    }
    
    // MARK: - Authentication Events
    
    func logAuthAttempt(success: Bool?, reason: String) {
        let event = SecurityEvent(
            type: .authentication,
            action: "auth_attempt",
            success: success,
            reason: reason,
            timestamp: Date(),
            userIdentifier: nil, // Never log actual user identifiers
            context: nil
        )
        logEvent(event)
    }
    
    func logSessionEvent(action: String, reason: String? = nil) {
        let event = SecurityEvent(
            type: .session,
            action: action,
            success: nil,
            reason: reason,
            timestamp: Date(),
            userIdentifier: nil,
            context: nil
        )
        logEvent(event)
    }
    
    func logAccessDenied(resource: String, reason: String) {
        let event = SecurityEvent(
            type: .accessControl,
            action: "access_denied",
            success: false,
            reason: reason,
            timestamp: Date(),
            userIdentifier: nil,
            context: resource
        )
        logEvent(event)
    }
    
    func logDataEvent(action: String, success: Bool, context: String? = nil) {
        let event = SecurityEvent(
            type: .dataAccess,
            action: action,
            success: success,
            reason: nil,
            timestamp: Date(),
            userIdentifier: nil,
            context: context
        )
        logEvent(event)
    }
    
    func logSystemEvent(action: String, success: Bool, reason: String? = nil) {
        let event = SecurityEvent(
            type: .system,
            action: action,
            success: success,
            reason: reason,
            timestamp: Date(),
            userIdentifier: nil,
            context: nil
        )
        logEvent(event)
    }
    
    // MARK: - Private Logging
    
    private func logEvent(_ event: SecurityEvent) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Format log entry (without sensitive data)
            let logEntry = self.formatLogEntry(event)
            
            // Write to OSLog
            os_log("%{public}@", log: self.logger, type: .info, logEntry)
            
            // Write to file
            self.writeToFile(logEntry)
        }
    }
    
    private func formatLogEntry(_ event: SecurityEvent) -> String {
        let timestamp = ISO8601DateFormatter().string(from: event.timestamp)
        let successStr = event.success.map { $0 ? "SUCCESS" : "FAILURE" } ?? "UNKNOWN"
        let reasonStr = event.reason.map { " | Reason: \($0)" } ?? ""
        let contextStr = event.context.map { " | Context: \($0)" } ?? ""
        
        return "[\(timestamp)] [\(event.type.rawValue.uppercased())] [\(successStr)] Action: \(event.action)\(reasonStr)\(contextStr)"
    }
    
    private func writeToFile(_ entry: String) {
        let fileManager = FileManager.default
        
        // Check file size and rotate if needed (> 1MB)
        if let attributes = try? fileManager.attributesOfItem(atPath: logFileURL.path),
           let fileSize = attributes[.size] as? NSNumber,
           fileSize.intValue > 1_000_000 {
            rotateLogFile()
        }
        
        // Append to log file
        if let data = (entry + "\n").data(using: .utf8) {
            if fileManager.fileExists(atPath: logFileURL.path) {
                if let handle = try? FileHandle(forWritingTo: logFileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logFileURL, options: .atomic)
            }
        }
    }
    
    private func rotateLogFile() {
        let fileManager = FileManager.default
        let backupURL = logFileURL.deletingPathExtension().appendingPathExtension("log.1")
        
        // Remove old backup if exists
        try? fileManager.removeItem(at: backupURL)
        
        // Move current to backup
        try? fileManager.moveItem(at: logFileURL, to: backupURL)
    }
    
    // MARK: - Log Retrieval (for admin/audit purposes)
    
    func retrieveLogs(since: Date? = nil, type: SecurityEventType? = nil) -> [String] {
        guard let content = try? String(contentsOf: logFileURL, encoding: .utf8) else {
            return []
        }
        
        var lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        if let since = since {
            let formatter = ISO8601DateFormatter()
            lines = lines.filter { line in
                // Extract timestamp from line
                guard let range = line.range(of: "]") else { return true }
                let timestampStr = String(line[line.startIndex...range.lowerBound])
                if let date = formatter.date(from: String(timestampStr.dropFirst().dropLast())) {
                    return date >= since
                }
                return true
            }
        }
        
        if let type = type {
            lines = lines.filter { $0.contains("[\(type.rawValue.uppercased())]") }
        }
        
        return lines
    }
    
    func exportLogs() -> URL? {
        let logs = retrieveLogs()
        let exportContent = logs.joined(separator: "\n")
        
        let tempDir = FileManager.default.temporaryDirectory
        let exportURL = tempDir.appendingPathComponent("security_audit_\(Date().timeIntervalSince1970).log")
        
        try? exportContent.write(to: exportURL, atomically: true, encoding: .utf8)
        return exportURL
    }
}

// MARK: - Security Event Models

struct SecurityEvent {
    let type: SecurityEventType
    let action: String
    let success: Bool?
    let reason: String?
    let timestamp: Date
    let userIdentifier: String? // Hashed/anonymized only
    let context: String? // Resource being accessed, etc.
}

enum SecurityEventType: String {
    case authentication
    case session
    case accessControl
    case dataAccess
    case system
    case keychain
}
