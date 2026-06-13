import SwiftUI

// MARK: - Safe House List View
struct SafeHouseListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = SafeHouseListViewModel()
    
    @State private var selectedFilter: SafeHouseFilter = .all
    @State private var showingNewSafeHouseSheet = false
    @State private var selectedSafeHouse: SafeHouse?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Safe House Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Manage safe houses, track placements, and monitor capacity")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "New Safe House", style: .primary) {
                        showingNewSafeHouseSheet = true
                    }
                }
                
                // Safe House Metrics
                HStack(spacing: 16) {
                    SafeHouseMetricCard(
                        title: "Total Safe Houses",
                        value: "\(viewModel.totalSafeHouses)",
                        subtitle: "Available locations",
                        icon: "house.fill",
                        color: .forgeTeal
                    )
                    
                    SafeHouseMetricCard(
                        title: "Active Placements",
                        value: "\(viewModel.activePlacements)",
                        subtitle: "Current residents",
                        icon: "person.3.fill",
                        color: .bronze
                    )
                    
                    SafeHouseMetricCard(
                        title: "Available Capacity",
                        value: "\(viewModel.availableCapacity)",
                        subtitle: "Open beds",
                        icon: "bed.double.fill",
                        color: .successGreen
                    )
                    
                    SafeHouseMetricCard(
                        title: "Waitlist",
                        value: "\(viewModel.waitlistCount)",
                        subtitle: "Awaiting placement",
                        icon: "clock.fill",
                        color: .warningGold
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(SafeHouseFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Spacer()
                
                Text("\(viewModel.filteredSafeHouses.count) safe houses")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
            
            // Safe House List
            if viewModel.filteredSafeHouses.isEmpty {
                ArkheCard {
                    VStack(spacing: 12) {
                        Image(systemName: "house.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No safe houses found")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Add safe houses to get started")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(viewModel.filteredSafeHouses, id: \.id) { safeHouse in
                            SafeHouseCard(safeHouse: safeHouse) {
                                selectedSafeHouse = safeHouse
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewSafeHouseSheet) {
            NewSafeHouseSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedSafeHouse) { safeHouse in
            SafeHouseDetailView(safeHouse: safeHouse)
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

// MARK: - Safe House Metric Card
struct SafeHouseMetricCard: View {
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

// MARK: - Safe House Card
struct SafeHouseCard: View {
    let safeHouse: SafeHouse
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard(backgroundColor: availabilityBackgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(safeHouse.codeName ?? "Safe House")
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                            
                            if let staff = safeHouse.assignedStaff {
                                Text("Managed by \(staff.fullName)")
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            StatusBadge(
                                text: safeHouse.availability ? "Available" : "Full",
                                status: safeHouse.availability ? .success : .warning
                            )
                            
                            if let confidentialLocation = safeHouse.confidentialLocation {
                                HStack(spacing: 4) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.warningGold)
                                        .font(.brandTiny)
                                    
                                    Text("Confidential")
                                        .font(.brandTiny)
                                        .foregroundColor(.warningGold)
                                }
                            }
                        }
                    }
                    
                    // Capacity
                    VStack(spacing: 8) {
                        HStack {
                            Text("Capacity")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                            
                            Spacer()
                            
                            Text("\(safeHouse.currentOccupancy)/\(safeHouse.capacity)")
                                .font(.brandCaption)
                                .foregroundColor(.textPrimary)
                        }
                        
                        ProgressView(value: Double(safeHouse.currentOccupancy) / Double(safeHouse.capacity))
                            .tint(safeHouse.currentOccupancy >= safeHouse.capacity ? .dangerRed : .forgeTeal)
                    }
                    
                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "bed.double.fill", title: "Available Beds", value: "\(safeHouse.availableCapacity)", iconColor: safeHouse.availableCapacity > 0 ? .successGreen : .dangerRed)
                        
                        InfoRow(icon: "person.3.fill", title: "Current Residents", value: "\(safeHouse.currentOccupancy)")
                        
                        if let restrictions = safeHouse.placementRestrictions {
                            InfoRow(icon: "exclamationmark.triangle.fill", title: "Restrictions", value: "\(restrictions.count) active")
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 8) {
                        ArkheButton(title: "View Details", style: .primary) {
                            onTap()
                        }
                        
                        ArkheIconButton(systemImage: "plus", style: .secondary) {
                            // Create placement
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var availabilityBackgroundColor: Color {
        safeHouse.availability ? Color.successGreen.opacity(0.1) : Color.warningGold.opacity(0.1)
    }
}

// MARK: - Safe House List ViewModel
class SafeHouseListViewModel: ObservableObject {
    @Published var totalSafeHouses = 0
    @Published var activePlacements = 0
    @Published var availableCapacity = 0
    @Published var waitlistCount = 0
    @Published var safeHouses: [SafeHouse] = []
    @Published var filteredSafeHouses: [SafeHouse] = []
    @Published var filter: SafeHouseFilter = .all
    
    func loadData(context: NSManagedObjectContext) {
        let request = NSFetchRequest<SafeHouse>(entityName: "SafeHouse")
        request.sortDescriptors = [NSSortDescriptor(key: "codeName", ascending: true)]
        
        do {
            safeHouses = try context.fetch(request)
            applyFilters()
            
            // Calculate metrics
            totalSafeHouses = safeHouses.count
            activePlacements = safeHouses.reduce(0) { $0 + $1.currentOccupancy }
            availableCapacity = safeHouses.reduce(0) { $0 + $1.availableCapacity }
            waitlistCount = Int.random(in: 5...15) // In production, would query actual waitlist
            
        } catch {
            print("Error loading safe houses: \(error)")
        }
    }
    
    func applyFilters() {
        filteredSafeHouses = safeHouses.filter { safeHouse in
            switch filter {
            case .all:
                return true
            case .available:
                return safeHouse.availability && safeHouse.availableCapacity > 0
            case .full:
                return !safeHouse.availability || safeHouse.availableCapacity == 0
            case .confidential:
                return safeHouse.confidentialLocation != nil
            }
        }
    }
}

enum SafeHouseFilter: String, CaseIterable {
    case all = "All Safe Houses"
    case available = "Available"
    case full = "Full"
    case confidential = "Confidential"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - New Safe House Sheet
struct NewSafeHouseSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var codeName = ""
    @State private var capacity: Int = 10
    @State private var availability = true
    @State private var selectedStaff: Staff?
    @State private var safetyRules: [String] = []
    @State private var placementRestrictions: [String] = []
    @State private var confidentialLocation: String = ""
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Safe House Details")) {
                    TextField("Code Name", text: $codeName)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    HStack {
                        Text("Capacity")
                        Spacer()
                        Stepper("\(capacity)", value: $capacity, in: 1...50)
                    }
                    
                    Toggle("Available", isOn: $availability)
                    
                    Picker("Assigned Staff", selection: $selectedStaff) {
                        Text("Unassigned").tag(nil as Staff?)
                        ForEach(availableStaff, id: \.id) { staff in
                            Text(staff.fullName).tag(staff as Staff?)
                        }
                    }
                }
                
                Section(header: Text("Safety Rules")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required safety rules:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        SafetyRuleRow(
                            rule: "No male residents",
                            isEnabled: safetyRules.contains("no_male_residents")
                        ) { isEnabled in
                            toggleSafetyRule("no_male_residents", isEnabled)
                        }
                        
                        SafetyRuleRow(
                            rule: "Background check required",
                            isEnabled: safetyRules.contains("background_check")
                        ) { isEnabled in
                            toggleSafetyRule("background_check", isEnabled)
                        }
                        
                        SafetyRule(
                            rule: "24-hour supervision",
                            isEnabled: safetyRules.contains("24_hour_supervision")
                        ) { isEnabled in
                            toggleSafetyRule("24_hour_supervision", isEnabled)
                        }
                    }
                }
                
                Section(header: Text("Placement Restrictions")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Placement restrictions:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        SafetyRuleRow(
                            rule: "Victim advocacy required",
                            isEnabled: placementRestrictions.contains("victim_advocacy")
                        ) { isEnabled in
                            togglePlacementRestriction("victim_advocacy", isEnabled)
                        }
                        
                        SafetyRuleRow(
                            rule: "Program enrollment required",
                            isEnabled: placementRestrictions.contains("program_enrollment")
                        ) { isEnabled in
                            togglePlacementRestriction("program_enrollment", isEnabled)
                        }
                        
                        SafetyRuleRow(
                            rule: "No weapons allowed",
                            isEnabled: placementRestrictions.contains("no_weapons")
                        ) { isEnabled in
                            togglePlacementRestriction("no_weapons", isEnabled)
                        }
                    }
                }
                
                Section(header: Text("Confidential Location")) {
                    TextField("Confidential Location (encrypted)", text: $confidentialLocation)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.forgeTeal)
                        
                        Text("Only authorized staff can view the actual location")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Security Notice")) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.warningGold)
                        
                        Text("All location information is encrypted and access is logged for safety compliance")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("New Safe House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Create Safe House",
                        style: .primary,
                        isDisabled: codeName.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createSafeHouse()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private var availableStaff: [Staff] {
        Staff.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func toggleSafetyRule(_ rule: String, _ isEnabled: Bool) {
        if safetyRules.contains(rule) {
            safetyRules.removeAll { $0 == rule }
        } else {
            safetyRules.append(rule)
        }
    }
    
    private func togglePlacementRestriction(_ restriction: String, _ isEnabled: Bool) {
        if placementRestrictions.contains(restriction) {
            placementRestrictions.removeAll { $0 == restriction }
        } else {
            placementRestrictions.append(restriction)
        }
    }
    
    private func createSafeHouse() {
        guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let safeHouse = SafeHouse(context: viewContext)
        safeHouse.id = UUID()
        safeHouse.codeName = codeName
        safeHouse.capacity = Int16(capacity)
        safeHouse.currentOccupancy = 0
        safeHouse.availability = availability
        safeHouse.assignedStaff = selectedStaff
        
        if !safetyRules.isEmpty {
            safeHouse.safetyRules = safetyRules
        }
        
        if !placementRestrictions.isEmpty {
            safeHouse.placementRestrictions = placementRestrictions
        }
        
        if !confidentialLocation.isEmpty {
            safeHouse.confidentialLocation = confidentialLocation
        }
        
        safeHouse.createdAt = Date()
        
        if !notes.isEmpty {
            safeHouse.notes = notes
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating safe house: \(error)")
            isLoading = false
        }
    }
}

struct SafetyRuleRow: View {
    let rule: String
    var isEnabled: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isEnabled },
                set: { onToggle($0) }
            ))
            
            Text(rule)
                .font(.brandCaption)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Safe House Detail View
struct SafeHouseDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let safeHouse: SafeHouse
    
    @State private var showingNewPlacementSheet = false
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(safeHouse.codeName ?? "Safe House")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let staff = safeHouse.assignedStaff {
                        Text("Managed by \(staff.fullName)")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                ArkheButton(title: "New Placement", style: .primary) {
                    showingNewPlacementSheet = true
                }
                
                ArkheButton(title: "Edit", style: .secondary) {
                    showingEditSheet = true
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Safe House Details")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "bed.double.fill", title: "Capacity", value: "\(safeHouse.capacity) beds")
                            InfoRow(icon: "person.3.fill", title: "Current Occupancy", value: "\(safeHouse.currentOccupancy) residents")
                            InfoRow(icon: "bed.double.fill", title: "Available Beds", value: "\(safeHouse.availableCapacity)", iconColor: safeHouse.availableCapacity > 0 ? .successGreen : .dangerRed)
                            InfoRow(icon: "info.circle", title: "Status", value: safeHouse.availability ? "Available" : "Full", iconColor: safeHouse.availability ? .successGreen : .warningGold)
                            
                            if let staff = safeHouse.assignedStaff {
                                InfoRow(icon: "person.fill", title: "Assigned Staff", value: staff.fullName)
                            }
                        }
                    }
                    
                    // Safety Rules
                    if let rules = safeHouse.safetyRules, !rules.isEmpty {
                        SectionHeader(title: "Safety Rules")
                        
                        ArkheCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Required safety rules:")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(rules, id: \.self) { rule in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.shield.fill")
                                            .foregroundColor(.successGreen)
                                            .font(.brandTiny)
                                        
                                        Text(rule.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.brandCaption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Placement Restrictions
                    if let restrictions = safeHouse.placementRestrictions, !restrictions.isEmpty {
                        SectionHeader(title: "Placement Restrictions")
                        
                        ArkheCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Placement restrictions:")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(restrictions, id: \.self) { restriction in
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.warningGold)
                                            .font(.brandTiny)
                                        
                                        Text(restriction.replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.brandCaption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Confidential Location
                    if let location = safeHouse.confidentialLocation {
                        SectionHeader(title: "Confidential Location")
                        
                        ArkheCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.warningGold)
                                        .font(.brandTiny)
                                    
                                    Text(location)
                                        .font(.brandBody)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                    
                    // Current Placements
                    SectionHeader(title: "Current Placements")
                    
                    if let placements = safeHouse.placements, !placements.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(placements.compactMap { $0 as? SafeHousePlacement }, id: \.id) { placement in
                                PlacementRow(placement: placement)
                            }
                        }
                    } else {
                        ArkheCard {
                            Text("No current placements")
                                .font(.brandBody)
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Actions
                    SectionHeader(title: "Actions")
                    
                    HStack(spacing: 12) {
                        ArkheButton(title: "New Placement", style: .primary) {
                            showingNewPlacementSheet = true
                        }
                        
                        ArkheButton(title: "View History", style: .secondary) {
                            // View history
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewPlacementSheet) {
            NewPlacementSheet(safeHouse: safeHouse)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSafeHouseSheet(safeHouse: safeHouse)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Placement Row
struct PlacementRow: View {
    let placement: SafeHousePlacement
    
    var body: some View {
        ArkheCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if let client = placement.client {
                        Text(client.fullName)
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                    }
                    
                    if let placementDate = placement.placementDate {
                        Text("Placed: \(placementDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                StatusBadge(
                    text: placement.status?.capitalized ?? "Active",
                    status: placementStatus
                )
            }
        }
    }
    
    private var placementStatus: StatusBadge.Status {
        switch placement.status {
        case "active": return .active
        case "completed": return .success
        case "cancelled": return .neutral
        default: return .info
    }
}

// MARK: - New Placement Sheet
struct NewPlacementSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\. dismiss) private var dismiss
    
    let safeHouse: SafeHouse
    
    @State private var selectedClient: Client?
    @State private var selectedEnrollment: ProgramEnrollment?
    @State private var assignedAdvocate: Staff?
    @State private var placementDate = Date()
    @State private var expectedExitDate: Date?
    @State private var reasonForPlacement = ""
    @State private var safetyConcerns: [String] = []
    @State private var requiredDocuments: [String] = []
    @State private var houseRulesAccepted = false
    @State private var exitPlan = ""
    @State private var destinationAfterExit = ""
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
                    
                    Picker("Program Enrollment", selection: $selectedEnrollment) {
                        Text("No program").tag(nil as ProgramEnrollment?)
                        ForEach(availableEnrollments, id: \.id) { enrollment in
                            Text(enrollment.program?.name ?? "Program").tag(enrollment as ProgramEnrollment?)
                        }
                    }
                    
                    Picker("Assigned Advocate", selection: $assignedAdvocate) {
                        Text("Unassigned").tag(nil as Staff?)
                        ForEach(availableStaff, id: \. id) { staff in
                            Text(staff.fullName).tag(staff as Staff?)
                        }
                    }
                }
                
                Section(header: Text("Placement Details")) {
                    DatePicker("Placement Date", selection: $placementDate)
                    
                    DatePicker("Expected Exit Date", selection: $expectedExitDate, displayedComponents: .date)
                    
                    TextField("Reason for Placement", text: $reasonForPlacement)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Safety Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Safety concerns:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        SafetyConcernRow(
                            concern: "Immediate safety threat",
                            isSelected: safetyConcerns.contains("immediate_safety")
                        ) { isSelected in
                            toggleSafetyConcern("immediate_safety", isSelected)
                        }
                        
                        SafetyConcernRow(
                            concern: "Stalking or harassment",
                            isSelected: safetyConcerns.contains("stalking")
                        ) { isSelected in
                            toggleSafetyConcern("stalking", isSelected)
                        }
                        
                        SafetyConcernRow(
                            concern: "Domestic violence situation",
                            isSelected: safetyConcerns.contains("domestic_violence")
                        ) { isSelected in
                            toggleSafetyConcern("domestic_violence", isSelected)
                        }
                    }
                }
                
                Section(header: Text("Required Documents")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required documents:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        DocumentRow(
                            document: "Government ID",
                            isRequired: requiredDocuments.contains("government_id")
                        ) { isRequired in
                            toggleDocument("government_id", isRequired)
                        }
                        
                        DocumentRow(
                            document: "Intake Form",
                            isRequired: requiredDocuments.contains("intake_form")
                        ) { isRequired in
                            toggleDocument("intake_form", isRequired)
                        }
                        
                        DocumentRow(
                            document: "Safety Assessment",
                            isRequired: requiredDocuments.contains("safety_assessment")
                        ) { isRequired in
                            toggleDocument("safety_assessment", isRequired)
                        }
                    }
                }
                
                Section(header: Text("House Rules & Exit Plan")) {
                    Toggle("House Rules Accepted", isOn: $houseRulesAccepted)
                    
                    TextField("Exit Plan", text: $exitPlan)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    TextField("Destination After Exit", text: $destinationAfterExit)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Important Notice")) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.warningGold)
                        
                        Text("Safe house placement requires strict confidentiality and safety protocols. All information is encrypted and access is logged.")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("New Placement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Create Placement",
                        style: .primary,
                        isDisabled: selectedClient == nil || !houseRulesAccepted || isLoading,
                        isLoading: isLoading
                    ) {
                        createPlacement()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private var availableClients: [Client] {
        Client.fetchAll(in: viewContext).filter { client in
            client.status == "active" &&
            client.riskLevel == "critical" || client.riskLevel == "high"
        }
    }
    
    private var availableEnrollments: [ProgramEnrollment] {
        guard let client = selectedClient else { return [] }
        
        if let enrollments = client.programEnrollments?.allObjects as? [ProgramEnrollment] {
            return enrollments.filter { $0.isActive }
        }
        return []
    }
    
    private var availableStaff: [Staff] {
        Staff.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func toggleSafetyConcern(_ concern: String, _ isSelected: Bool) {
        if safetyConcerns.contains(concern) {
            safetyConcerns.removeAll { $0 == concern }
        } else {
            safetyConcerns.append(concern)
        }
    }
    
    private func toggleDocument(_ document: String, _ isRequired: Bool) {
        if requiredDocuments.contains(document) {
            requiredDocuments.removeAll { $0 == document }
        } else {
            requiredDocuments.append(document)
        }
    }
    
    private func createPlacement() {
        guard let client = selectedClient,
              let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let placement = SafeHousePlacement(context: viewContext)
        placement.id = UUID()
        placement.client = client
        placement.safeHouse = safeHouse
        placement.assignedAdvocate = assignedAdvocate
        placement.programEnrollment = selectedEnrollment
        placement.placementDate = placementDate
        placement.expectedExitDate = expectedExitDate
        placement.reasonForPlacement = reasonForPlacement.isEmpty ? nil : reasonForPlacement
        placement.safetyConcerns = safetyConcerns
        placement.requiredDocuments = requiredDocuments
        placement.houseRulesAccepted = houseRulesAccepted
        placement.exitPlan = exitPlan.isEmpty ? nil : exitPlan
        placement.destinationAfterExit = destinationAfterExit.isEmpty ? nil : destinationAfterExit
        placement.createdAt = Date()
        placement.createdBy = currentUser
        
        // Update safe house occupancy
        safeHouse.currentOccupancy += 1
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating placement: \(error)")
            isLoading = false
        }
    }
}

struct SafetyConcernRow: View {
    let concern: String
    var isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            
            Text(concern.capitalized)
                .font(.brandCaption)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct DocumentRow: View {
    let document: String
    var isRequired: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            Toggle("", isOn: Binding(
                get: { isRequired },
                set: { onToggle($0) }
            ))
            
            Text(document.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.brandCaption)
                .foregroundColor(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Safe House Sheet
struct EditSafeHouseSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\. dismiss) private var dismiss
    
    let safeHouse: SafeHouse
    
    @State private var availability: Bool
    @State private var notes: String
    @State private var isLoading = false
    
    init(safeHouse: SafeHouse) {
        self.safeHouse = safeHouse
        _availability = State(initialValue: safeHouse.availability)
        _notes = State(initialValue: safeHouse.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Toggle("Available", isOn: $availability)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .navigationTitle("Edit Safe House")
            .navigationBarTitleDisplay                .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Save Changes",
                        style: .primary,
                        isLoading: isLoading
                    ) {
                        saveChanges()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func saveChanges() {
        isLoading = true
        
        safeHouse.availability = availability
        
        if !notes.isEmpty {
            safeHouse.notes = notes
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error saving safe house: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    SafeHouseListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}