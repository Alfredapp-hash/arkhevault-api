import SwiftUI
import Network

// MARK: - Offline Manager
class OfflineManager: ObservableObject {
    static let shared = OfflineManager()
    
    @Published var isOnline = true
    @Published var syncStatus: SyncStatus = .idle
    @Published var pendingChanges: Int = 0
    @Published var lastSyncDate: Date?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.arkheholdings.vault.network")
    private let context: NSManagedObjectContext
    
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed
    }
    
    private init(context: NSManagedObjectContext = CoreDataController.shared.container.viewContext) {
        self.context = context
        startMonitoring()
        loadLastSyncDate()
        countPendingChanges()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                if self?.isOnline == true {
                    self?.syncPendingChanges()
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Sync Operations
    
    func syncPendingChanges() {
        guard isOnline else {
            #if DEBUG
            print("Cannot sync: offline")
            #endif
            return
        }
        
        syncStatus = .syncing
        
        Task {
            do {
                try await performSync()
                await MainActor.run {
                    self.syncStatus = .success
                    self.lastSyncDate = Date()
                    self.saveLastSyncDate()
                    self.countPendingChanges()
                }
            } catch {
                await MainActor.run {
                    self.syncStatus = .failed
                    #if DEBUG
                    print("Sync failed: \(error)")
                    #endif
                }
            }
        }
    }
    
    private func performSync() async throws {
        // Fetch all pending changes
        let pendingChanges = try fetchPendingChanges()
        
        // Sync each change
        for change in pendingChanges {
            try await syncChange(change)
        }
        
        // Mark changes as synced
        try markChangesAsSynced(pendingChanges)
    }
    
    private func fetchPendingChanges() throws -> [PendingChange] {
        let request = NSFetchRequest<PendingChange>(entityName: "PendingChange")
        request.predicate = NSPredicate(format: "synced == NO")
        return try context.fetch(request)
    }
    
    private func syncChange(_ change: PendingChange) async throws {
        // Implement actual sync logic with secure connection
        // All API calls use TLS 1.3 with AES-256-GCM via NetworkSecurityManager
        
        let baseURL = Configuration.shared.apiBaseURL
        guard let url = URL(string: "\(baseURL)/api/sync") else {
            throw NetworkSecurityError.invalidResponse
        }
        
        // Use secure session for all sync operations
        let (_, response) = try await NetworkSecurityManager.shared.performSecureRequest(
            url: url,
            method: "POST",
            headers: [
                "Content-Type": "application/json",
                "X-Sync-Token": change.id?.uuidString ?? ""
            ]
        )
        
        guard response.statusCode == 200 else {
            throw NetworkSecurityError.invalidResponse
        }
        
        // Validate TLS security
        let validation = NetworkSecurityManager.shared.validateConnectionSecurity(for: response)
        if case .failed(let reason) = validation {
            SecurityEventLogger.shared.logDataEvent(
                action: "sync_security_validation_failed",
                success: false,
                context: reason
            )
        }
    }
    
    private func markChangesAsSynced(_ changes: [PendingChange]) throws {
        for change in changes {
            change.synced = true
            change.syncedAt = Date()
        }
        try context.save()
    }
    
    // MARK: - Queue Changes
    
    func queueChange<T: NSManagedObject>(
        entity: T,
        operation: ChangeOperation,
        entityName: String,
        entityId: UUID
    ) {
        let pendingChange = PendingChange(context: context)
        pendingChange.id = UUID()
        pendingChange.entityName = entityName
        pendingChange.entityId = entityId.uuidString
        pendingChange.operation = operation.rawValue
        pendingChange.synced = false
        pendingChange.createdAt = Date()
        
        // Store entity data as JSON
        if let data = try? JSONEncoder().encode(entity) {
            pendingChange.entityData = String(data: data, encoding: .utf8)
        }
        
        do {
            try context.save()
            countPendingChanges()
            
            // Try to sync immediately if online
            if isOnline {
                syncPendingChanges()
            }
        } catch {
            #if DEBUG
            print("Failed to queue change: \(error)")
            #endif
        }
    }
    
    enum ChangeOperation: String {
        case create
        case update
        case delete
    }
    
    // MARK: - Pending Changes Count
    
    private func countPendingChanges() {
        let request = NSFetchRequest<PendingChange>(entityName: "PendingChange")
        request.predicate = NSPredicate(format: "synced == NO")
        
        do {
            let count = try context.count(for: request)
            pendingChanges = count
        } catch {
            #if DEBUG
            print("Failed to count pending changes: \(error)")
            #endif
        }
    }
    
    // MARK: - Last Sync Date
    
    private func loadLastSyncDate() {
        if let timestamp = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date {
            lastSyncDate = timestamp
        }
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "lastSyncDate")
        }
    }
    
    // MARK: - Offline Mode Toggle
    
    func setOfflineMode(_ offline: Bool) {
        if offline {
            // Force offline mode
            monitor.cancel()
            isOnline = false
        } else {
            // Resume monitoring
            startMonitoring()
        }
    }
}

