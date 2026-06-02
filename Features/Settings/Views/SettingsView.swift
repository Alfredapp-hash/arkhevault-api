import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Configure application settings and preferences")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Settings Sections
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Settings
                    SectionHeader(title: "Profile")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            if let currentUser = viewModel.currentUser {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(Color.forgeTeal.opacity(0.2))
                                        .frame(width: 64, height: 64)
                                        .overlay(
                                            Text(currentUser.fullName.prefix(2).uppercased())
                                                .font(.brandHeading)
                                                .foregroundColor(.forgeTeal)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(currentUser.fullName)
                                            .font(.brandBodyBold)
                                            .foregroundColor(.textPrimary)
                                        
                                        if let email = currentUser.email {
                                            Text(email)
                                                .font(.brandCaption)
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        if let role = currentUser.role {
                                            Text(role.capitalized)
                                                .font(.brandTiny)
                                                .foregroundColor(.forgeTeal)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    ForgeButton(title: "Edit Profile", style: .secondary) {
                                        viewModel.showingEditProfile = true
                                    }
                                }
                            }
                        }
                    }
                    
                    // Appearance Settings
                    SectionHeader(title: "Appearance")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Dark Mode",
                                description: "Use dark appearance",
                                isOn: $viewModel.darkMode
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsToggleRow(
                                title: "Reduce Motion",
                                description: "Reduce animation effects",
                                isOn: $viewModel.reduceMotion
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Font Size",
                                description: viewModel.fontSize.displayName,
                                icon: "textformat.size"
                            ) {
                                viewModel.showingFontSizePicker = true
                            }
                        }
                    }
                    
                    // Notification Settings
                    SectionHeader(title: "Notifications")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Push Notifications",
                                description: "Receive push notifications",
                                isOn: $viewModel.pushNotifications
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsToggleRow(
                                title: "Email Notifications",
                                description: "Receive email notifications",
                                isOn: $viewModel.emailNotifications
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsToggleRow(
                                title: "Appointment Reminders",
                                description: "Get reminded about appointments",
                                isOn: $viewModel.appointmentReminders
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsToggleRow(
                                title: "Task Reminders",
                                description: "Get reminded about tasks",
                                isOn: $viewModel.taskReminders
                            )
                        }
                    }
                    
                    // Security Settings
                    SectionHeader(title: "Security")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "Biometric Authentication",
                                description: "Use Face ID or Touch ID",
                                isOn: $viewModel.biometricAuth
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Change Password",
                                description: "Update your password",
                                icon: "lock.fill"
                            ) {
                                viewModel.showingChangePassword = true
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Two-Factor Authentication",
                                description: viewModel.twoFactorEnabled ? "Enabled" : "Disabled",
                                icon: "lock.shield.fill"
                            ) {
                                viewModel.showingTwoFactorSetup = true
                            }
                        }
                    }
                    
                    // Data & Privacy
                    SectionHeader(title: "Data & Privacy")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsRow(
                                title: "Privacy Settings",
                                description: "Manage privacy preferences",
                                icon: "hand.raised.fill"
                            ) {
                                viewModel.showingPrivacySettings = true
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Export Data",
                                description: "Download your data",
                                icon: "square.and.arrow.down"
                            ) {
                                viewModel.exportData(context: viewContext)
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Clear Cache",
                                description: "Clear application cache",
                                icon: "trash.fill"
                            ) {
                                viewModel.clearCache()
                            }
                        }
                    }
                    
                    // AI Settings
                    SectionHeader(title: "AI Settings")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsToggleRow(
                                title: "AI Enhancement",
                                description: "Enable AI-powered features",
                                isOn: $viewModel.aiEnabled
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsToggleRow(
                                title: "Voice-to-Text",
                                description: "Enable speech recognition",
                                isOn: $viewModel.voiceToText
                            )
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "AI Model",
                                description: "Claude 3.5 Sonnet",
                                icon: "brain"
                            ) {
                                // AI model selection
                            }
                        }
                    }
                    
                    // About
                    SectionHeader(title: "About")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            SettingsRow(
                                title: "Version",
                                description: "1.0.0 (Build 1)",
                                icon: "info.circle"
                            ) {
                                // Version info
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Terms of Service",
                                description: "View terms and conditions",
                                icon: "doc.text"
                            ) {
                                viewModel.showingTermsOfService = true
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            SettingsRow(
                                title: "Privacy Policy",
                                description: "View privacy policy",
                                icon: "hand.raised.fill"
                            ) {
                                viewModel.showingPrivacyPolicy = true
                            }
                        }
                    }
                    
                    // Logout
                    ForgeCard {
                        ForgeButton(
                            title: "Log Out",
                            style: .danger,
                            isFullWidth: true
                        ) {
                            viewModel.logout()
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $viewModel.showingEditProfile) {
            EditProfileSheet(user: viewModel.currentUser)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showingChangePassword) {
            ChangePasswordSheet()
        }
        .sheet(isPresented: $viewModel.showingTwoFactorSetup) {
            TwoFactorSetupSheet()
        }
        .sheet(isPresented: $viewModel.showingPrivacySettings) {
            PrivacySettingsSheet()
        }
        .sheet(isPresented: $viewModel.showingFontSizePicker) {
            FontSizePickerSheet(fontSize: $viewModel.fontSize)
        }
        .sheet(isPresented: $viewModel.showingTermsOfService) {
            TermsOfServiceSheet()
        }
        .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
            PrivacyPolicySheet()
        }
        .onAppear {
            viewModel.loadCurrentUser(context: viewContext)
        }
    }
}

