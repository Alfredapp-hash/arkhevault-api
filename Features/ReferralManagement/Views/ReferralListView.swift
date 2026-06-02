import SwiftUI

// MARK: - Referral List View
struct ReferralListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ReferralListViewModel()
    
    @State private var selectedFilter: ReferralFilter = .all
    @State private var selectedStatus: ReferralStatus = .all
    @State private var searchText = ""
    @State private var showingNewReferralSheet = false
    @State private var selectedReferral: Referral?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Referral Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Track referrals, manage partnerships, and monitor outcomes")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ForgeButton(title: "New Referral", style: .primary) {
                        showingNewReferralSheet = true
                    }
                }
                
                // Referral Metrics
                HStack(spacing: 16) {
                    ReferralMetricCard(
                        title: "Active Referrals",
                        value: "\(viewModel.activeReferrals)",
                        subtitle: "Currently in progress",
                        icon: "arrow.right.arrow.left",
                        color: .forgeTeal
                    )
                    
                    ReferralMetricCard(
                        title: "Completed",
                        value: "\(viewModel.completedThisMonth)",
                        subtitle: "This month",
                        icon: "checkmark.circle.fill",
                        color: .successGreen
                    )
                    
                    ReferralMetricCard(
                        title: "Pending",
                        value: "\(viewModel.pendingReferrals)",
                        subtitle: "Awaiting response",
                        icon: "clock.fill",
                        color: .warningGold
                    )
                    
                    ReferralMetricCard(
                        title: "Partners",
                        value: "\(viewModel.partnerCount)",
                        subtitle: "Active partners",
                        icon: "building.2",
                        color: .bronze
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ReferralFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Picker("Status", selection: $selectedStatus) {
                    ForEach(ReferralStatus.allCases, id: \.self) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search referrals...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.lightCharcoal)
                .cornerRadius(8)
                
                Spacer()
                
                Text("\(viewModel.filteredReferrals.count) referrals")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
            
            // Referral List
            if viewModel.filteredReferrals.isEmpty {
                ForgeCard {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.right.arrow.left")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No referrals found")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Create your first referral to get started")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredReferrals, id: \.id) { referral in
                            ReferralCard(referral: referral) {
                                selectedReferral = referral
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewReferralSheet) {
            NewReferralSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedReferral) { referral in
            ReferralDetailView(referral: referral)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.filter = newValue
        }
        .onChange(of: selectedStatus) { newValue in
            viewModel.statusFilter = newValue
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
    }
}

// MARK: - Referral Metric Card
struct ReferralMetricCard: View {
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
                .font(.system(size: 28, weight: .bold, design: .default))
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

// MARK: - Referral Card
struct ReferralCard: View {
    let referral: Referral
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ForgeCard(backgroundColor: statusBackgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(referral.referralDestination ?? "Referral")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            if let client = referral.client {
                                Text(client.fullName)
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            StatusBadge(
                                text: referral.status?.capitalized ?? "Unknown",
                                status: referralStatus
                            )
                            
                            if referral.consentConfirmed {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(.successGreen)
                                        .font(.brandTiny)
                                    
                                    Text("Consent")
                                        .font(.brandTiny)
                                        .foregroundColor(.successGreen)
                                }
                            }
                        }
                    }
                    
                    // Details
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let referralDate = referral.referralDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.textSecondary)
                                        .font(.brandTiny)
                                    
                                    Text("Referred: \(referralDate.formatted(date: .abbreviated, time: .omitted))")
                                        .font(.brandCaption)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            
                            if let referralType = referral.referralType {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .foregroundColor(.textSecondary)
                                        .font(.brandTiny)
                                    
                                    Text(referralType.capitalized)
                                        .font(.brandCaption)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            if let contactPerson = referral.contactPerson {
                                Text(contactPerson)
                                    .font(.brandCaption)
                                    .foregroundColor(.textPrimary)
                            }
                            
                            if let followUpDate = referral.followUpDate {
                                Text("Follow-up: \(followUpDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.brandTiny)
                                    .foregroundColor(.forgeTeal)
                            }
                        }
                    }
                    
                    // Outcome
                    if let outcome = referral.outcome {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Outcome")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                            
                            Text(outcome)
                                .font(.brandCaption)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 8) {
                        ForgeButton(title: "View Details", style: .primary) {
                            onTap()
                        }
                        
                        if referral.status == "pending" {
                            ForgeIconButton(systemImage: "checkmark", style: .secondary) {
                                // Mark as contacted
                            }
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusBackgroundColor: Color {
        switch referral.status {
        case "completed":
            return Color.successGreen.opacity(0.1)
        case "in_progress":
            return Color.forgeTeal.opacity(0.1)
        case "cancelled":
            return Color.lightCharcoal
        case "rejected":
            return Color.dangerRed.opacity(0.1)
        default:
            return Color.lightCharcoal
        }
    }
    
    private var referralStatus: StatusBadge.Status {
        switch referral.status {
        case "completed": return .success
        case "in_progress": return .active
        case "cancelled": return .neutral
        case "rejected": return .danger
        default: return .info
        }
    }
}

// MARK: - Referral List ViewModel
class ReferralListViewModel: ObservableObject {
    @Published var activeReferrals = 0
    @Published var completedThisMonth = 0
    @Published var pendingReferrals = 0
    @Published var partnerCount = 0
    @Published var referrals: [Referral] = []
    @Published var filteredReferrals: [Referral] = []
    @Published var filter: ReferralFilter = .all
    @Published var statusFilter: ReferralStatus = .all
    @Published var searchText = ""
    
    func loadData(context: NSManagedObjectContext) {
        let request = NSFetchRequest<Referral>(entityName: "Referral")
        request.sortDescriptors = [NSSortDescriptor(key: "referralDate", ascending: false)]
        
        do {
            referrals = try context.fetch(request)
            applyFilters()
            
            // Calculate metrics
            activeReferrals = referrals.filter { $0.status == "in_progress" }.count
            pendingReferrals = referrals.filter { $0.status == "pending" }.count
            
            let thisMonth = Calendar.current.dateInterval(of: .month, for: Date())
            completedThisMonth = referrals.filter { referral in
                guard let referralDate = referral.referralDate,
                      let monthInterval = thisMonth else { return false }
                return referral.status == "completed" && monthInterval.contains(referralDate)
            }.count
            
            partnerCount = Set(referrals.compactMap { $0.referralDestination }).count
            
        } catch {
            print("Error loading referrals: \(error)")
        }
    }
    
    func applyFilters() {
        filteredReferrals = referrals.filter { referral in
            // Apply status filter
            let matchesStatus: Bool
            switch statusFilter {
            case .all:
                matchesStatus = true
            case .pending:
                matchesStatus = referral.status == "pending"
            case .inProgress:
                matchesStatus = referral.status == "in_progress"
            case .completed:
                matchesStatus = referral.status == "completed"
            case .cancelled:
                matchesStatus = referral.status == "cancelled"
            }
            
            // Apply type filter
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .legal:
                matchesFilter = referral.referralType?.contains("legal") == true
            case .housing:
                matchesFilter = referral.referralType?.contains("housing") == true
            case .medical:
                matchesFilter = referral.referralType?.contains("medical") == true
            case .employment:
                matchesFilter = referral.referralType?.contains("employment") == true
            case .counseling:
                matchesFilter = referral.referralType?.contains("counseling") == true
            }
            
            // Apply search filter
            let matchesSearch = searchText.isEmpty ||
                (referral.referralDestination?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (referral.contactPerson?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            return matchesStatus && matchesFilter && matchesSearch
        }
    }
}

enum ReferralFilter: String, CaseIterable {
    case all = "All Referrals"
    case legal = "Legal"
    case housing = "Housing"
    case medical = "Medical"
    case employment = "Employment"
    case counseling = "Counseling"
    
    var displayName: String {
        rawValue
    }
}

enum ReferralStatus: String, CaseIterable {
    case all = "All Status"
    case pending = "Pending"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
    case rejected = "Rejected"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - New Referral Sheet
struct NewReferralSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedClient: Client?
    @State private var referralType: ReferralType = .legal
    @State private var referralSource: String = ""
    @State private var referralDestination: String = ""
    @State private var contactPerson: String = ""
    @State private var contactPhone: String = ""
    @State private var referralDate = Date()
    @State private var followUpDate: Date?
    @State private var notes = ""
    @State private var consentConfirmed = false
    @State private var documentsShared: [String] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Client Information")) {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select a client").tag(nil as Client?)
                        ForEach(availableClients, id: \.id) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                }
                
                Section(header: Text("Referral Details")) {
                    Picker("Referral Type", selection: $referralType) {
                        ForEach(ReferralType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Referral Source", text: $referralSource)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Referral Destination (Organization)", text: $referralDestination)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Contact Person", text: $contactPerson)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Contact Phone", text: $contactPhone)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Timing")) {
                    DatePicker("Referral Date", selection: $referralDate)
                    
                    DatePicker("Follow-up Date", selection: $followUpDate, displayedComponents: .date)
                }
                
                Section(header: Text("Consent & Documentation")) {
                    Toggle("Client Consent Confirmed", isOn: $consentConfirmed)
                    
                    if consentConfirmed {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Documents to Share")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            DocumentShareRow(
                                document: "Intake Form",
                                isShared: documentsShared.contains("intake_form")
                            ) { isShared in
                                toggleDocument("intake_form", isShared)
                            }
                            
                            DocumentShareRow(
                                document: "Case Notes",
                                isShared: documentsShared.contains("case_notes")
                            ) { isShared in
                                toggleDocument("case_notes", isShared)
                            }
                            
                            DocumentShareRow(
                                document: "Safety Assessment",
                                isShared: documentsShared.contains("safety_assessment")
                            ) { isShared in
                                toggleDocument("safety_assessment", isShared)
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Important Notice")) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.warningGold)
                        
                        Text("Client consent must be confirmed before sharing any client information with external partners.")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("New Referral")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Create Referral",
                        style: .primary,
                        isDisabled: selectedClient == nil || referralDestination.isEmpty || !consentConfirmed || isLoading,
                        isLoading: isLoading
                    ) {
                        createReferral()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private var availableClients: [Client] {
        Client.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func toggleDocument(_ document: String, _ isShared: Bool) {
        if isShared {
            documentsShared.append(document)
        } else {
            documentsShared.removeAll { $0 == document }
        }
    }
    
    private func createReferral() {
        guard let client = selectedClient,
              let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let referral = Referral(context: viewContext)
        referral.id = UUID()
        referral.client = client
        referral.referralType = referralType.rawValue
        referral.referralSource = referralSource.isEmpty ? nil : referralSource
        referral.referralDestination = referralDestination
        referral.contactPerson = contactPerson.isEmpty ? nil : contactPerson
        referral.contactPhone = contactPhone.isEmpty ? nil : contactPhone
        referral.referralDate = referralDate
        referral.followUpDate = followUpDate
        referral.status = "pending"
        referral.consentConfirmed = consentConfirmed
        referral.createdAt = Date()
        referral.createdBy = currentUser
        
        if !notes.isEmpty {
            referral.notes = notes
        }
        
        if !documentsShared.isEmpty {
            referral.documentsShared = documentsShared
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating referral: \(error)")
            isLoading = false
        }
    }
}

enum ReferralType: String, CaseIterable {
    case legal = "Legal Services"
    case housing = "Housing Assistance"
    case medical = "Medical Services"
    case employment = "Employment Services"
    case counseling = "Counseling Services"
    case financial = "Financial Assistance"
    case education = "Education & Training"
    case childCare = "Child Care Services"
    case transportation = "Transportation"
    case foodAssistance = "Food Assistance"
    case victimAdvocacy = "Victim Advocacy"
    case safeHouse = "Safe House Referral"
    
    var displayName: String {
        rawValue
    }
}

struct DocumentShareRow: View {
    let document: String
    var isShared: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isShared },
                set: { onToggle($0) }
            ))
            
            Text(document)
                .font(.brandCaption)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Referral Detail View
struct ReferralDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let referral: Referral
    
    @State private var showingUpdateStatusSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(referral.referralDestination ?? "Referral")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let client = referral.client {
                        Text(client.fullName)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if referral.status == "pending" || referral.status == "in_progress" {
                    ForgeButton(title: "Update Status", style: .primary) {
                        showingUpdateStatusSheet = true
                    }
                }
            }
            .padding()
            .background(statusBackgroundColor)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Referral Details")
                    
                    ForgeCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "list.bullet", title: "Referral Type", value: referral.referralType?.displayName ?? "Unknown")
                            InfoRow(icon: "arrow.right.arrow.left", title: "Destination", value: referral.referralDestination ?? "Unknown")
                            InfoRow(icon: "arrow.left", title: "Source", value: referral.referralSource ?? "Forged In Fire")
                            InfoRow(icon: "info.circle", title: "Status", value: referral.status?.capitalized ?? "Unknown")
                            
                            if let referralDate = referral.referralDate {
                                InfoRow(icon: "calendar", title: "Referral Date", value: referralDate.formatted(date: .long, time: .shortened))
                            }
                            
                            if let followUpDate = referral.followUpDate {
                                InfoRow(icon: "calendar.badge.exclamationmark", title: "Follow-up Date", value: followUpDate.formatted(date: .long, time: .omitted), iconColor: .forgeTeal)
                            }
                        }
                    }
                    
                    // Contact Information
                    SectionHeader(title: "Contact Information")
                    
                    ForgeCard {
                        VStack(spacing: 12) {
                            if let contactPerson = referral.contactPerson {
                                InfoRow(icon: "person.fill", title: "Contact Person", value: contactPerson)
                            }
                            
                            if let contactPhone = referral.contactPhone {
                                InfoRow(icon: "phone.fill", title: "Contact Phone", value: contactPhone)
                            }
                        }
                    }
                    
                    // Consent & Documentation
                    SectionHeader(title: "Consent & Documentation")
                    
                    ForgeCard {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: referral.consentConfirmed ? "checkmark.shield.fill" : "xmark.shield.fill")
                                    .foregroundColor(referral.consentConfirmed ? .successGreen : .dangerRed)
                                    .font(.system(size: 24))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Client Consent")
                                        .font(.brandBodyBold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(referral.consentConfirmed ? "Consent confirmed" : "Consent not confirmed")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            
                            if let documentsShared = referral.documentsShared, !documentsShared.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Documents Shared")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    ForEach(documentsShared, id: \.self) { document in
                                        HStack(spacing: 8) {
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(.forgeTeal)
                                                .font(.brandTiny)
                                            
                                            Text(document.capitalized.replacingOccurrences(of: "_", with: " "))
                                                .font(.brandCaption)
                                                .foregroundColor(.textPrimary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Outcome
                    if let outcome = referral.outcome {
                        SectionHeader(title: "Referral Outcome")
                        
                        ForgeCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Outcome")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                Text(outcome)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = referral.notes {
                        SectionHeader(title: "Notes")
                        
                        ForgeCard {
                            Text(notes)
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    
                    // Timeline
                    SectionHeader(title: "Timeline")
                    
                    ForgeCard {
                        VStack(spacing: 16) {
                            TimelineItem(
                                icon: "arrow.right.arrow.left",
                                title: "Referral Created",
                                date: referral.createdAt,
                                user: referral.createdBy?.fullName ?? "System"
                            )
                            
                            if let referralDate = referral.referralDate {
                                TimelineItem(
                                    icon: "paperplane.fill",
                                    title: "Referral Sent",
                                    date: referralDate,
                                    user: referral.createdBy?.fullName ?? "System"
                                )
                            }
                            
                            if referral.status == "completed", let followUpDate = referral.followUpDate {
                                TimelineItem(
                                    icon: "checkmark.circle.fill",
                                    title: "Referral Completed",
                                    date: followUpDate,
                                    user: referral.createdBy?.fullName ?? "System",
                                    color: .successGreen
                                )
                            }
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 12) {
                        ForgeButton(title: "Update Status", style: .primary) {
                            showingUpdateStatusSheet = true
                        }
                        
                        ForgeButton(title: "Send Follow-up", style: .secondary) {
                            // Send follow-up action
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingUpdateStatusSheet) {
            UpdateReferralStatusSheet(referral: referral)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var statusBackgroundColor: Color {
        switch referral.status {
        case "completed":
            return Color.successGreen.opacity(0.15)
        case "in_progress":
            return Color.forgeTeal.opacity(0.15)
        case "cancelled":
            return Color.lightCharcoal
        case "rejected":
            return Color.dangerRed.opacity(0.15)
        default:
            return Color.lightCharcoal
        }
    }
}

// MARK: - Update Referral Status Sheet
struct UpdateReferralStatusSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let referral: Referral
    
    @State private var newStatus: String = "in_progress"
    @State private var outcome = ""
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Update Status")) {
                    Picker("Status", selection: $newStatus) {
                        Text("Pending").tag("pending")
                        Text("In Progress").tag("in_progress")
                        Text("Completed").tag("completed")
                        Text("Cancelled").tag("cancelled")
                        Text("Rejected").tag("rejected")
                    }
                }
                
                if newStatus == "completed" {
                    Section(header: Text("Outcome")) {
                        TextField("Outcome Description", text: $outcome)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .navigationTitle("Update Referral Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Update",
                        style: .primary,
                        isDisabled: isLoading,
                        isLoading: isLoading
                    ) {
                        updateStatus()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func updateStatus() {
        isLoading = true
        
        referral.status = newStatus
        
        if newStatus == "completed" && !outcome.isEmpty {
            referral.outcome = outcome
        }
        
        if !notes.isEmpty {
            referral.notes = notes
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error updating referral: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    ReferralListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}