import SwiftUI

// MARK: - Safety Dashboard View
struct SafetyDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SafetyDashboardViewModel()
    
    @State private var showingNewFlagSheet = false
    @State private var selectedFilter: SafetyFilter = .all
    @State private var selectedFlag: SafetyFlag?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safety Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Monitor and manage client safety concerns")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ForgeButton(title: "New Safety Flag", style: .danger) {
                        showingNewFlagSheet = true
                    }
                }
                
                // Safety Metrics
                HStack(spacing: 16) {
                    SafetyMetricCard(
                        title: "Active Flags",
                        value: "\(viewModel.activeFlagsCount)",
                        subtitle: "Requires attention",
                        icon: "exclamationmark.triangle.fill",
                        color: .dangerRed
                    )
                    
                    SafetyMetricCard(
                        title: "Critical Risk",
                        value: "\(viewModel.criticalRiskClients)",
                        subtitle: "Immediate attention",
                        icon: "exclamationmark.octagon.fill",
                        color: .dangerRed
                    )
                    
                    SafetyMetricCard(
                        title: "High Risk",
                        value: "\(viewModel.highRiskClients)",
                        subtitle: "Elevated concern",
                        icon: "exclamationmark.shield.fill",
                        color: .riskHigh
                    )
                    
                    SafetyMetricCard(
                        title: "Resolved Today",
                        value: "\(viewModel.resolvedToday)",
                        subtitle: "Safety improvements",
                        icon: "checkmark.shield.fill",
                        color: .successGreen
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SafetyFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Text("\(viewModel.filteredFlags.count) flags")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
            
            // Safety Flags List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredFlags, id: \.id) { flag in
                        SafetyFlagCard(flag: flag) {
                            selectedFlag = flag
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewFlagSheet) {
            NewSafetyFlagSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedFlag) { flag in
            SafetyFlagDetailView(flag: flag)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.filter = newValue
        }
    }
}

// MARK: - Safety Metric Card
struct SafetyMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .default))
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
                
                Text(subtitle)
                    .font(.brandTiny)
                    .foregroundColor(color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.lightCharcoal)
        .cornerRadius(12)
        .forgeShadow()
    }
}

// MARK: - Safety Flag Card
struct SafetyFlagCard: View {
    let flag: SafetyFlag
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ForgeCard(backgroundColor: severityBackgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(flag.flagType?.capitalized ?? "Safety Flag")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            if let client = flag.client {
                                Text(client.fullName)
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            StatusBadge(
                                text: flag.severity?.capitalized ?? "Unknown",
                                status: severityStatus
                            )
                            
                            if flag.isActive {
                                StatusBadge(text: "Active", status: .danger)
                            } else {
                                StatusBadge(text: "Resolved", status: .success)
                            }
                        }
                    }
                    
                    // Description
                    if let description = flag.descriptionText {
                        Text(description)
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Metadata
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Created: \(flag.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.brandTiny)
                                .foregroundColor(.textMuted)
                            
                            if let createdBy = flag.createdBy {
                                Text("By: \(createdBy.fullName)")
                                    .font(.brandTiny)
                                    .foregroundColor(.textMuted)
                            }
                        }
                        
                        Spacer()
                        
