import XCTest
@testable import ArkheVault

// MARK: - Configuration Tests
class ConfigurationTests: XCTestCase {
    var configuration: Configuration!
    
    override func setUp() {
        super.setUp()
        configuration = Configuration.shared
    }
    
    override func tearDown() {
        configuration = nil
        super.tearDown()
    }
    
    func testEnvironmentDetection() {
        // Test that environment is detected correctly
        let environment = configuration.environment
        
        #if DEBUG
        XCTAssertEqual(environment, .development)
        #else
        XCTAssertNotNil(environment)
        #endif
    }
    
    func testAPIBaseURL() {
        let baseURL = configuration.apiBaseURL
        XCTAssertTrue(baseURL.hasPrefix("https://"))
        XCTAssertTrue(baseURL.contains("arkhevault"))
    }
    
    func testRateLimitingDefaults() {
        // Test default rate limiting values
        XCTAssertEqual(configuration.maxAPIRequestsPerMinute, 60)
        XCTAssertEqual(configuration.maxAPIRequestsPerHour, 1000)
    }
    
    func testFeatureFlags() {
        // Feature flags should be boolean
        XCTAssertTrue(type(of: configuration.aiFeaturesEnabled) == Bool.self)
        XCTAssertTrue(type(of: configuration.voiceToTextEnabled) == Bool.self)
        XCTAssertTrue(type(of: configuration.analyticsEnabled) == Bool.self)
    }
}

// MARK: - Rate Limiter Tests
class RateLimiterTests: XCTestCase {
    var rateLimiter: RateLimiter!
    
    override func setUp() {
        super.setUp()
        rateLimiter = RateLimiter(maxRequestsPerMinute: 10, maxRequestsPerHour: 100)
    }
    
    override func tearDown() {
        rateLimiter = nil
        super.tearDown()
    }
    
    func testInitialRateLimit() {
        let (allowed, resetTime) = rateLimiter.checkRateLimit()
        XCTAssertTrue(allowed)
        XCTAssertNil(resetTime)
    }
    
    func testRateLimitEnforcement() {
        // Make requests up to the limit
        for _ in 0..<10 {
            let (allowed, _) = rateLimiter.checkRateLimit()
            XCTAssertTrue(allowed)
        }
        
        // Next request should be denied
        let (allowed, resetTime) = rateLimiter.checkRateLimit()
        XCTAssertFalse(allowed)
        XCTAssertNotNil(resetTime)
    }
    
    func testRateLimitReset() {
        // Fill up the rate limit
        for _ in 0..<10 {
            _ = rateLimiter.checkRateLimit()
        }
        
        // Reset
        rateLimiter.reset()
        
        // Should be allowed again
        let (allowed, _) = rateLimiter.checkRateLimit()
        XCTAssertTrue(allowed)
    }
    
    func testUsageStats() {
        // Make some requests
        for _ in 0..<5 {
            _ = rateLimiter.checkRateLimit()
        }
        
        let (minuteCount, hourCount) = rateLimiter.getUsageStats()
        XCTAssertEqual(minuteCount, 5)
        XCTAssertEqual(hourCount, 5)
    }
    
    func testHourlyRateLimit() {
        // Create a rate limiter with very low limits for testing
        let testLimiter = RateLimiter(maxRequestsPerMinute: 100, maxRequestsPerHour: 2)
        
        // Make 2 requests
        for _ in 0..<2 {
            _ = testLimiter.checkRateLimit()
        }
        
        // Should be denied due to hourly limit
        let (allowed, _) = testLimiter.checkRateLimit()
        XCTAssertFalse(allowed)
    }
}

// MARK: - Keychain Helper Tests
class KeychainHelperTests: XCTestCase {
    let testKey = "test_key_\(UUID().uuidString)"
    let testValue = "test_value"
    
    override func tearDown() {
        // Clean up test data
        KeychainHelper.delete(key: testKey)
        super.tearDown()
    }
    
    func testStoreAndRetrieve() {
        // Store a value
        let storeSuccess = KeychainHelper.store(key: testKey, value: testValue)
        XCTAssertTrue(storeSuccess)
        
        // Retrieve the value
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertEqual(retrievedValue, testValue)
    }
    
