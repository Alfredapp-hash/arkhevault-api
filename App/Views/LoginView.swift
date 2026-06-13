import SwiftUI

// MARK: - Login View
struct LoginView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var showingBiometricPrompt = false
    @State private var validationError: String? = nil
    
    // Email validation regex
    private let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Logo
            VStack(spacing: 24) {
                Spacer()
                
                ArkheLogo(size: .large, style: .full, showTagline: true)
                    .padding(.bottom, 8)
                
                Text("Welcome Back")
                    .font(.brandTitle)
                    .foregroundColor(.textPrimary)
                
                Text("Sign in to access your workspace")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.top, 60)
            .padding(.bottom, 40)
            
            // Login Form
            VStack(spacing: 20) {
                // Email Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email Address")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.forgeTeal)
                            .frame(width: 20)
                        
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(PlainTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.never)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.lightCharcoal)
                    .cornerRadius(8)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.forgeTeal)
                            .frame(width: 20)
                        
                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.lightCharcoal)
                    .cornerRadius(8)
                }
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.dangerRed)
                            .font(.brandTiny)
                        
                        Text(errorMessage)
                            .font(.brandCaption)
                            .foregroundColor(.dangerRed)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.dangerRed.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Login Button
                ArkheButton(
                    title: isLoggingIn ? "Signing In..." : "Sign In",
                    style: .primary,
                    isFullWidth: true,
                    isDisabled: email.isEmpty || password.isEmpty || isLoggingIn,
                    isLoading: isLoggingIn
                ) {
                    login()
                }
                
                // Biometric Login
                Button(action: {
                    showingBiometricPrompt = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "faceid")
                            .foregroundColor(.forgeTeal)
                        
                        Text("Sign in with Face ID")
                            .font(.brandCaption)
                            .foregroundColor(.forgeTeal)
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(Color.brandBorder)
                
                // Forgot Password
                Button(action: {
                    // Forgot password action
                }) {
                    Text("Forgot Password?")
                        .font(.brandCaption)
                        .foregroundColor(.forgeTeal)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                ArkheLogo(size: .compact, style: .iconOnly)
                
                Text("Arkhe Vault Client Manager")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
                
                Text("Version \(BrandSystem.version)")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingBiometricPrompt) {
            BiometricLoginView()
        }
    }
    
    private func login() {
        // Validate email format
        guard isValidEmail(email) else {
            validationError = "Please enter a valid email address"
            return
        }
        
        // Clear validation error
        validationError = nil
        isLoggingIn = true
        
        Task {
            let success = await authManager.login(email: email, password: password, context: viewContext)
            
            await MainActor.run {
                isLoggingIn = false
                
                if success {
                    // Navigate to main app
                    validationError = nil
                }
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Biometric Login View
struct BiometricLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var isAuthenticating = false
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ArkheLogo(size: .large, style: .iconOnly)
                
                Text("Biometric Authentication")
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Text("Use Face ID or Touch ID to sign in")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            
            ArkheButton(
                title: isAuthenticating ? "Authenticating..." : "Authenticate",
                style: .primary,
                isFullWidth: true,
                isDisabled: isAuthenticating,
                isLoading: isAuthenticating
            ) {
                authenticateWithBiometrics()
            }
            
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.darkCharcoal)
    }
    
    private func authenticateWithBiometrics() {
        isAuthenticating = true
        
        Task {
            let success = await authManager.authenticateWithBiometrics(context: authManager.currentUser?.managedObjectContext ?? NSManagedObjectContext())
            
            await MainActor.run {
                isAuthenticating = false
                
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}