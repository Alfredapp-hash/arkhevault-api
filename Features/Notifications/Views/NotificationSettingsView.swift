import SwiftUI
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var notificationHistory: [NotificationEntry] = []
    
    private init() {
        checkAuthorizationStatus()
        loadNotificationHistory()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isAuthorized = granted
            }
            return granted
        } catch {
            #if DEBUG
            print("Failed to request notification authorization: \(error)")
            #endif
            await MainActor.run {
                self.isAuthorized = false
            }
            return false
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Notification Types
    
    enum NotificationType: String, CaseIterable {
        case safetyAlert = "Safety Alert"
        case taskReminder = "Task Reminder"
        case appointmentReminder = "Appointment Reminder"
        case clientUpdate = "Client Update"
        case systemUpdate = "System Update"
        case reportGenerated = "Report Generated"
        case volunteerSchedule = "Volunteer Schedule"
        case safeHouseUpdate = "Safe House Update"
    }
    
    // MARK: - Send Notification
    
    func sendNotification(
        type: NotificationType,
        title: String,
        body: String,
        userInfo: [String: Any]? = nil,
        delay: TimeInterval? = nil
    ) {
        guard isAuthorized else {
            #if DEBUG
            print("Notifications not authorized")
            #endif
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        // Add category identifier
        content.categoryIdentifier = type.rawValue
        
        let trigger: UNNotificationTrigger
        if let delay = delay {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Failed to send notification: \(error)")
                #endif
            } else {
                self.addToHistory(type: type, title: title, body: body)
            }
        }
    }
    
    // MARK: - Specific Notification Helpers
    
    func sendSafetyAlert(clientName: String, severity: String) {
        sendNotification(
            type: .safetyAlert,
            title: "Safety Alert: \(clientName)",
            body: "Severity: \(severity). Please review immediately."
        )
    }
    
    func sendTaskReminder(taskTitle: String, dueDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        sendNotification(
            type: .taskReminder,
            title: "Task Due",
            body: "\(taskTitle) is due on \(formatter.string(from: dueDate))"
        )
    }
    
    func sendAppointmentReminder(clientName: String, appointmentDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        sendNotification(
            type: .appointmentReminder,
            title: "Appointment Reminder",
            body: "Appointment with \(clientName) on \(formatter.string(from: appointmentDate))"
        )
    }
    
    func sendClientUpdate(clientName: String, updateType: String) {
        sendNotification(
            type: .clientUpdate,
            title: "Client Update: \(clientName)",
            body: "\(updateType) has been recorded."
        )
    }
    
    func sendReportGenerated(reportName: String) {
        sendNotification(
            type: .reportGenerated,
            title: "Report Generated",
            body: "\(reportName) is ready for review."
        )
    }
    
    func sendVolunteerSchedule(volunteerName: String, shiftDate: Date) {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        sendNotification(
            type: .volunteerSchedule,
            title: "Volunteer Schedule",
            body: "\(volunteerName) has a shift on \(formatter.string(from: shiftDate))"
        )
    }
    
    func sendSafeHouseUpdate(houseName: String, updateType: String) {
        sendNotification(
            type: .safeHouseUpdate,
            title: "Safe House Update",
            body: "\(houseName): \(updateType)"
        )
    }
    
    // MARK: - Scheduled Notifications
    
    func scheduleNotification(
        type: NotificationType,
        title: String,
        body: String,
        date: Date,
        userInfo: [String: Any]? = nil
    ) {
        guard isAuthorized else {
            #if DEBUG
            print("Notifications not authorized")
            #endif
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        
        content.categoryIdentifier = type.rawValue
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                #if DEBUG
                print("Failed to schedule notification: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func cancelNotifications(withIdentifier identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    // MARK: - Notification History
    
    private func addToHistory(type: NotificationType, title: String, body: String) {
        let entry = NotificationEntry(
            id: UUID(),
            type: type,
            title: title,
            body: body,
            timestamp: Date()
        )
        
        notificationHistory.insert(entry, at: 0)
        
        // Keep only last 100 notifications
        if notificationHistory.count > 100 {
            notificationHistory = Array(notificationHistory.prefix(100))
        }
        
        saveNotificationHistory()
    }
    
    private func loadNotificationHistory() {
        if let data = UserDefaults.standard.data(forKey: "notificationHistory"),
           let history = try? JSONDecoder().decode([NotificationEntry].self, from: data) {
            notificationHistory = history
        }
    }
    
    private func saveNotificationHistory() {
        if let data = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(data, forKey: "notificationHistory")
        }
    }
    
    func clearNotificationHistory() {
        notificationHistory.removeAll()
        saveNotificationHistory()
    }
}

// MARK: - Notification Entry
struct NotificationEntry: Identifiable, Codable {
    let id: UUID
    let type: NotificationManager.NotificationType
    let title: String
    let body: String
    let timestamp: Date
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var badgeEnabled = true
    @State private var notificationTypes: [NotificationManager.NotificationType: Bool] = [:]
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Notifications")
            
            // Enable Notifications
            ArkheCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Notifications")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Receive alerts and reminders")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                Task {
                                    await notificationManager.requestAuthorization()
                                }
                            } else {
                                notificationManager.cancelAllNotifications()
                            }
                        }
                }
            }
            
            if notificationsEnabled && notificationManager.isAuthorized {
                // Notification Settings
                VStack(spacing: 12) {
                    ArkheCard {
                        HStack {
                            Text("Sound")
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $soundEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        }
                    }
                    
                    ArkheCard {
                        HStack {
                            Text("Badge Count")
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Toggle("", isOn: $badgeEnabled)
                                .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        }
                    }
                }
                
                // Notification Types
                SectionHeader(title: "Notification Types")
                
                VStack(spacing: 12) {
                    ForEach(NotificationManager.NotificationType.allCases, id: \.self) { type in
                        ArkheCard {
                            HStack {
                                Text(type.rawValue)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { notificationTypes[type, default: true] },
                                    set: { notificationTypes[type] = $0 }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                            }
                        }
                    }
                }
                
                // Notification History
                SectionHeader(title: "Recent Notifications")
                
                if notificationManager.notificationHistory.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No Notifications",
                        message: "You haven't received any notifications yet."
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(notificationManager.notificationHistory.prefix(10)) { entry in
                            NotificationHistoryRow(entry: entry)
                        }
                    }
                }
                
                ArkheButton(
                    title: "Clear History",
                    style: .outline
                ) {
                    notificationManager.clearNotificationHistory()
                }
            } else if notificationsEnabled && !notificationManager.isAuthorized {
                ArkheCard {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("Notifications Not Authorized")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Enable notifications in System Settings to receive alerts.")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
        }
        .padding()
    }
}