    func testRetrieveNonExistentKey() {
        let retrievedValue = KeychainHelper.retrieve(key: "non_existent_key")
        XCTAssertNil(retrievedValue)
    }
    
    func testDeleteKey() {
        // Store a value
        KeychainHelper.store(key: testKey, value: testValue)
        
        // Delete it
        let deleteSuccess = KeychainHelper.delete(key: testKey)
        XCTAssertTrue(deleteSuccess)
        
        // Verify it's gone
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertNil(retrievedValue)
    }
    
    func testUpdateExistingKey() {
        // Store initial value
        KeychainHelper.store(key: testKey, value: testValue)
        
        // Update with new value
        let newValue = "new_value"
        let updateSuccess = KeychainHelper.store(key: testKey, value: newValue)
        XCTAssertTrue(updateSuccess)
        
        // Verify new value
        let retrievedValue = KeychainHelper.retrieve(key: testKey)
        XCTAssertEqual(retrievedValue, newValue)
    }
}

// MARK: - Error Handler Tests
class ErrorHandlerTests: XCTestCase {
    var errorHandler: ErrorHandler!
    
    override func setUp() {
        super.setUp()
        errorHandler = ErrorHandler.shared
        errorHandler.dismissError()
    }
    
    override func tearDown() {
        errorHandler = nil
        super.tearDown()
    }
    
    func testHandleAppError() {
        let testError = AppError.networkUnavailable
        errorHandler.handle(testError, context: "Test Context")
        
        XCTAssertNotNil(errorHandler.currentError)
        XCTAssertTrue(errorHandler.showErrorAlert)
    }
    
    func testHandleUnknownError() {
        let testError = NSError(domain: "TestDomain", code: 1, userInfo: nil)
        errorHandler.handle(testError, context: "Test Context")
        
        XCTAssertNotNil(errorHandler.currentError)
    }
    
    func testErrorHistory() {
        let initialCount = errorHandler.errorHistory.count
        
        // Add some errors
        errorHandler.handle(AppError.networkUnavailable, context: "Test 1")
        errorHandler.handle(AppError.authenticationFailed(reason: "Test"), context: "Test 2")
        
        XCTAssertEqual(errorHandler.errorHistory.count, initialCount + 2)
    }
    
    func testErrorHistoryLimit() {
        // Add more than 50 errors
        for i in 0..<60 {
            errorHandler.handle(AppError.unknownError, context: "Test \(i)")
        }
        
        // Should be limited to 50
        XCTAssertEqual(errorHandler.errorHistory.count, 50)
    }
    
    func testDismissError() {
        errorHandler.handle(AppError.networkUnavailable, context: "Test")
        
        XCTAssertNotNil(errorHandler.currentError)
        
        errorHandler.dismissError()
        
        XCTAssertNil(errorHandler.currentError)
        XCTAssertFalse(errorHandler.showErrorAlert)
    }
}

// MARK: - App Error Tests
class AppErrorTests: XCTestCase {
    func testAuthenticationErrorDescription() {
        let error = AppError.authenticationFailed(reason: "Invalid password")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Authentication failed"))
    }
    
    func testNetworkErrorDescription() {
        let error = AppError.networkUnavailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Network connection"))
    }
    
    func testRateLimitErrorDescription() {
        let resetTime = Date().addingTimeInterval(300)
        let error = AppError.rateLimitExceeded(resetTime: resetTime)
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Rate limit exceeded"))
    }
    
    func testRecoverySuggestions() {
        let error = AppError.networkUnavailable
        XCTAssertNotNil(error.recoverySuggestion)
        XCTAssertTrue(error.recoverySuggestion!.contains("internet connection"))
    }
    
    func testValidationErrorDescription() {
        let error = AppError.invalidInput(field: "Email", reason: "Invalid format")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("Email"))
    }
}

// MARK: - Brand System Tests
class BrandSystemTests: XCTestCase {
    func testAppName() {
        XCTAssertEqual(BrandSystem.appName, "Arkhe Vault")
    }
    
    func testTagline() {
        XCTAssertEqual(BrandSystem.tagline, "Protecting Data. Empowering Missions.")
    }
    