                        if !flag.isActive, let resolvedBy = flag.resolvedBy {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Resolved: \(flag.resolvedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                                    .font(.brandTiny)
                                    .foregroundColor(.successGreen)
                                
                                Text("By: \(resolvedBy.fullName)")
                                    .font(.brandTiny)
                                    .foregroundColor(.successGreen)
                            }
                        }
                    }
                    
                    // Quick Actions
                    if flag.isActive {
                        HStack(spacing: 8) {
                            ForgeButton(title: "Resolve", style: .secondary) {
                                // Quick resolve action
                            }
                            
                            ForgeIconButton(systemImage: "phone", style: .primary) {
                                // Call client
                            }
                            
                            ForgeIconButton(systemImage: "doc.text", style: .outline) {
                                // Add note
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var severityBackgroundColor: Color {
        switch flag.severity {
        case "critical": return Color.dangerRed.opacity(0.1)
        case "high": return Color.riskHigh.opacity(0.1)
        case "medium": return Color.warningGold.opacity(0.1)
        default: return Color.lightCharcoal
        }
    }
    
    private var severityStatus: StatusBadge.Status {
        switch flag.severity {
        case "critical": return .danger
        case "high": return .danger
        case "medium": return .warning
        default: return .info
        }
    }
}

// MARK: - Safety Dashboard ViewModel
class SafetyDashboardViewModel: ObservableObject {
    @Published var activeFlagsCount = 0
    @Published var criticalRiskClients = 0
    @Published var highRiskClients = 0
    @Published var resolvedToday = 0
    @Published var safetyFlags: [SafetyFlag] = []
    @Published var filteredFlags: [SafetyFlag] = []
    @Published var filter: SafetyFilter = .all
    
    func loadData(context: NSManagedObjectContext) {
        let request = NSFetchRequest<SafetyFlag>(entityName: "SafetyFlag")
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            safetyFlags = try context.fetch(request)
            applyFilters()
            
            // Calculate metrics
            activeFlagsCount = safetyFlags.filter { $0.isActive }.count
            
            let criticalFlags = safetyFlags.filter { $0.isActive && $0.severity == "critical" }
            criticalRiskClients = Set(criticalFlags.compactMap { $0.client?.id }).count
            
            let highFlags = safetyFlags.filter { $0.isActive && $0.severity == "high" }
            highRiskClients = Set(highFlags.compactMap { $0.client?.id }).count
            
            let today = Calendar.current.startOfDay(for: Date())
            resolvedToday = safetyFlags.filter { flag in
                guard let resolvedAt = flag.resolvedAt else { return false }
                return Calendar.current.isDate(resolvedAt, inSameDayAs: today)
            }.count
            
        } catch {
            print("Error loading safety flags: \(error)")
        }
    }
    
    func applyFilters() {
        filteredFlags = safetyFlags.filter { flag in
            switch filter {
            case .all:
                return true
            case .active:
                return flag.isActive
            case .resolved:
                return !flag.isActive
            case .critical:
                return flag.isActive && flag.severity == "critical"
            case .high:
                return flag.isActive && flag.severity == "high"
            }
        }
    }
}

enum SafetyFilter: String, CaseIterable {
    case all = "All Flags"
    case active = "Active"
    case resolved = "Resolved"
    case critical = "Critical"
    case high = "High Priority"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - New Safety Flag Sheet
struct NewSafetyFlagSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedClient: Client?
    @State private var flagType: SafetyFlagType = .immediateDanger
    @State private var severity: SafetySeverity = .high
    @State private var descriptionText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client")) {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select a client").tag(nil as Client?)
                        ForEach(availableClients, id: \.id) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                }
                
                Section(header: Text("Flag Details")) {
                    Picker("Flag Type", selection: $flagType) {
                        ForEach(SafetyFlagType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Picker("Severity", selection: $severity) {
                        ForEach(SafetySeverity.allCases, id: \.self) { severity in
                            Text(severity.displayName).tag(severity)
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 100)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Important Notice")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.warningGold)
                            
                            Text("This will create a formal safety flag that requires supervisor review.")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Text("All safety flags are logged in the audit system and may require escalation to supervisors.")
                            .font(.brandTiny)
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .navigationTitle("New Safety Flag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Create Flag",
                        style: .danger,
                        isDisabled: selectedClient == nil || descriptionText.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createSafetyFlag()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var availableClients: [Client] {
        Client.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func createSafetyFlag() {
        guard let client = selectedClient,
              let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let flag = SafetyFlag.create(
            in: viewContext,
            client: client,
            flagType: flagType.rawValue,
            description: descriptionText,
            severity: severity.rawValue,
            createdBy: currentUser
        )
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating safety flag: \(error)")
            isLoading = false
        }
    }
}

enum SafetyFlagType: String, CaseIterable {
    case immediateDanger = "Immediate Danger"
    case domesticViolence = "Domestic Violence Concern"
    case unsafeHousing = "Unsafe Housing"
    case restrainingOrder = "Restraining Order Involved"
    case courtDatePending = "Court Date Pending"
    case childrenInvolved = "Children Involved"
    case confidentialLocation = "Confidential Location"
    case safeHouseCandidate = "Safe House Candidate"
    case doNotContact = "Do Not Contact Directly"
    case highRiskOffender = "High Risk Offender Concern"
    case activeCrisis = "Active Crisis"
    
    var displayName: String {
        rawValue
    }
}

enum SafetySeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Safety Flag Detail View
struct SafetyFlagDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let flag: SafetyFlag
    
    @State private var showingResolveDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(flag.flagType?.capitalized ?? "Safety Flag")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let client = flag.client {
                        Text(client.fullName)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if flag.isActive {
                    ForgeButton(title: "Resolve Flag", style: .secondary) {
                        showingResolveDialog = true
                    }
                }
            }
            .padding()
            .background(flag.isActive ? severityBackgroundColor : Color.successGreen.opacity(0.1))
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Flag Details")
                    
                    ForgeCard {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Severity")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                Spacer()
                                
                                StatusBadge(
                                    text: flag.severity?.capitalized ?? "Unknown",
                                    status: severityStatus
                                )
                            }
                            
                            HStack {
                                Text("Status")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                Spacer()
                                
                                StatusBadge(
                                    text: flag.isActive ? "Active" : "Resolved",
                                    status: flag.isActive ? .danger : .success
                                )
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            if let description = flag.descriptionText {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(description)
                                        .font(.brandBody)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                    
                    // Client Information
                    if let client = flag.client {
                        SectionHeader(title: "Client Information")
                        
                        ForgeCard {
                            VStack(spacing: 12) {
                                InfoRow(icon: "person.fill", title: "Name", value: client.fullName)
                                
                                if let phone = client.contactPhone {
                                    InfoRow(icon: "phone.fill", title: "Phone", value: phone)
                                }
                                
                                if let email = client.contactEmail {
                                    InfoRow(icon: "envelope.fill", title: "Email", value: email)
                                }
                                
                                InfoRow(icon: "shield.fill", title: "Risk Level", value: client.riskLevel?.capitalized ?? "Unknown", iconColor: riskColor)
                                
                                if client.hasActiveSafetyFlags {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.dangerRed)
                                        
                                        Text("Has \(client.activeSafetyFlags.count) other active safety flag(s)")
                                            .font(.brandCaption)
                                            .foregroundColor(.dangerRed)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Timeline
                    SectionHeader(title: "Timeline")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            TimelineItem(
                                icon: "flag.fill",
                                title: "Flag Created",
                                date: flag.createdAt,
                                user: flag.createdBy?.fullName ?? "System"
                            )
                            
                            if let resolvedAt = flag.resolvedAt {
                                TimelineItem(
                                    icon: "checkmark.shield.fill",
                                    title: "Flag Resolved",
                                    date: resolvedAt,
                                    user: flag.resolvedBy?.fullName ?? "System",
                                    color: .successGreen
                                )
                            }
                        }
                    }
                    
                    // Actions
                    if flag.isActive {
                        SectionHeader(title: "Quick Actions")
                        
                        HStack(spacing: 12) {
                            ForgeButton(title: "Call Client", style: .primary) {
                                // Call action
                            }
                            
                            ForgeButton(title: "Add Note", style: .secondary) {
                                // Add note action
                            }
                            
                            ForgeButton(title: "Escalate", style: .danger) {
                                // Escalate action
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .alert("Resolve Safety Flag", isPresented: $showingResolveDialog) {
            Alert(
                title: Text("Resolve Safety Flag"),
                message: Text("This will mark the safety flag as resolved. The client's risk level should be reassessed after resolution."),
                primaryButton: .default(Text("Resolve")) {
                    resolveFlag()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var severityBackgroundColor: Color {
        switch flag.severity {
        case "critical": return Color.dangerRed.opacity(0.15)
        case "high": return Color.riskHigh.opacity(0.15)
        case "medium": return Color.warningGold.opacity(0.15)
        default: return Color.lightCharcoal
        }
    }
    
    private var severityStatus: StatusBadge.Status {
        switch flag.severity {
        case "critical": return .danger
        case "high": return .danger
        case "medium": return .warning
        default: return .info
        }
    }
    
    private var riskColor: Color {
        switch flag.client?.riskLevel {
        case "critical": return .riskCritical
        case "high": return .riskHigh
        case "medium": return .riskMedium
        default: return .riskLow
        }
    }
    
    private func resolveFlag() {
        guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        flag.resolve(resolvedBy: currentUser)
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Timeline Item
struct TimelineItem: View {
    let icon: String
    let title: String
    let date: Date
    let user: String
    var color: Color = .forgeTeal
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .medium))
                
                Rectangle()
                    .fill(Color.lightCharcoal)
                    .frame(width: 2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                    
                    Text("•")
                        .foregroundColor(.textMuted)
                    
                    Text(user)
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    SafetyDashboardView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}