// MARK: - Pending Change Entity (Add to Core Data)
// This entity needs to be added to the Core Data model:
/*
class PendingChange: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var entityName: String
    @NSManaged public var entityId: String
    @NSManaged public var operation: String
    @NSManaged public var entityData: String?
    @NSManaged public var synced: Bool
    @NSManaged public var syncedAt: Date?
    @NSManaged public var createdAt: Date
}
*/

// MARK: - Offline Status Banner
struct OfflineStatusBanner: View {
    @ObservedObject var offlineManager = OfflineManager.shared
    
    var body: some View {
        if !offlineManager.isOnline {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.warningGold)
                    .font(.brandCaption)
                
                Text("You're offline. Changes will be synced when you reconnect.")
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if offlineManager.pendingChanges > 0 {
                    Text("\(offlineManager.pendingChanges) pending")
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.warningGold.opacity(0.15))
            .overlay(
                Rectangle()
                    .stroke(Color.warningGold.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Sync Status Indicator
struct SyncStatusIndicator: View {
    @ObservedObject var offlineManager = OfflineManager.shared
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: syncIcon)
                .foregroundColor(syncColor)
                .font(.brandCaption)
            
            Text(syncText)
                .font(.brandCaption)
                .foregroundColor(.textSecondary)
            
            if let lastSync = offlineManager.lastSyncDate {
                Text("Last sync: \(lastSync.formatted(date: .abbreviated, time: .shortened))")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
            }
        }
    }
    
    private var syncIcon: String {
        switch offlineManager.syncStatus {
        case .idle:
            return offlineManager.isOnline ? "checkmark.circle" : "wifi.slash"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var syncColor: Color {
        switch offlineManager.syncStatus {
        case .idle:
            return offlineManager.isOnline ? .successGreen : .textMuted
        case .syncing:
            return .forgeTeal
        case .success:
            return .successGreen
        case .failed:
            return .dangerRed
        }
    }
    
    private var syncText: String {
        switch offlineManager.syncStatus {
        case .idle:
            return offlineManager.isOnline ? "Synced" : "Offline"
        case .syncing:
            return "Syncing..."
        case .success:
            return "Synced"
        case .failed:
            return "Sync Failed"
        }
    }
}

// MARK: - Offline Settings View
struct OfflineSettingsView: View {
    @ObservedObject var offlineManager = OfflineManager.shared
    @State private var forceOfflineMode = false
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Offline Mode")
            
            // Connection Status
            ArkheCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Connection Status")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(offlineManager.isOnline ? "Online" : "Offline")
                            .font(.brandCaption)
                            .foregroundColor(offlineManager.isOnline ? .successGreen : .warningGold)
                    }
                    
                    Spacer()
                    
                    Image(systemName: offlineManager.isOnline ? "wifi" : "wifi.slash")
                        .font(.system(size: 24))
                        .foregroundColor(offlineManager.isOnline ? .successGreen : .warningGold)
                }
            }
            
