import SwiftUI

// MARK: - Client List View
struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ClientListViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: ClientFilter = .all
    @State private var selectedClient: Client?
    @State private var showingNewClientSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header and Search
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Client Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("\(viewModel.filteredClients.count) clients")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ForgeButton(title: "New Client", style: .primary) {
                        showingNewClientSheet = true
                    }
                }
                
                // Search and Filters
                HStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                        
                        TextField("Search clients...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .onChange(of: searchText) { newValue in
                                viewModel.searchText = newValue
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.lightCharcoal)
                    .cornerRadius(8)
                    
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(ClientFilter.allCases, id: \.self) { filter in
                            Text(filter.displayName).tag(filter)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                    .onChange(of: selectedFilter) { newValue in
                        viewModel.filter = newValue
                    }
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Client List
            if viewModel.filteredClients.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.textMuted)
                    
                    Text("No clients found")
                        .font(.brandSubheading)
                        .foregroundColor(.textSecondary)
                    
                    Text("Try adjusting your search or filters")
                        .font(.brandCaption)
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredClients, id: \.id) { client in
                            ClientRow(client: client) {
                                selectedClient = client
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.deepCharcoal)
        .sheet(item: $selectedClient) { client in
            ClientDetailView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingNewClientSheet) {
            NewClientSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadClients(context: viewContext)
        }
    }
}

// MARK: - Client Row
struct ClientRow: View {
    let client: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(Color.forgeTeal.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(client.fullName.prefix(2).uppercased())
                            .font(.brandBodyBold)
                            .foregroundColor(.forgeTeal)
                    )
                
                // Client Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        if let email = client.contactEmail {
                            Text(email)
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if let phone = client.contactPhone {
                            Text("•")
                                .foregroundColor(.textMuted)
                            
                            Text(phone)
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        RiskLevelIndicator(level: client.riskLevelEnum, showLabel: true)
                        
                        if client.hasActiveSafetyFlags {
                            StatusBadge(text: "Safety Flag", status: .danger)
                        }
                        
                        if client.activeProgramsCount > 0 {
                            Text("\(client.activeProgramsCount) programs")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status and Actions
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(
                        text: client.status?.capitalized ?? "Active",
                        status: client.status == "active" ? .active : .neutral
                    )
                    
                    Text(client.lastContactDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never")
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                }
            }
            .padding()
            .background(Color.lightCharcoal)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.lightCharcoal, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Client Detail View (Client 360)
struct ClientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let client: Client
    
    @State private var selectedTab: ClientTab = .overview
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Client Snapshot Banner
                ClientSnapshotBanner(client: client)
                    .padding()
                    .background(client.riskBackgroundColor)
                
                // Tab Selection
                Picker("Client Tab", selection: $selectedTab) {
                    ForEach(ClientTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Tab Content
                ScrollView {
                    Group {
                        switch selectedTab {
                        case .overview:
                            ClientOverviewTab(client: client)
                        case .programs:
                            ClientProgramsTab(client: client)
                        case .notes:
                            ClientNotesTab(client: client)
                        case .tasks:
                            ClientTasksTab(client: client)
                        case .documents:
                            ClientDocumentsTab(client: client)
                        case .safety:
                            ClientSafetyTab(client: client)
                        case .timeline:
                            ClientTimelineTab(client: client)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(client.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        ForgeIconButton(systemImage: "phone", style: .primary) {
                            // Initiate call
                        }
                        
                        ForgeIconButton(systemImage: "envelope", style: .secondary) {
                            // Send email
                        }
                        
                        ForgeIconButton(systemImage: "pencil", style: .outline) {
                            // Edit client
                        }
                    }
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.deepCharcoal)
    }
}

// MARK: - Client Snapshot Banner
struct ClientSnapshotBanner: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 20) {
            // Risk Level and Safety Flags
            VStack(alignment: .leading, spacing: 8) {
                RiskLevelIndicator(level: client.riskLevelEnum, showLabel: true)
                
                if client.hasActiveSafetyFlags {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.dangerRed)
                            .font(.brandTiny)
                        
                        Text("\(client.activeSafetyFlags.count) Active Flags")
                            .font(.brandTiny)
                            .foregroundColor(.dangerRed)
                    }
                }
            }
            
            Divider()
                .frame(height: 40)
            
            // Key Metrics
            VStack(alignment: .leading, spacing: 8) {
                MetricItem(icon: "star.fill", label: "Programs", value: "\(client.activeProgramsCount)")
                MetricItem(icon: "checkmark.circle", label: "Open Tasks", value: "\(client.openTasksCount)")
                MetricItem(icon: "calendar", label: "Last Contact", value: lastContactText)
            }
            
            Divider()
                .frame(height: 40)
            
            // Status Information
            VStack(alignment: .leading, spacing: 8) {
                MetricItem(icon: "house.fill", label: "Housing", value: client.housingStatus ?? "Unknown")
                MetricItem(icon: "person.fill", label: "Advocate", value: client.assignedAdvocate?.fullName ?? "Unassigned")
                if client.confidentialAddress {
                    MetricItem(icon: "lock.fill", label: "Address", value: "Confidential", iconColor: .warningGold)
                }
            }
            
            Spacer()
            
            // Quick Actions
            VStack(spacing: 8) {
                ForgeButton(title: "Call", style: .outline) {
                    // Initiate call
                }
                
                ForgeButton(title: "Note", style: .primary) {
                    // Create quick note
                }
            }
        }
        .padding()
        .cornerRadius(12)
    }
    
    private var lastContactText: String {
        guard let lastContact = client.lastContactDate else { return "Never" }
        let daysSince = Calendar.current.dateComponents([.day], from: lastContact, to: Date()).day ?? 0
        if daysSince == 0 {
            return "Today"
        } else if daysSince == 1 {
            return "Yesterday"
        } else {
            return "\(daysSince) days ago"
        }
    }
}

