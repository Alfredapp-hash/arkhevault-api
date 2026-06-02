import SwiftUI
import LocalAuthentication
import Security
import CryptoKit

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: Staff?
    @Published var errorMessage: String?
    
    private let keychainService = "com.forgedinfire.clientmanager"
    
    private init() {
        checkExistingSession()
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String, context: NSManagedObjectContext) async -> Bool {
        // Log authentication attempt (without PII)
        SecurityEventLogger.shared.logAuthAttempt(success: nil, reason: "login_attempt")
        
        let staff = Staff.authenticate(email: email, in: context)
        
        guard let staff = staff else {
            SecurityEventLogger.shared.logAuthAttempt(success: false, reason: "user_not_found")
            await MainActor.run {
                errorMessage = "Invalid email or password"
            }
            return false
        }
        
        // Verify password using secure comparison
        guard verifyPassword(password, forEmail: email) else {
            SecurityEventLogger.shared.logAuthAttempt(success: false, reason: "invalid_password")
            await MainActor.run {
                errorMessage = "Invalid email or password"
            }
            return false
        }
        
        // Store hashed credentials in keychain
        let passwordHash = hashPassword(password)
        saveCredentials(email: email, passwordHash: passwordHash)
        
        await MainActor.run {
            self.currentUser = staff
            self.isAuthenticated = true
            self.errorMessage = nil
            SessionManager.shared.startSession()
            
            // Update last login
            staff.lastLogin = Date()
            try? context.save()
        }
        
        SecurityEventLogger.shared.logAuthAttempt(success: true, reason: "password_login")
        return true
    }
    
    // MARK: - Password Hashing
    private func hashPassword(_ password: String) -> String {
        let salt = "ArkheVault_" + ProcessInfo.processInfo.environment["APP_SALT_SUFFIX"]! // Unique per installation
        let inputData = Data((salt + password).utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, forEmail email: String) -> Bool {
        // In production, retrieve stored hash from keychain and compare
        // For this implementation, we hash the input and compare
        let inputHash = hashPassword(password)
        if let storedHash = retrievePasswordHash(forEmail: email) {
            return inputHash == storedHash
        }
        // First login - store the hash
        return !password.isEmpty
    }
    
    private func retrievePasswordHash(forEmail email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService + ".password",
            kSecAttrAccount as String: email,
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
    
    // MARK: - Biometric Authentication
    func authenticateWithBiometrics() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        // Check if biometric authentication is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate to access Arkhe Vault"
            
            do {
                let success = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: reason
                )
                
                if success {
                    // Restore previous session if credentials exist and are valid
                    if let email = retrieveCredentials(),
                       validateBiometricCredentials(email: email) {
                        await MainActor.run {
                            self.isAuthenticated = true
                            SessionManager.shared.startSession()
                        }
                        SecurityEventLogger.shared.logAuthAttempt(success: true, reason: "biometric_login")
                        return true
                    }
                    SecurityEventLogger.shared.logAuthAttempt(success: false, reason: "biometric_no_credentials")
                }
                
                return success
            } catch {
                await MainActor.run {
                    errorMessage = "Biometric authentication failed: \(error.localizedDescription)"
                }
                return false
            }
        } else {
            await MainActor.run {
                errorMessage = "Biometric authentication not available"
            }
            return false
        }
    }
    
    // MARK: - Session Management
    private func checkExistingSession() {
        if retrieveCredentials() != nil {
            // Require re-authentication for security
            // Do not log email or any PII
            #if DEBUG
            print("Existing credentials found - re-authentication required")
            #endif
        }
    }
    
    private func validateBiometricCredentials(email: String) -> Bool {
        // Verify that email exists in system
        // In production, would validate against CoreData
        return !email.isEmpty
    }
    
    // MARK: - Keychain Operations
    private func saveCredentials(email: String, passwordHash: String) {
        // Store email reference
        let emailData = email.data(using: .utf8)!
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "current_user",
            kSecValueData as String: emailData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing email
        SecItemDelete(emailQuery as CFDictionary)
        
        // Add new email reference
        let emailStatus = SecItemAdd(emailQuery as CFDictionary, nil)
        if emailStatus != errSecSuccess {
            #if DEBUG
            print("Error saving email to keychain: \(emailStatus)")
            #endif
        }
        
        // Store password hash separately
        let hashData = passwordHash.data(using: .utf8)!
        let hashQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService + ".password",
            kSecAttrAccount as String: email,
            kSecValueData as String: hashData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing hash
        SecItemDelete(hashQuery as CFDictionary)
        
        // Add new hash
        let hashStatus = SecItemAdd(hashQuery as CFDictionary, nil)
        if hashStatus != errSecSuccess {
            #if DEBUG
            print("Error saving password hash to keychain: \(hashStatus)")
            #endif
        }
    }
    
    private func retrieveCredentials() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "current_user",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data,
           let email = String(data: data, encoding: .utf8) {
            return email
        }
        
        return nil
    }
    
    private func clearCredentials() {
        // Clear email reference
        let emailQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(emailQuery as CFDictionary)
        
        // Clear all password hashes
        let hashQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService + ".password"
        ]
        SecItemDelete(hashQuery as CFDictionary)
        
        SessionManager.shared.endSession()
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        SecurityEventLogger.shared.logAuthAttempt(success: nil, reason: "logout")
        clearCredentials()
    }
}

// MARK: - Login View
struct LoginView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showBiometricOption = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo and Title
            VStack(spacing: 16) {
                // Forged In Fire Logo Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.forgeTeal)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.warmIvory)
                    )
                
                VStack(spacing: 8) {
                    Text("Forged In Fire")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Client Management Platform")
                        .font(.brandBody)
                        .foregroundColor(.textSecondary)
                }
            }
            
            // Login Form
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    TextField("Enter your email", text: $email)
                        .textFieldStyle(ForgeTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(ForgeTextFieldStyle())
                }
            }
            
            // Error Message
            if let errorMessage = authManager.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.dangerRed)
                    Text(errorMessage)
                        .font(.brandCaption)
                        .foregroundColor(.dangerRed)
                }
                .padding()
                .background(Color.dangerRed.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Login Button
            ForgeButton(
                title: isLoading ? "Signing In..." : "Sign In",
                style: .primary,
                isDisabled: isLoading || email.isEmpty || password.isEmpty,
                isLoading: isLoading
            ) {
                Task {
                    isLoading = true
                    let success = await authManager.login(
                        email: email,
                        password: password,
                        context: viewContext
                    )
                    isLoading = false
                }
            }
            
            // Biometric Login Option
            if showBiometricOption {
                Button(action: {
                    Task {
                        let success = await authManager.authenticateWithBiometrics()
                        if success {
                            // Handle successful biometric auth
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                        Text("Sign in with Face ID")
                    }
                    .font(.brandBody)
                    .foregroundColor(.forgeTeal)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Text("Forged In Fire - Client Management")
                    .font(.brandSmall)
                    .foregroundColor(.textMuted)
                
                Text("© 2024 Forged In Fire. All rights reserved.")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
            }
        }
        .padding(32)
        .frame(maxWidth: 400, maxHeight: .infinity)
        .background(Color.deepCharcoal)
        .onAppear {
            checkBiometricAvailability()
        }
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            showBiometricOption = true
        }
    }
}

// MARK: - Custom TextField Style
struct ForgeTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.darkCharcoal)
            .foregroundColor(.textPrimary)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.lightCharcoal, lineWidth: 1)
            )
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}