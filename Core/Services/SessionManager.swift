import Foundation
import Combine
import AppKit

// MARK: - Session Manager
/// Arkhe Vault - Manages user session lifecycle with automatic timeout for security
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isSessionActive = false
    @Published var sessionStartTime: Date?
    @Published var lastActivityTime: Date?
    
    // Configuration
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    private let warningThreshold: TimeInterval = 5 * 60 // 5 minutes before timeout
    
    private var cancellables = Set<AnyCancellable>()
    private var timeoutTimer: Timer?
    private var warningTimer: Timer?
    
    // Callbacks
    var onSessionTimeout: (() -> Void)?
    var onSessionWarning: ((TimeInterval) -> Void)?
    
    private init() {
        setupActivityMonitoring()
    }
    
    // MARK: - Session Lifecycle
    
    func startSession() {
        isSessionActive = true
        sessionStartTime = Date()
        lastActivityTime = Date()
        
        SecurityEventLogger.shared.logSessionEvent(action: "session_start")
        
        startTimeoutTimer()
        startWarningTimer()
    }
    
    func endSession() {
        isSessionActive = false
        sessionStartTime = nil
        lastActivityTime = nil
        
        SecurityEventLogger.shared.logSessionEvent(action: "session_end", reason: "logout")
        
        invalidateTimers()
    }
    
    func timeoutSession() {
        isSessionActive = false
        sessionStartTime = nil
        lastActivityTime = nil
        
        SecurityEventLogger.shared.logSessionEvent(action: "session_timeout", reason: "inactivity")
        
        invalidateTimers()
        
        // Notify observers
        DispatchQueue.main.async { [weak self] in
            self?.onSessionTimeout?()
        }
    }
    
    func recordActivity() {
        guard isSessionActive else { return }
        
        lastActivityTime = Date()
        
        // Reset timers
        invalidateTimers()
        startTimeoutTimer()
        startWarningTimer()
    }
    
    // MARK: - Timer Management
    
    private func startTimeoutTimer() {
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: sessionTimeout, repeats: false) { [weak self] _ in
            self?.timeoutSession()
        }
    }
    
    private func startWarningTimer() {
        let warningInterval = sessionTimeout - warningThreshold
        guard warningInterval > 0 else { return }
        
        warningTimer = Timer.scheduledTimer(withTimeInterval: warningInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onSessionWarning?(self.warningThreshold)
            }
        }
    }
    
    private func invalidateTimers() {
        timeoutTimer?.invalidate()
        timeoutTimer = nil
        warningTimer?.invalidate()
        warningTimer = nil
    }
    
    // MARK: - Activity Monitoring
    
    private func setupActivityMonitoring() {
        // Monitor NSEvent for macOS activity
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel]) { [weak self] _ in
            self?.recordActivity()
        }
        
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.recordActivity()
        }
    }
    
    // MARK: - Session Status
    
    var timeRemaining: TimeInterval? {
        guard let lastActivity = lastActivityTime, isSessionActive else { return nil }
        let elapsed = Date().timeIntervalSince(lastActivity)
        let remaining = sessionTimeout - elapsed
        return max(remaining, 0)
    }
    
    var sessionDuration: TimeInterval? {
        guard let startTime = sessionStartTime else { return nil }
        return Date().timeIntervalSince(startTime)
    }
    
    var formattedTimeRemaining: String {
        guard let remaining = timeRemaining else { return "--:--" }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func extendSession() {
        guard isSessionActive else { return }
        
        recordActivity()
        SecurityEventLogger.shared.logSessionEvent(action: "session_extended")
    }
}

// MARK: - Session Timeout View
import SwiftUI

struct SessionTimeoutView: View {
    @StateObject private var sessionManager = SessionManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(.forgeTeal)
            
            Text("Session Timeout")
                .font(.brandTitle)
                .foregroundColor(.textPrimary)
            
            Text("Your session has expired due to inactivity. Please sign in again to continue.")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let duration = sessionManager.sessionDuration {
                Text("Session duration: \(formatDuration(duration))")
                    .font(.brandCaption)
                    .foregroundColor(.textMuted)
            }
            
            ForgeButton(
                title: "Sign In Again",
                style: .primary,
                isFullWidth: true
            ) {
                dismiss()
                // Trigger re-authentication
                AuthenticationManager.shared.logout()
            }
        }
        .padding(32)
        .frame(width: 400)
        .background(Color.darkCharcoal)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Session Warning View

struct SessionWarningView: View {
    @StateObject private var sessionManager = SessionManager.shared
    let remainingTime: TimeInterval
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.warningYellow)
                
                Text("Session Expiring Soon")
                    .font(.brandHeading)
                    .foregroundColor(.textPrimary)
                
                Spacer()
            }
            
            Text("Your session will expire in \(sessionManager.formattedTimeRemaining) due to inactivity.")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 12) {
                Button("Logout") {
                    AuthenticationManager.shared.logout()
                }
                .buttonStyle(ForgeButtonStyle(style: .outline))
                
                Button("Continue Session") {
                    sessionManager.extendSession()
                }
                .buttonStyle(ForgeButtonStyle(style: .primary))
            }
        }
        .padding(20)
        .background(Color.darkCharcoal)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.warningYellow.opacity(0.3), lineWidth: 1)
        )
    }
}
