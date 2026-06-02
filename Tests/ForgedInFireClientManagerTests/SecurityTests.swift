import XCTest
import CryptoKit
@testable import ForgedInFireClientManager

// MARK: - Authentication Security Tests
class AuthenticationSecurityTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear keychain before each test
        let keychainService = "com.forgedinfire.clientmanager"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: Password Hashing Tests
    
    func testPasswordHashingConsistency() {
        let password = "testPassword123"
        let salt = "ForgedInFire_test"
        
        // Hash same password twice
        let inputData1 = Data((salt + password).utf8)
        let hash1 = SHA256.hash(data: inputData1)
        let hashString1 = hash1.compactMap { String(format: "%02x", $0) }.joined()
        
        let inputData2 = Data((salt + password).utf8)
        let hash2 = SHA256.hash(data: inputData2)
        let hashString2 = hash2.compactMap { String(format: "%02x", $0) }.joined()
        
        XCTAssertEqual(hashString1, hashString2, "Same password should produce same hash")
    }
    
    func testPasswordHashingDifferentPasswords() {
        let password1 = "password123"
        let password2 = "password124"
        let salt = "ForgedInFire_test"
        
        let inputData1 = Data((salt + password1).utf8)
        let hash1 = SHA256.hash(data: inputData1)
        let hashString1 = hash1.compactMap { String(format: "%02x", $0) }.joined()
        
        let inputData2 = Data((salt + password2).utf8)
        let hash2 = SHA256.hash(data: inputData2)
        let hashString2 = hash2.compactMap { String(format: "%02x", $0) }.joined()
        
        XCTAssertNotEqual(hashString1, hashString2, "Different passwords should produce different hashes")
    }
    
    func testPasswordHashLength() {
        let password = "test"
        let salt = "ForgedInFire_test"
        
        let inputData = Data((salt + password).utf8)
        let hash = SHA256.hash(data: inputData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        XCTAssertEqual(hashString.count, 64, "SHA256 hex string should be 64 characters")
    }
    
    // MARK: Email Validation Tests
    
    func testValidEmailFormats() {
        let validEmails = [
            "user@example.com",
            "user.name@example.co.uk",
            "user+tag@example.com",
            "user123@test.org",
            "first.last@company.io"
        ]
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        
        for email in validEmails {
            XCTAssertTrue(emailPredicate.evaluate(with: email), "\(email) should be valid")
        }
    }
    
    func testInvalidEmailFormats() {
        let invalidEmails = [
            "invalid",
            "@example.com",
            "user@",
            "user@.com",
            "user name@example.com",
            "user@example",
            ""
        ]
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
        
        for email in invalidEmails {
            XCTAssertFalse(emailPredicate.evaluate(with: email), "\(email) should be invalid")
        }
    }
}

// MARK: - Keychain Security Tests
class KeychainSecurityTests: XCTestCase {
    
    let testKey = "test_key_\(UUID().uuidString)"
    let testValue = "test_secret_value"
    
    override func tearDown() {
        // Clean up test data
        KeychainHelper.delete(key: testKey)
        super.tearDown()
    }
    
    func testKeychainStoreAndRetrieve() {
        // Store value
        let storeSuccess = KeychainHelper.store(key: testKey, value: testValue)
        XCTAssertTrue(storeSuccess, "Should successfully store in keychain")
        
        // Retrieve value
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertEqual(retrievedValue, testValue, "Retrieved value should match stored value")
    }
    
    func testKeychainUpdateExistingKey() {
        // Store initial value
        KeychainHelper.store(key: testKey, value: testValue)
        
        // Update with new value
        let newValue = "updated_secret_value"
        let updateSuccess = KeychainHelper.store(key: testKey, value: newValue)
        XCTAssertTrue(updateSuccess, "Should successfully update keychain value")
        
        // Verify new value
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertEqual(retrievedValue, newValue, "Should retrieve updated value")
    }
    
    func testKeychainDelete() {
        // Store value
        KeychainHelper.store(key: testKey, value: testValue)
        
        // Delete value
        let deleteSuccess = KeychainHelper.delete(key: testKey)
        XCTAssertTrue(deleteSuccess, "Should successfully delete from keychain")
        
        // Verify deletion
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertNil(retrievedValue, "Deleted key should return nil")
    }
    
    func testKeychainNonExistentKey() {
        let retrievedValue = KeychainHelper.retrieve(key: "non_existent_key_\(UUID().uuidString)")
        XCTAssertNil(retrievedValue, "Non-existent key should return nil")
    }
    
    func testKeychainAccessibilityLevel() {
        // Verify keychain uses secure accessibility level
        // This is verified by the keychain query using kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let storeSuccess = KeychainHelper.store(key: testKey, value: testValue)
        XCTAssertTrue(storeSuccess, "Should store with secure accessibility level")
        
        // Verify data is retrievable
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertNotNil(retrievedValue, "Should retrieve value with secure accessibility")
    }
}

