import Foundation

// MARK: - Configuration Manager
class Configuration {
    static let shared = Configuration()
    
    private init() {}
    
    // MARK: - API Keys
    
    /// Claude API Key from secure storage
    var claudeAPIKey: String {
        // 1. Check environment variable (development only)
        if let envKey = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // 2. Check from keychain (production - secure storage)
        if let keychainKey = KeychainHelper.retrieve(key: "claude_api_key") {
            return keychainKey
        }
        
        // 3. Return empty string (will trigger error handling)
        // DO NOT check Info.plist - prevents API key extraction from app bundle
        return ""
    }
    
    /// Check if API key is configured
    var isClaudeAPIKeyConfigured: Bool {
        return !claudeAPIKey.isEmpty
    }
    
    // MARK: - Environment Configuration
    
    /// Current environment (development, staging, production)
    var environment: AppEnvironment {
        #if DEBUG
        return .development
        #else
        if let envString = ProcessInfo.processInfo.environment["APP_ENV"] {
            return AppEnvironment(rawValue: envString.lowercased()) ?? .production
        }
        return .production
        #endif
    }
    
    /// Base URL for API requests (if needed for backend)
    var apiBaseURL: String {
        switch environment {
        case .development:
            return "https://api-dev.arkhevault.org"
        case .staging:
            return "https://api-staging.arkhevault.org"
        case .production:
            return "https://api.arkhevault.org"
        }
    }
    
    // MARK: - Feature Flags
    
    /// Enable AI features
    var aiFeaturesEnabled: Bool {
        return isClaudeAPIKeyConfigured
    }
    
    /// Enable voice-to-text
    var voiceToTextEnabled: Bool {
        return ProcessInfo.processInfo.environment["VOICE_TO_TEXT_ENABLED"] == "true"
    }
    
    /// Enable analytics
    var analyticsEnabled: Bool {
        return ProcessInfo.processInfo.environment["ANALYTICS_ENABLED"] == "true"
    }
    
    /// Enable crash reporting
    var crashReportingEnabled: Bool {
        return ProcessInfo.processInfo.environment["CRASH_REPORTING_ENABLED"] == "true"
    }
    
    // MARK: - Rate Limiting Configuration
    
    /// Maximum API requests per minute
    var maxAPIRequestsPerMinute: Int {
        if let value = ProcessInfo.processInfo.environment["MAX_API_REQUESTS_PER_MINUTE"],
           let intValue = Int(value) {
            return intValue
        }
        return 60 // Default: 60 requests per minute
    }
    
    /// Maximum API requests per hour
    var maxAPIRequestsPerHour: Int {
        if let value = ProcessInfo.processInfo.environment["MAX_API_REQUESTS_PER_HOUR"],
           let intValue = Int(value) {
            return intValue
        }
        return 1000 // Default: 1000 requests per hour
    }
    
    /// Rate limiting enabled
    var rateLimitingEnabled: Bool {
        return ProcessInfo.processInfo.environment["RATE_LIMITING_ENABLED"] == "true"
    }
}

// MARK: - App Environment
enum AppEnvironment: String {
    case development
    case staging
    case production
}

// MARK: - Keychain Helper
class KeychainHelper {
    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        
        return nil
    }
    
    static func store(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}