    func testVersion() {
        XCTAssertNotNil(BrandSystem.version)
    }
    
    func testLogoConfiguration() {
        XCTAssertNotNil(BrandSystem.logoFileName)
        XCTAssertFalse(BrandSystem.logoFileName.isEmpty)
    }
}

// MARK: - Color System Tests
class ColorSystemTests: XCTestCase {
    func testBrandColorsExist() {
        // Test that brand colors are defined
        XCTAssertNotNil(Color.forgeTeal)
        XCTAssertNotNil(Color.bronze)
        XCTAssertNotNil(Color.warmIvory)
        XCTAssertNotNil(Color.deepCharcoal)
    }
    
    func testStatusColorsExist() {
        XCTAssertNotNil(Color.successGreen)
        XCTAssertNotNil(Color.warningGold)
        XCTAssertNotNil(Color.dangerRed)
        XCTAssertNotNil(Color.infoBlue)
    }
    
    func testRiskLevelColorsExist() {
        XCTAssertNotNil(Color.riskLow)
        XCTAssertNotNil(Color.riskMedium)
        XCTAssertNotNil(Color.riskHigh)
        XCTAssertNotNil(Color.riskCritical)
    }
}

// MARK: - Mock Data Helper
class MockDataHelper {
    static func createMockClient(context: NSManagedObjectContext) -> Client {
        let client = Client(context: context)
        client.id = UUID()
        client.firstName = "Test"
        client.lastName = "Client"
        client.email = "test@example.com"
        client.phoneNumber = "555-1234"
        client.createdAt = Date()
        client.updatedAt = Date()
        return client
    }
    
    static func createMockProgram(context: NSManagedObjectContext) -> Program {
        let program = Program(context: context)
        program.id = UUID()
        program.name = "Test Program"
        program.description = "Test Description"
        program.capacity = 10
        program.isActive = true
        program.createdAt = Date()
        program.updatedAt = Date()
        return program
    }
}

// MARK: - Core Data Helper Tests
class CoreDataHelperTests: XCTestCase {
    var mockContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "ArkheVaultDataModel")
        let description = persistentContainer.persistentStoreDescriptions.first
        description?.url = URL(fileURLWithPath: "/dev/null")
        
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load test store: \(error?.localizedDescription ?? "")")
        }
        
        mockContext = persistentContainer.viewContext
    }
    
    override func tearDown() {
        mockContext = nil
        super.tearDown()
    }
    
    func testCreateMockClient() {
        let client = MockDataHelper.createMockClient(context: mockContext)
        
        XCTAssertNotNil(client)
        XCTAssertEqual(client.firstName, "Test")
        XCTAssertEqual(client.lastName, "Client")
        XCTAssertNotNil(client.id)
    }
    
    func testCreateMockProgram() {
        let program = MockDataHelper.createMockProgram(context: mockContext)
        
        XCTAssertNotNil(program)
        XCTAssertEqual(program.name, "Test Program")
        XCTAssertEqual(program.capacity, 10)
        XCTAssertTrue(program.isActive)
    }
    
    func testClientProgramRelationship() {
        let client = MockDataHelper.createMockClient(context: mockContext)
        let program = MockDataHelper.createMockProgram(context: mockContext)
        
        let enrollment = ProgramEnrollment(context: mockContext)
        enrollment.id = UUID()
        enrollment.client = client
        enrollment.program = program
        enrollment.enrollmentDate = Date()
        enrollment.status = "Active"
        
        XCTAssertNotNil(enrollment.client)
        XCTAssertNotNil(enrollment.program)
        XCTAssertEqual(enrollment.client?.firstName, "Test")
        XCTAssertEqual(enrollment.program?.name, "Test Program")
    }
}

// MARK: - Performance Tests
class PerformanceTests: XCTestCase {
    func testRateLimiterPerformance() {
        measure {
            let rateLimiter = RateLimiter(maxRequestsPerMinute: 100, maxRequestsPerHour: 1000)
            
            for _ in 0..<50 {
                _ = rateLimiter.checkRateLimit()
            }
        }
    }
    