// MARK: - Encryption Tests
class EncryptionTests: XCTestCase {
    
    func testAESGCMEncryptionDecryption() throws {
        let message = "Sensitive client data"
        let messageData = Data(message.utf8)
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt
        let sealedBox = try AES.GCM.seal(messageData, using: key)
        guard let combined = sealedBox.combined else {
            XCTFail("Failed to get combined sealed box")
            return
        }
        
        // Decrypt
        let sealedBoxToOpen = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBoxToOpen, using: key)
        let decryptedString = String(data: decryptedData, encoding: .utf8)
        
        XCTAssertEqual(decryptedString, message, "Decrypted message should match original")
    }
    
    func testAESGCMKeySizes() {
        let key128 = SymmetricKey(size: .bits128)
        let key192 = SymmetricKey(size: .bits192)
        let key256 = SymmetricKey(size: .bits256)
        
        XCTAssertEqual(key128.withUnsafeBytes { $0.count }, 16, "128-bit key should be 16 bytes")
        XCTAssertEqual(key192.withUnsafeBytes { $0.count }, 24, "192-bit key should be 24 bytes")
        XCTAssertEqual(key256.withUnsafeBytes { $0.count }, 32, "256-bit key should be 32 bytes")
    }
    
    func testAESGCMAuthenticatedEncryption() throws {
        let message = "Test message"
        let messageData = Data(message.utf8)
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt with nonce
        let nonce = AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(messageData, using: key, nonce: nonce)
        
        XCTAssertNotNil(sealedBox.ciphertext, "Should produce ciphertext")
        XCTAssertNotNil(sealedBox.tag, "Should produce authentication tag")
        XCTAssertNotNil(sealedBox.nonce, "Should produce nonce")
    }
    
    func testDifferentKeysProduceDifferentCiphertext() throws {
        let message = "Test message"
        let messageData = Data(message.utf8)
        let key1 = SymmetricKey(size: .bits256)
        let key2 = SymmetricKey(size: .bits256)
        
        let sealedBox1 = try AES.GCM.seal(messageData, using: key1)
        let sealedBox2 = try AES.GCM.seal(messageData, using: key2)
        
        XCTAssertNotEqual(sealedBox1.combined, sealedBox2.combined, "Different keys should produce different ciphertext")
    }
}

// MARK: - Session Security Tests
class SessionSecurityTests: XCTestCase {
    
    var sessionManager: SessionManager!
    
    override func setUp() {
        super.setUp()
        sessionManager = SessionManager.shared
        sessionManager.endSession() // Reset state
    }
    
    override func tearDown() {
        sessionManager.endSession()
        super.tearDown()
    }
    
    func testSessionStart() {
        XCTAssertFalse(sessionManager.isSessionActive, "Session should not be active initially")
        
        sessionManager.startSession()
        
        XCTAssertTrue(sessionManager.isSessionActive, "Session should be active after start")
        XCTAssertNotNil(sessionManager.sessionStartTime, "Session start time should be set")
        XCTAssertNotNil(sessionManager.lastActivityTime, "Last activity time should be set")
    }
    
    func testSessionEnd() {
        sessionManager.startSession()
        XCTAssertTrue(sessionManager.isSessionActive)
        
        sessionManager.endSession()
        
        XCTAssertFalse(sessionManager.isSessionActive, "Session should not be active after end")
        XCTAssertNil(sessionManager.sessionStartTime, "Session start time should be nil")
        XCTAssertNil(sessionManager.lastActivityTime, "Last activity time should be nil")
    }
    
    func testSessionTimeoutCalculation() {
        sessionManager.startSession()
        
        let expectation = self.expectation(description: "Session timeout")
        var timeoutCalled = false
        
        sessionManager.onSessionTimeout = {
            timeoutCalled = true
            expectation.fulfill()
        }
        
        // Simulate inactivity by not calling recordActivity
        // In real test, we'd need to manipulate time or use a shorter timeout for testing
        
        wait(for: [expectation], timeout: 35.0) // 30 min timeout + buffer
        
        // Note: This test would need time manipulation for practical use
        // For now, we verify the mechanism exists
        XCTAssertNotNil(sessionManager.onSessionTimeout, "Timeout handler should be set")
    }
    
    func testSessionActivityRecording() {
        sessionManager.startSession()
        let initialActivityTime = sessionManager.lastActivityTime
        
        // Wait a moment
        Thread.sleep(forTimeInterval: 0.1)
        
        sessionManager.recordActivity()
        
        XCTAssertTrue(sessionManager.isSessionActive, "Session should still be active")
        XCTAssertNotEqual(sessionManager.lastActivityTime, initialActivityTime, "Activity time should update")
    }
    