            // Force Offline Mode
            ArkheCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Force Offline Mode")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("Disable all network connections")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $forceOfflineMode)
                        .toggleStyle(SwitchToggleStyle(tint: .forgeTeal))
                        .onChange(of: forceOfflineMode) { newValue in
                            offlineManager.setOfflineMode(newValue)
                        }
                }
            }
            
            // Sync Status
            SectionHeader(title: "Sync Status")
            
            ArkheCard {
                VStack(spacing: 12) {
                    SyncStatusIndicator()
                    
                    if offlineManager.pendingChanges > 0 {
                        HStack {
                            Text("Pending Changes")
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                            
                            Spacer()
                            
                            Text("\(offlineManager.pendingChanges)")
                                .font(.brandBodyBold)
                                .foregroundColor(.warningGold)
                        }
                        
                        ArkheButton(
                            title: "Sync Now",
                            style: .primary,
                            isDisabled: !offlineManager.isOnline
                        ) {
                            offlineManager.syncPendingChanges()
                        }
                    }
                }
            }
            
            // Offline Capabilities
            SectionHeader(title: "Offline Capabilities")
            
            VStack(spacing: 12) {
                CapabilityRow(
                    icon: "person.text.rectangle",
                    title: "Client Management",
                    isAvailable: true
                )
                
                CapabilityRow(
                    icon: "note.text",
                    title: "Case Notes",
                    isAvailable: true
                )
                
                CapabilityRow(
                    icon: "calendar",
                    title: "Calendar (View Only)",
                    isAvailable: true
                )
                
                CapabilityRow(
                    icon: "sparkles",
                    title: "AI Features",
                    isAvailable: false
                )
                
                CapabilityRow(
                    icon: "doc.text.viewfinder",
                    title: "Document OCR",
                    isAvailable: false
                )
                
                CapabilityRow(
                    icon: "chart.bar",
                    title: "Reporting",
                    isAvailable: true
                )
            }
            
            // Offline Data Management
            SectionHeader(title: "Offline Data")
            
            ArkheButton(
                title: "Clear Offline Data",
                style: .danger
            ) {
                clearOfflineData()
            }
        }
        .padding()
    }
    
    private func clearOfflineData() {
        // Clear all pending changes
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "PendingChange")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try CoreDataController.shared.container.viewContext.execute(deleteRequest)
            offlineManager.pendingChanges = 0
        } catch {
            print("Failed to clear offline data: \(error)")
        }
    }
}

// MARK: - Capability Row
struct CapabilityRow: View {
    let icon: String
    let title: String
    let isAvailable: Bool
    
    var body: some View {
        ArkheCard {
            HStack {
                Image(systemName: icon)
                    .font(.brandCaption)
                    .foregroundColor(isAvailable ? .successGreen : .textMuted)
                    .frame(width: 20)
                
                Text(title)
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if isAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.successGreen)
                        .font(.brandCaption)
                } else {
                    Text("Online Only")
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                }
            }
        }
    }
}

// MARK: - Offline Data Saver (Extension for Core Data)
extension NSManagedObject {
    func saveOffline(operation: OfflineManager.ChangeOperation) {
        OfflineManager.shared.queueChange(
            entity: self,
            operation: operation,
            entityName: String(describing: type(of: self)),
            entityId: self.value(forKey: "id") as? UUID ?? UUID()
        )
    }
}

// MARK: - Preview
#Preview("Offline Settings") {
    OfflineSettingsView()
        .frame(width: 500, height: 700)
        .background(Color.deepCharcoal)
}

#Preview("Offline Banner") {
    VStack {
        OfflineStatusBanner()
        Spacer()
    }
    .padding()
    .background(Color.deepCharcoal)
}