    func testConfigurationPerformance() {
        measure {
            let config = Configuration.shared
            _ = config.environment
            _ = config.apiBaseURL
            _ = config.maxAPIRequestsPerMinute
        }
    }
    
    func testKeychainRetrievalPerformance() {
        let testKey = "perf_test_key"
        let testValue = "perf_test_value"
        
        KeychainHelper.store(key: testKey, value: testValue)
        
        measure {
            _ = KeychainHelper.retrieve(key: testKey)
        }
        
        KeychainHelper.delete(key: testKey)
    }
}

// MARK: - Integration Tests
class IntegrationTests: XCTestCase {
    func testConfigurationRateLimiterIntegration() {
        let config = Configuration.shared
        let rateLimiter = RateLimiter(
            maxRequestsPerMinute: config.maxAPIRequestsPerMinute,
            maxRequestsPerHour: config.maxAPIRequestsPerHour
        )
        
        // Make a request
        let (allowed, _) = rateLimiter.checkRateLimit()
        XCTAssertTrue(allowed)
        
        // Check stats
        let (minuteCount, hourCount) = rateLimiter.getUsageStats()
        XCTAssertEqual(minuteCount, 1)
        XCTAssertEqual(hourCount, 1)
    }
    
    func testErrorHandlerRateLimitIntegration() {
        let errorHandler = ErrorHandler.shared
        let rateLimiter = RateLimiter(maxRequestsPerMinute: 1, maxRequestsPerHour: 10)
        
        // Fill rate limit
        _ = rateLimiter.checkRateLimit()
        
        // Next request should fail
        let (allowed, resetTime) = rateLimiter.checkRateLimit()
        XCTAssertFalse(allowed)
        
        // Handle the error
        if let resetTime = resetTime {
            errorHandler.handle(AppError.rateLimitExceeded(resetTime: resetTime))
        }
        
        XCTAssertNotNil(errorHandler.currentError)
    }
}

// MARK: - Test Suite Info
class TestSuiteInfo {
    static var allTests: [(String, () -> Void)] {
        return [
            // Configuration Tests
            ("testEnvironmentDetection", ConfigurationTests().testEnvironmentDetection),
            ("testAPIBaseURL", ConfigurationTests().testAPIBaseURL),
            ("testRateLimitingDefaults", ConfigurationTests().testRateLimitingDefaults),
            ("testFeatureFlags", ConfigurationTests().testFeatureFlags),
            
            // Rate Limiter Tests
            ("testInitialRateLimit", RateLimiterTests().testInitialRateLimit),
            ("testRateLimitEnforcement", RateLimiterTests().testRateLimitEnforcement),
            ("testRateLimitReset", RateLimiterTests().testRateLimitReset),
            ("testUsageStats", RateLimiterTests().testUsageStats),
            ("testHourlyRateLimit", RateLimiterTests().testHourlyRateLimit),
            
            // Keychain Helper Tests
            ("testStoreAndRetrieve", KeychainHelperTests().testStoreAndRetrieve),
            ("testRetrieveNonExistentKey", KeychainHelperTests().testRetrieveNonExistentKey),
            ("testDeleteKey", KeychainHelperTests().testDeleteKey),
            ("testUpdateExistingKey", KeychainHelperTests().testUpdateExistingKey),
            
            // Error Handler Tests
            ("testHandleAppError", ErrorHandlerTests().testHandleAppError),
            ("testHandleUnknownError", ErrorHandlerTests().testHandleUnknownError),
            ("testErrorHistory", ErrorHandlerTests().testErrorHistory),
            ("testErrorHistoryLimit", ErrorHandlerTests().testErrorHistoryLimit),
            ("testDismissError", ErrorHandlerTests().testDismissError),
            
            // App Error Tests
            ("testAuthenticationErrorDescription", AppErrorTests().testAuthenticationErrorDescription),
            ("testNetworkErrorDescription", AppErrorTests().testNetworkErrorDescription),
            ("testRateLimitErrorDescription", AppErrorTests().testRateLimitErrorDescription),
            ("testRecoverySuggestions", AppErrorTests().testRecoverySuggestions),
            ("testValidationErrorDescription", AppErrorTests().testValidationErrorDescription),
        ]
    }
}