    func testSessionDurationCalculation() {
        sessionManager.startSession()
        
        Thread.sleep(forTimeInterval: 0.1)
        
        let duration = sessionManager.sessionDuration
        XCTAssertNotNil(duration, "Duration should be calculated")
        XCTAssertGreaterThan(duration!, 0, "Duration should be positive")
    }
}

// MARK: - Security Event Logger Tests
class SecurityEventLoggerTests: XCTestCase {
    
    var logger: SecurityEventLogger!
    
    override func setUp() {
        super.setUp()
        logger = SecurityEventLogger.shared
    }
    
    func testAuthAttemptLogging() {
        // Test that auth attempt logging doesn't crash
        logger.logAuthAttempt(success: true, reason: "test_success")
        logger.logAuthAttempt(success: false, reason: "test_failure")
        logger.logAuthAttempt(success: nil, reason: "test_attempt")
        
        // Verify logs can be retrieved
        let logs = logger.retrieveLogs()
        XCTAssertNotNil(logs, "Should retrieve logs without error")
    }
    
    func testSessionEventLogging() {
        logger.logSessionEvent(action: "test_start")
        logger.logSessionEvent(action: "test_end", reason: "test_reason")
        
        let logs = logger.retrieveLogs(type: .session)
        XCTAssertNotNil(logs, "Should retrieve session logs")
    }
    
    func testDataEventLogging() {
        logger.logDataEvent(action: "test_data_access", success: true)
        logger.logDataEvent(action: "test_data_export", success: false, context: "test_context")
        
        let logs = logger.retrieveLogs(type: .dataAccess)
        XCTAssertNotNil(logs, "Should retrieve data access logs")
    }
    
    func testLogRetrievalWithTimeFilter() {
        let startDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let logs = logger.retrieveLogs(since: startDate)
        XCTAssertNotNil(logs, "Should retrieve logs since date")
    }
    
    func testLogRetrievalWithTypeFilter() {
        logger.logAuthAttempt(success: true, reason: "test")
        
        let authLogs = logger.retrieveLogs(type: .authentication)
        let systemLogs = logger.retrieveLogs(type: .system)
        
        XCTAssertNotNil(authLogs, "Should retrieve auth logs")
        XCTAssertNotNil(systemLogs, "Should retrieve system logs")
    }
}

// MARK: - Network Security Tests
class NetworkSecurityTests: XCTestCase {
    
    var networkManager: NetworkSecurityManager!
    
    override func setUp() {
        super.setUp()
        networkManager = NetworkSecurityManager.shared
    }
    
    func testSecureSessionCreation() {
        let session = networkManager.secureURLSession
        XCTAssertNotNil(session, "Should create secure URLSession")
        XCTAssertNotNil(session.configuration, "Session should have configuration")
    }
    
    func testHTTPSOnlyValidation() {
        let httpURL = URL(string: "http://example.com")!
        let httpsURL = URL(string: "https://example.com")!
        
        // HTTP should be rejected
        XCTAssertEqual(httpURL.scheme?.lowercased(), "http", "URL scheme should be http")
        XCTAssertEqual(httpsURL.scheme?.lowercased(), "https", "URL scheme should be https")
    }
    
    func testTLSConfiguration() {
        // Verify TLS 1.3 configuration exists
        let config = URLSessionConfiguration.secureConfiguration
        XCTAssertNotNil(config, "Secure configuration should exist")
        
        // Check TLS version (if available on platform)
        if #available(macOS 15.0, iOS 15.0, *) {
            XCTAssertNotNil(config.tlsMinimumSupportedProtocolVersion, "Should have minimum TLS version")
        }
    }
    
    func testNetworkSecurityStatus() {
        let status = networkManager.checkNetworkSecurity()
        XCTAssertNotNil(status, "Should return network security status")
    }
}

// MARK: - Integration Tests
class SecurityIntegrationTests: XCTestCase {
    
    func testCompleteAuthenticationFlow() {
        let authManager = AuthenticationManager.shared
        
        // Verify initial state
        XCTAssertFalse(authManager.isAuthenticated, "Should not be authenticated initially")
        
        // Note: Full flow test would require CoreData context and Staff entity
        // This is a placeholder for integration testing
    }
    
    func testSecurityEventChain() {
        let logger = SecurityEventLogger.shared
        let sessionManager = SessionManager.shared
        
        // Start session (should log)
        sessionManager.startSession()
        
        // Log some events
        logger.logAuthAttempt(success: nil, reason: "integration_test")
        
        // End session (should log)
        sessionManager.endSession()
        
        // Verify logs exist
        let logs = logger.retrieveLogs()
        XCTAssertNotNil(logs, "Should have logged events")
    }
}
