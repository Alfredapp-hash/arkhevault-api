import SwiftUI

// MARK: - App Error Types
enum AppError: LocalizedError {
    // Authentication Errors
    case authenticationFailed(reason: String)
    case biometricAuthenticationFailed
    case sessionExpired
    case credentialsNotFound
    
    // Network Errors
    case networkUnavailable
    case serverError(code: Int, message: String)
    case requestTimeout
    case rateLimitExceeded(resetTime: Date?)
    
    // Data Errors
    case dataCorruption
    case dataNotFound
    case saveFailed(reason: String)
    case migrationFailed
    
    // Validation Errors
    case invalidInput(field: String, reason: String)
    case missingRequiredField(field: String)
    case duplicateEntry(field: String)
    
    // File Errors
    case fileNotFound(path: String)
    case fileAccessDenied(path: String)
    fileCorrupted(path: String)
    
    // AI Service Errors
    case aiServiceUnavailable
    case aiQuotaExceeded
    case aiInvalidResponse
    
    // System Errors
    case unknownError
    
    var errorDescription: String? {
        switch self {
        // Authentication Errors
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .biometricAuthenticationFailed:
            return "Biometric authentication failed. Please try using your password."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .credentialsNotFound:
            return "Saved credentials not found. Please sign in again."
            
        // Network Errors
        case .networkUnavailable:
            return "Network connection is unavailable. Please check your internet connection."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .rateLimitExceeded(let resetTime):
            if let resetTime = resetTime {
                return "Rate limit exceeded. Please try again at \(resetTime.formatted(date: .abbreviated, time: .shortened))"
            }
            return "Rate limit exceeded. Please try again later."
            
        // Data Errors
        case .dataCorruption:
            return "Data corruption detected. Please contact support."
        case .dataNotFound:
            return "The requested data was not found."
        case .saveFailed(let reason):
            return "Failed to save changes: \(reason)"
        case .migrationFailed:
            return "Data migration failed. Please contact support."
            
        // Validation Errors
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .missingRequiredField(let field):
            return "\(field) is required."
        case .duplicateEntry(let field):
            return "A record with this \(field) already exists."
            
        // File Errors
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileAccessDenied(let path):
            return "Access denied to file: \(path)"
        case .fileCorrupted(let path):
            return "File is corrupted: \(path)"
            
        // AI Service Errors
        case .aiServiceUnavailable:
            return "AI service is temporarily unavailable. Please try again later."
        case .aiQuotaExceeded:
            return "AI service quota exceeded. Please try again later."
        case .aiInvalidResponse:
            return "Invalid response from AI service. Please try again."
            
        // System Errors
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "Please check your email and password and try again."
        case .biometricAuthenticationFailed:
            return "Use your password instead, or enable Face ID/Touch ID in Settings."
        case .sessionExpired:
            return "Please sign in again with your email and password."
        case .credentialsNotFound:
            return "Please sign in to save your credentials securely."
            
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .serverError:
            return "If the problem persists, please contact support."
        case .requestTimeout:
            return "Check your internet connection and try again."
        case .rateLimitExceeded:
            return "Wait a few minutes before making another request."
            
        case .dataCorruption:
            return "Please restore from backup or contact support."
        case .dataNotFound:
            return "The data may have been deleted or moved."
        case .saveFailed:
            return "Check your input and try again. If the problem persists, contact support."
        case .migrationFailed:
            return "Please restart the app and contact support if the problem persists."
            
        case .invalidInput:
            return "Please correct the input and try again."
        case .missingRequiredField:
            return "Please fill in this field."
        case .duplicateEntry:
            return "Please use a different value."
            
        case .fileNotFound:
            return "Please check the file path and try again."
        case .fileAccessDenied:
            return "Please check file permissions and try again."
        case .fileCorrupted:
            return "Please restore from backup or use a different file."
            
        case .aiServiceUnavailable:
            return "Wait a few minutes and try again."
        case .aiQuotaExceeded:
            return "Wait a few minutes or upgrade your plan."
        case .aiInvalidResponse:
            return "Try again or contact support if the problem persists."
            
        case .unknownError:
            return "If the problem persists, please contact support."
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var errorHistory: [ErrorEntry] = []
    
    private init() {}
    
    /// Handle an error with user-friendly display
    func handle(_ error: Error, context: String? = nil) {
        let appError = convertToAppError(error)
        
        DispatchQueue.main.async {
            self.currentError = appError
            self.showErrorAlert = true
            
            // Log error
            self.logError(appError, context: context)
            
            // Add to history
            self.addToHistory(appError, context: context)
        }
    }
    
    /// Handle error without showing alert (for background operations)
    func handleSilently(_ error: Error, context: String? = nil) {
        let appError = convertToAppError(error)
        
        DispatchQueue.main.async {
            self.logError(appError, context: context)
            self.addToHistory(appError, context: context)
        }
    }
    
    /// Dismiss current error
    func dismissError() {
        currentError = nil
        showErrorAlert = false
    }
    
    /// Convert any error to AppError
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .requestTimeout
            default:
                return .unknownError
            }
        }
        