// MARK: - Settings ViewModel
class SettingsViewModel: ObservableObject {
    @Published var currentUser: Staff?
    @Published var darkMode = true
    @Published var reduceMotion = false
    @Published var fontSize: FontSize = .medium
    @Published var pushNotifications = true
    @Published var emailNotifications = true
    @Published var appointmentReminders = true
    @Published var taskReminders = true
    @Published var biometricAuth = true
    @Published var twoFactorEnabled = false
    @Published var aiEnabled = true
    @Published var voiceToText = true
    
    @Published var showingEditProfile = false
    @Published var showingChangePassword = false
    @Published var showingTwoFactorSetup = false
    @Published var showingPrivacySettings = false
    @Published var showingFontSizePicker = false
    @Published var showingTermsOfService = false
    @Published var showingPrivacyPolicy = false
    
    func loadCurrentUser(context: NSManagedObjectContext) {
        currentUser = Staff.fetchAll(in: context).first
    }
    
    func logout() {
        // Implement logout logic
        #if DEBUG
        print("Logging out...")
        #endif
        AuthenticationManager.shared.logout()
    }
    
    func exportData(context: NSManagedObjectContext) {
        // Implement data export
        #if DEBUG
        print("Exporting data...")
        #endif
    }
    
    func clearCache() {
        // Implement cache clearing
        #if DEBUG
        print("Clearing cache...")
        #endif
    }
}

enum FontSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    case extraLarge = "Extra Large"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Settings Components
struct SettingsToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
        }
    }
}

