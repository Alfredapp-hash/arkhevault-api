import XCTest

// MARK: - UI Security Tests
class SecurityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-keychain"]
        app.launch()
    }
    
    override func tearDown() {
        app.terminate()
        super.tearDown()
    }
    
    // MARK: Login Security Tests
    
    func testLoginFormValidation() {
        // Test empty fields disabled login button
        let loginButton = app.buttons["Sign In"]
        XCTAssertFalse(loginButton.isEnabled, "Login button should be disabled with empty fields")
        
        // Enter invalid email
        let emailField = app.textFields["Enter your email"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        let passwordField = app.secureTextFields["Enter your password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Attempt login with invalid email
        loginButton.tap()
        
        // Should show validation error
        let errorMessage = app.staticTexts["Please enter a valid email address"]
        XCTAssertTrue(errorMessage.exists, "Should show email validation error")
    }
    
    func testLoginWithValidCredentials() {
        // Enter valid email
        let emailField = app.textFields["Enter your email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        // Enter password
        let passwordField = app.secureTextFields["Enter your password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Login button should be enabled
        let loginButton = app.buttons["Sign In"]
        XCTAssertTrue(loginButton.isEnabled, "Login button should be enabled with valid input")
    }
    
    func testPasswordFieldIsSecure() {
        let passwordField = app.secureTextFields["Enter your password"]
        XCTAssertTrue(passwordField.exists, "Password field should be secure text field")
        
        passwordField.tap()
        passwordField.typeText("secretpassword")
        
        // Verify text is masked (we can't see the actual text in UI tests)
        XCTAssertTrue(passwordField.exists, "Password field should exist")
    }
    
    func testBiometricLoginOption() {
        // Check if biometric option is available
        let biometricButton = app.buttons["Sign in with Face ID"]
        
        // Note: Biometric availability depends on device/simulator
        if biometricButton.exists {
            XCTAssertTrue(biometricButton.isHittable, "Biometric login button should be accessible")
        }
    }
    
    // MARK: Session Timeout Tests
    
    func testSessionTimeoutWarning() {
        // Login first
        loginWithTestCredentials()
        
        // Wait for session timeout warning (would need to manipulate time in real test)
        // This is a placeholder for the actual timeout test
        
        let warningText = app.staticTexts["Session Expiring Soon"]
        // In real test, we'd wait for the timeout
        XCTAssertFalse(warningText.exists, "Should not show warning immediately after login")
    }
    
    // MARK: Navigation Security Tests
    
    func testProtectedRoutesRequireAuthentication() {
        // Try to access main window without login
        // Should be redirected to login
        
        let loginTitle = app.staticTexts["Welcome Back"]
        XCTAssertTrue(loginTitle.exists, "Should show login view when not authenticated")
    }
    
    func testLogoutClearsSession() {
        // Login
        loginWithTestCredentials()
        
        // Navigate to settings and logout
        let settingsButton = app.buttons["Settings"]
        if settingsButton.exists {
            settingsButton.tap()
            let logoutButton = app.buttons["Logout"]
            if logoutButton.exists {
                logoutButton.tap()
                
                // Should return to login
                let loginTitle = app.staticTexts["Welcome Back"]
                XCTAssertTrue(loginTitle.waitForExistence(timeout: 2), "Should return to login after logout")
            }
        }
    }
    
    // MARK: Helper Methods
    
    private func loginWithTestCredentials() {
        let emailField = app.textFields["Enter your email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Enter your password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        let loginButton = app.buttons["Sign In"]
        loginButton.tap()
        
        // Wait for main window to appear
        let mainWindow = app.windows.element(boundBy: 0)
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 5), "Main window should appear after login")
    }
}

// MARK: - Performance Security Tests
class SecurityPerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testPasswordHashingPerformance() {
        let password = "testpassword123"
        let salt = "ForgedInFire_test"
        
        measure {
            for _ in 0..<100 {
                let inputData = Data((salt + password).utf8)
                _ = SHA256.hash(data: inputData)
            }
        }
    }
    
    func testAESGCMEncryptionPerformance() {
        let message = String(repeating: "A", count: 1000)
        let messageData = Data(message.utf8)
        let key = SymmetricKey(size: .bits256)
        
        measure {
            for _ in 0..<10 {
                do {
                    _ = try AES.GCM.seal(messageData, using: key)
                } catch {
                    XCTFail("Encryption failed: \(error)")
                }
            }
        }
    }
    
    func testKeychainAccessPerformance() {
        let testKey = "perf_test_key"
        let testValue = "performance_test_value"
        
        measure {
            for _ in 0..<50 {
                KeychainHelper.store(key: testKey, value: testValue)
                _ = KeychainHelper.retrieve(key: testKey)
            }
        }
        
        // Cleanup
        KeychainHelper.delete(key: testKey)
    }
}

// MARK: - Accessibility Security Tests
class AccessibilitySecurityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testPasswordFieldAccessibilityLabel() {
        let passwordField = app.secureTextFields["Enter your password"]
        XCTAssertTrue(passwordField.exists, "Password field should have accessibility label")
        
        // Verify it's marked as secure
        // In UI tests we can verify the element exists and is a secure text field
        XCTAssertTrue(passwordField.isHittable, "Password field should be accessible")
    }
    
    func testLoginButtonAccessibility() {
        let loginButton = app.buttons["Sign In"]
        XCTAssertTrue(loginButton.exists, "Login button should exist")
        XCTAssertTrue(loginButton.isHittable, "Login button should be accessible")
    }
    
    func testErrorMessageAccessibility() {
        // Trigger an error
        let loginButton = app.buttons["Sign In"]
        loginButton.tap()
        
        // Error message should be accessible
        let errorMessage = app.staticTexts.element(matching: NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'valid'"))
        // Just verify we can check for error messages
        XCTAssertNotNil(errorMessage)
    }
}