        return .unknownError
    }
    
    /// Log error to console (in production, send to error tracking service)
    private func logError(_ error: AppError, context: String?) {
        let timestamp = Date().formatted(date: .abbreviated, time: .standard)
        let contextString = context ?? "Unknown"
        #if DEBUG
        print("[\(timestamp)] ERROR [\(contextString)]: \(error.localizedDescription)")
        #endif
        
        // In production, send to error tracking service (e.g., Sentry, Firebase Crashlytics)
    }
    
    /// Add error to history
    private func addToHistory(_ error: AppError, context: String?) {
        let entry = ErrorEntry(
            error: error,
            context: context,
            timestamp: Date()
        )
        
        errorHistory.insert(entry, at: 0)
        
        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory = Array(errorHistory.prefix(50))
        }
    }
}

// MARK: - Error Entry
struct ErrorEntry: Identifiable {
    let id = UUID()
    let error: AppError
    let context: String?
    let timestamp: Date
}

// MARK: - Error Alert View
struct ErrorAlertView: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    var body: some View {
        Alert(
            title: Text("Something went wrong"),
            message: Text(errorHandler.currentError?.errorDescription ?? "An unexpected error occurred"),
            dismissButton: .default(Text("OK")) {
                errorHandler.dismissError()
            }
        )
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.warningGold)
                .font(.brandCaption)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.errorDescription ?? "An error occurred")
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.textSecondary)
                    .font(.brandCaption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.warningGold.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.warningGold.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Error Toast View
struct ErrorToastView: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.dangerRed)
                .font(.brandCaption)
            
            Text(error.errorDescription ?? "An error occurred")
                .font(.brandBody)
                .foregroundColor(.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.dangerRed.opacity(0.9))
        .foregroundColor(.warmIvory)
        .cornerRadius(8)
        .shadow(radius: 8)
        .offset(y: isVisible ? 0 : 100)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            isVisible = true
            
            // Auto-dismiss after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                if isVisible {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Loading and Error State View
struct LoadingAndErrorView<Content: View, EmptyContent: View>: View {
    @ObservedObject var errorHandler = ErrorHandler.shared
    
    let isLoading: Bool
    let error: AppError?
    let content: Content
    let emptyContent: EmptyContent
    let onRetry: (() -> Void)?
    
    init(
        isLoading: Bool,
        error: AppError?,
        onRetry: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content,
        @ViewBuilder emptyContent: () -> EmptyContent
    ) {
        self.isLoading = isLoading
        self.error = error
        self.onRetry = onRetry
        self.content = content()
        self.emptyContent = emptyContent()
    }
    
    var body: some View {
        if isLoading {
            LoadingView()
        } else if let error = error {
            ErrorStateView(error: error, onRetry: onRetry)
        } else {
            content
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .forgeTeal))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.warningGold)
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Text(error.errorDescription ?? "An unexpected error occurred")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let onRetry = onRetry {
                ArkheButton(
                    title: "Try Again",
                    style: .primary
                ) {
                    onRetry()
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textMuted)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                ArkheButton(
                    title: actionTitle,
                    style: .secondary
                ) {
                    action()
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Usage Example Extension
extension View {
    /// Handle errors with automatic display
    func withErrorHandling() -> some View {
        self.environmentObject(ErrorHandler.shared)
    }
}

// MARK: - Preview
#Preview("Error Banner") {
    VStack {
        ErrorBannerView(error: .networkUnavailable) {
            print("Dismissed")
        }
        
        ErrorBannerView(error: .authenticationFailed(reason: "Invalid password")) {
            print("Dismissed")
        }
    }
    .padding()
    .background(Color.deepCharcoal)
}

#Preview("Error Toast") {
    ErrorToastView(error: .saveFailed(reason: "Network error")) {
        print("Dismissed")
    }
    .background(Color.deepCharcoal)
}

#Preview("Error State") {
    ErrorStateView(error: .networkUnavailable) {
        print("Retry")
    }
    .background(Color.deepCharcoal)
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "tray",
        title: "No Clients",
        message: "You haven't added any clients yet. Get started by adding your first client."
    )
    .background(Color.deepCharcoal)
}