struct SettingsRow: View {
    let title: String
    let description: String
    let icon: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.forgeTeal)
                    .frame(width: 32, height: 32)
                    .background(Color.forgeTeal.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.brandBody)
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.textMuted)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Profile Sheet
struct EditProfileSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let user: Staff?
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var isLoading = false
    
    init(user: Staff?) {
        self.user = user
        _firstName = State(initialValue: user?.firstName ?? "")
        _lastName = State(initialValue: user?.lastName ?? "")
        _email = State(initialValue: user?.email ?? "")
        _phone = State(initialValue: user?.phone ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                    TextField("Phone", text: $phone)
                        .textContentType(.telephoneNumber)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Save",
                        style: .primary,
                        isDisabled: firstName.isEmpty || lastName.isEmpty || email.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        saveProfile()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func saveProfile() {
        guard let user = user else { return }
        
        isLoading = true
        
        user.firstName = firstName
        user.lastName = lastName
        user.email = email
        user.phone = phone.isEmpty ? nil : phone
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error saving profile: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Change Password Sheet
struct ChangePasswordSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Change Password")) {
                    SecureField("Current Password", text: $currentPassword)
                    SecureField("New Password", text: $newPassword)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Change Password",
                        style: .primary,
                        isDisabled: currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        changePassword()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func changePassword() {
        guard newPassword == confirmPassword else { return }
        
        isLoading = true
        
        // Implement password change logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Two Factor Setup Sheet
struct TwoFactorSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEnabled = false
    @State private var verificationCode = ""
    @State private var showingVerification = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Two-Factor Authentication")) {
                    Toggle("Enable Two-Factor Authentication", isOn: $isEnabled)
                    
                    if isEnabled && !showingVerification {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Two-factor authentication adds an extra layer of security to your account.")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            ForgeButton(title: "Set Up", style: .primary) {
                                showingVerification = true
                            }
                        }
                    }
                    
                    if showingVerification {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter the verification code sent to your device:")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            TextField("Verification Code", text: $verificationCode)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            ForgeButton(title: "Verify", style: .primary) {
                                // Verify code
                            }
                        }
                    }
                }
            }
            .navigationTitle("Two-Factor Authentication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Privacy Settings Sheet
struct PrivacySettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var shareData = false
    @State private var analyticsEnabled = true
    @State private var crashReportsEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Privacy Settings")) {
                    SettingsToggleRow(
                        title: "Share Data with Partners",
                        description: "Allow sharing with partner organizations",
                        isOn: $shareData
                    )
                    
                    SettingsToggleRow(
                        title: "Analytics",
                        description: "Help improve the app by sharing usage data",
                        isOn: $analyticsEnabled
                    )
                    
                    SettingsToggleRow(
                        title: "Crash Reports",
                        description: "Automatically send crash reports",
                        isOn: $crashReportsEnabled
                    )
                }
            }
            .navigationTitle("Privacy Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(title: "Done", style: .primary) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}

// MARK: - Font Size Picker Sheet
struct FontSizePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var fontSize: FontSize
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Font Size")) {
                    Picker("Font Size", selection: $fontSize) {
                        ForEach(FontSize.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Font Size")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(title: "Done", style: .primary) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }
}

// MARK: - Terms of Service Sheet
struct TermsOfServiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("""
                    By using the Forged In Fire Client Management application, you agree to these terms of service.
                    
                    1. Acceptance of Terms
                    By accessing and using this application, you accept and agree to be bound by the terms and provisions of this agreement.
                    
                    2. Privacy Policy
                    Your use of this application is also governed by our Privacy Policy. Please review our Privacy Policy, which also governs the application and informs users of our data collection practices.
                    
                    3. User Responsibilities
                    Users are responsible for maintaining the confidentiality of their account information and for all activities that occur under their account.
                    
                    4. Confidentiality
                    All client information is confidential and must be handled according to professional standards and legal requirements.
                    
                    5. Data Security
                    We implement reasonable security measures to protect your data, but no method of transmission over the Internet is 100% secure.
                    """)
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                }
                .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(title: "Done", style: .primary) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Privacy Policy Sheet
struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("""
                    Forged In Fire is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information.
                    
                    1. Information We Collect
                    We collect information you provide directly to us, such as when you create an account, update your profile, or use our services.
                    
                    2. How We Use Your Information
                    We use the information we collect to provide, maintain, and improve our services, to process transactions, and to communicate with you.
                    
                    3. Data Security
                    We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.
                    
                    4. Client Confidentiality
                    All client information is encrypted and stored securely. Access is restricted to authorized personnel only and all access is logged.
                    
                    5. Your Rights
                    You have the right to access, update, or delete your personal information. You may also opt out of certain communications.
                    """)
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(title: "Done", style: .primary) {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}