struct MetricItem: View {
    let icon: String
    let label: String
    let value: String
    var iconColor: Color = .forgeTeal
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.brandTiny)
                    .foregroundColor(.textSecondary)
                
                Text(value)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Client Tabs
enum ClientTab: String, CaseIterable {
    case overview = "Overview"
    case programs = "Programs"
    case notes = "Notes"
    case tasks = "Tasks"
    case documents = "Documents"
    case safety = "Safety"
    case timeline = "Timeline"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Tab Views (Placeholders for now)
struct ClientOverviewTab: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 20) {
            // Personal Information
            SectionHeader(title: "Personal Information")
            
            ForgeCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "person.fill", title: "Full Name", value: client.fullName)
                    if let dob = client.dateOfBirth {
                        InfoRow(icon: "calendar", title: "Date of Birth", value: dob.formatted(date: .long, time: .omitted))
                    }
                    if let email = client.contactEmail {
                        InfoRow(icon: "envelope.fill", title: "Email", value: email)
                    }
                    if let phone = client.contactPhone {
                        InfoRow(icon: "phone.fill", title: "Phone", value: phone)
                    }
                    if let biography = client.biography, !biography.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Biography")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            Text(biography)
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }
            
            // Emergency Contact
            if client.emergencyContactName != nil || client.emergencyContactPhone != nil {
                SectionHeader(title: "Emergency Contact")
                
                ForgeCard {
                    VStack(spacing: 12) {
                        if let name = client.emergencyContactName {
                            InfoRow(icon: "person.2.fill", title: "Contact Name", value: name)
                        }
                        if let phone = client.emergencyContactPhone {
                            InfoRow(icon: "phone.fill", title: "Contact Phone", value: phone)
                        }
                    }
                }
            }
            
            // Status Information
            SectionHeader(title: "Status Information")
            
            ForgeCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "house.fill", title: "Housing Status", value: client.housingStatus ?? "Unknown")
                    InfoRow(icon: "briefcase.fill", title: "Employment Status", value: client.employmentStatus ?? "Unknown")
                    InfoRow(icon: "car.fill", title: "Transportation Status", value: client.transportationStatus ?? "Unknown")
                    
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.forgeTeal)
                        
                        Text("Veteran Status")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        Spacer()
                        
                        Text(client.veteranStatus ? "Yes" : "No")
                            .font(.brandCaption)
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
    }
}