// MARK: - Notification History Row
struct NotificationHistoryRow: View {
    let entry: NotificationEntry
    
    var body: some View {
        ArkheCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(entry.body)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                    
                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                }
                
                Spacer()
                
                BrandBadge(
                    text: entry.type.rawValue,
                    color: .forgeTeal,
                    style: .subtle
                )
            }
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo
        
        // Navigate to relevant view based on notification type
        if let notificationType = userInfo["type"] as? String {
            handleNotificationTap(type: notificationType, userInfo: userInfo)
        }
        
        completionHandler()
    }
    
    private func handleNotificationTap(type: String, userInfo: [String: Any]) {
        // Navigate to appropriate view based on notification type
        // This would typically be handled by the main app coordinator
        print("Notification tapped: \(type)")
    }
}

// MARK: - Setup Notification Delegate
extension AppDelegate {
    func setupNotifications() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Register notification categories
        let safetyCategory = UNNotificationCategory(
            identifier: "Safety Alert",
            actions: [],
            intentIdentifiers: []
        )
        
        let taskCategory = UNNotificationCategory(
            identifier: "Task Reminder",
            actions: [],
            intentIdentifiers: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            safetyCategory,
            taskCategory
        ])
    }
}

// MARK: - Preview
#Preview("Notification Settings") {
    NotificationSettingsView()
        .frame(width: 500, height: 700)
        .background(Color.deepCharcoal)
}