struct ClientProgramsTab: View {
    let client: Client
    
    var body: some View {
        ForgeCard {
            Text("Program enrollments coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ClientNotesTab: View {
    let client: Client
    
    var body: some View {
        ForgeCard {
            Text("Case notes coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ClientTasksTab: View {
    let client: Client
    
    var body: some View {
        ForgeCard {
            Text("Tasks coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ClientDocumentsTab: View {
    let client: Client
    
    var body: some View {
        ForgeCard {
            Text("Documents coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ClientSafetyTab: View {
    let client: Client
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Safety Flags")
            
            if client.hasActiveSafetyFlags {
                ForEach(client.activeSafetyFlags, id: \.id) { flag in
                    SafetyFlagCard(flag: flag)
                }
            } else {
                ForgeCard {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.successGreen)
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No Active Safety Flags")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Client has no current safety concerns flagged")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            
            SectionHeader(title: "Safe Contact Rules")
            
            ForgeCard {
                Text("Safe contact rules configuration coming soon")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct ClientTimelineTab: View {
    let client: Client
    
    var body: some View {
        ForgeCard {
            Text("Activity timeline coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Supporting Views
struct SafetyFlagCard: View {
    let flag: SafetyFlag
    
    var body: some View {
        ForgeCard(backgroundColor: severityBackgroundColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(flag.flagType?.capitalized ?? "Safety Flag")
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    StatusBadge(text: flag.severity?.capitalized ?? "Unknown", status: severityStatus)
                }
                
                if let description = flag.descriptionText {
                    Text(description)
                        .font(.brandBody)
                        .foregroundColor(.textSecondary)
                }
                
                HStack {
                    Text("Created: \(flag.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                    
                    Spacer()
                }
            }
        }
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

// MARK: - New Client Sheet
struct NewClientSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isLoading = false
    
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
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(title: "Create", style: .primary, isDisabled: isLoading) {
                        createClient()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func createClient() {
        guard !firstName.isEmpty && !lastName.isEmpty else { return }
        
        isLoading = true
        
        let client = Client.create(
            in: viewContext,
            firstName: firstName,
            lastName: lastName,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone
        )
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating client: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Client List ViewModel
class ClientListViewModel: ObservableObject {
    @Published var clients: [Client] = []
    @Published var filteredClients: [Client] = []
    @Published var searchText = ""
    @Published var filter: ClientFilter = .all
    
    func loadClients(context: NSManagedObjectContext) {
        clients = Client.fetchAll(in: context)
        applyFilters()
    }
    
    func applyFilters() {
        filteredClients = clients.filter { client in
            // Apply search filter
            let matchesSearch = searchText.isEmpty ||
                client.fullName.localizedCaseInsensitiveContains(searchText) ||
                (client.contactEmail?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            // Apply status filter
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = client.status == "active"
            case .inactive:
                matchesFilter = client.status == "inactive"
            case .highRisk:
                matchesFilter = client.riskLevel == "high" || client.riskLevel == "critical"
            case .hasSafetyFlags:
                matchesFilter = client.hasActiveSafetyFlags
            }
            
            return matchesSearch && matchesFilter
        }
    }
}

enum ClientFilter: String, CaseIterable {
    case all = "All Clients"
    case active = "Active"
    case inactive = "Inactive"
    case highRisk = "High Risk"
    case hasSafetyFlags = "Safety Flags"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Client Extensions
extension Client {
    var riskBackgroundColor: Color {
        switch riskLevel {
        case "critical": return Color.dangerRed.opacity(0.15)
        case "high": return Color.riskHigh.opacity(0.15)
        case "medium": return Color.warningGold.opacity(0.15)
        default: return Color.successGreen.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    ClientListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}