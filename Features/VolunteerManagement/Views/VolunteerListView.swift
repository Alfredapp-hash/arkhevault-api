import SwiftUI

// MARK: - Volunteer List View
struct VolunteerListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = VolunteerListViewModel()
    
    @State private var selectedFilter: VolunteerFilter = .all
    @State private var searchText = ""
    @State private var showingNewVolunteerSheet = false
    @State private var selectedVolunteer: Staff?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volunteer Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Manage volunteers, track hours, and coordinate assignments")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ForgeButton(title: "New Volunteer", style: .primary) {
                        showingNewVolunteerSheet = true
                    }
                }
                
                // Volunteer Metrics
                HStack(spacing: 16) {
                    VolunteerMetricCard(
                        title: "Active Volunteers",
                        value: "\(viewModel.activeVolunteers)",
                        subtitle: "Currently active",
                        icon: "person.3.fill",
                        color: .forgeTeal
                    )
                    
                    VolunteerMetricCard(
                        title: "Hours This Month",
                        value: "\(viewModel.hoursThisMonth)",
                        subtitle: "Volunteer hours",
                        icon: "clock.fill",
                        color: .bronze
                    )
                    
                    VolunteerMetricCard(
                        title: "Active Assignments",
                        value: "\(viewModel.activeAssignments)",
                        subtitle: "Current tasks",
                        icon: "list.bullet.rectangle",
                        color: .successGreen
                    )
                    
                    VolunteerMetricCard(
                        title: "New This Month",
                        value: "\(viewModel.newThisMonth)",
                        subtitle: "New volunteers",
                        icon: "person.badge.plus",
                        color: .infoBlue
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(VolunteerFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.textSecondary)
                    
                    TextField("Search volunteers...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.lightCharcoal)
                .cornerRadius(8)
                
                Spacer()
                
                Text("\(viewModel.filteredVolunteers.count) volunteers")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
            
            // Volunteer List
            if viewModel.filteredVolunteers.isEmpty {
                ForgeCard {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No volunteers found")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Add volunteers to get started")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredVolunteers, id: \.id) { volunteer in
                            VolunteerCard(volunteer: volunteer) {
                                selectedVolunteer = volunteer
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewVolunteerSheet) {
            NewVolunteerSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedVolunteer) { volunteer in
            VolunteerDetailView(volunteer: volunteer)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.filter = newValue
        }
        .onChange(of: searchText) { newValue in
            viewModel.searchText = newValue
        }
    }
}

// MARK: - Volunteer Metric Card
struct VolunteerMetricCard: View {
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

// MARK: - Volunteer Card
struct VolunteerCard: View {
    let volunteer: Staff
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ForgeCard {
                HStack(spacing: 16) {
                    // Avatar
                    Circle()
                        .fill(Color.forgeTeal.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(volunteer.fullName.prefix(2).uppercased())
                                .font(.brandBodyBold)
                                .foregroundColor(.forgeTeal)
                        )
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(volunteer.fullName)
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        if let email = volunteer.email {
                            Text(email)
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        if let phone = volunteer.phone {
                            Text(phone)
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                        
                        HStack(spacing: 8) {
                            StatusBadge(
                                text: volunteer.status?.capitalized ?? "Unknown",
                                status: volunteer.status == "active" ? .active : .neutral
                            )
                            
                            if let role = volunteer.role {
                                Text(role.capitalized)
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Hours and Assignments
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(volunteerHours(volunteer)) hrs")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text("This Month")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                        
                        Text("\(volunteerAssignments(volunteer)) tasks")
                            .font(.brandCaption)
                            .foregroundColor(.forgeTeal)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func volunteerHours(_ volunteer: Staff) -> Int {
        // In production, this would query actual hour logs
        return Int.random(in: 10...50)
    }
    
    private func volunteerAssignments(_ volunteer: Staff) -> Int {
        // In production, this would query actual assignments
        return Int.random(in: 1...10)
    }
}

// MARK: - Volunteer List ViewModel
class VolunteerListViewModel: ObservableObject {
    @Published var activeVolunteers = 0
    @Published var hoursThisMonth = 0
    @Published var activeAssignments = 0
    @Published var newThisMonth = 0
    @Published var volunteers: [Staff] = []
    @Published var filteredVolunteers: [Staff] = []
    @Published var filter: VolunteerFilter = .all
    @Published var searchText = ""
    
    func loadData(context: NSManagedObjectContext) {
        let allStaff = Staff.fetchAll(in: context)
        volunteers = allStaff.filter { $0.role == "volunteer" || $0.role == "volunteer_coordinator" }
        applyFilters()
        
        // Calculate metrics
        activeVolunteers = volunteers.filter { $0.status == "active" }.count
        hoursThisMonth = Int.random(in: 150...500)
        activeAssignments = Int.random(in: 20...50)
        newThisMonth = Int.random(in: 1...5)
    }
    
    func applyFilters() {
        filteredVolunteers = volunteers.filter { volunteer in
            // Apply status filter
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .active:
                matchesFilter = volunteer.status == "active"
            case .inactive:
                matchesFilter = volunteer.status == "inactive"
            case .coordinators:
                matchesFilter = volunteer.role == "volunteer_coordinator"
            }
            
            // Apply search filter
            let matchesSearch = searchText.isEmpty ||
                volunteer.fullName.localizedCaseInsensitiveContains(searchText) ||
                (volunteer.email?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            return matchesFilter && matchesSearch
        }
    }
}

enum VolunteerFilter: String, CaseIterable {
    case all = "All Volunteers"
    case active = "Active"
    case inactive = "Inactive"
    case coordinators = "Coordinators"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - New Volunteer Sheet
struct NewVolunteerSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var role: VolunteerRole = .volunteer
    @State private var status = "active"
    @State private var availability = VolunteerAvailability.fullTime
    @State private var skills: Set<String> = []
    @State private var interests: Set<String> = []
    @State private var notes = ""
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
                
                Section(header: Text("Volunteer Details")) {
                    Picker("Role", selection: $role) {
                        ForEach(VolunteerRole.allCases, id: \.self) { role in
                            Text(role.displayName).tag(role)
                        }
                    }
                    
                    Picker("Status", selection: $status) {
                        Text("Active").tag("active")
                        Text("Inactive").tag("inactive")
                    }
                    
                    Picker("Availability", selection: $availability) {
                        ForEach(VolunteerAvailability.allCases, id: \.self) { availability in
                            Text(availability.displayName).tag(availability)
                        }
                    }
                }
                
                Section(header: Text("Skills")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select volunteer skills:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(VolunteerSkill.allCases, id: \.self) { skill in
                                SkillChip(
                                    skill: skill,
                                    isSelected: skills.contains(skill.rawValue)
                                ) { isSelected in
                                    if isSelected {
                                        skills.insert(skill.rawValue)
                                    } else {
                                        skills.remove(skill.rawValue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text="Interests") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Areas of interest:")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ], spacing: 8) {
                            ForEach(VolunteerInterest.allCases, id: \.self) { interest in
                                InterestChip(
                                    interest: interest,
                                    isSelected: interests.contains(interest.rawValue)
                                ) { isSelected in
                                    if isSelected {
                                        interests.insert(interest.rawValue)
                                    } else {
                                        interests.remove(interest.rawValue)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .navigationTitle("New Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Create Volunteer",
                        style: .primary,
                        isDisabled: firstName.isEmpty || lastName.isEmpty || email.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createVolunteer()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }
    
    private func createVolunteer() {
        isLoading = true
        
        let volunteer = Staff.create(
            in: viewContext,
            email: email,
            firstName: firstName,
            lastName: lastName,
            role: role.rawValue
        )
        
        volunteer.phone = phone.isEmpty ? nil : phone
        volunteer.status = status
        
        // Store skills and interests in permissions (in production, would use separate entities)
        if !skills.isEmpty {
            volunteer.permissions = Array(skills)
        }
        
        if !notes.isEmpty {
            volunteer.setValue(notes, forKey: "notes")
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating volunteer: \(error)")
            isLoading = false
        }
    }
}

enum VolunteerRole: String, CaseIterable {
    case volunteer = "Volunteer"
    case volunteerCoordinator = "Volunteer Coordinator"
    
    var displayName: String {
        rawValue
    }
}

enum VolunteerAvailability: String, CaseIterable {
    case fullTime = "Full Time"
    case partTime = "Part Time"
    case weekends = "Weekends Only"
    case flexible = "Flexible"
    
    var displayName: String {
        rawValue
    }
}

struct SkillChip: View {
    let skill: VolunteerSkill
    var isSelected: Bool
    let onTap: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onTap(!isSelected)
        }) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.forgeTeal)
                        .font(.brandTiny)
                }
                
                Text(skill.displayName)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.forgeTeal.opacity(0.2) : Color.lightCharcoal)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.forgeTeal : Color.lightCharcoal, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InterestChip: View {
    let interest: VolunteerInterest
    var isSelected: Bool
    let onTap: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onTap(!isSelected)
        }) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.bronze)
                        .font(.brandTiny)
                }
                
                Text(interest.displayName)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.bronze.opacity(0.2) : Color.lightCharcoal)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.bronze : Color.lightCharcoal, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum VolunteerSkill: String, CaseIterable {
    case clientSupport = "Client Support"
    case administrative = "Administrative"
    case eventSupport = "Event Support"
    case fundraising = "Fundraising"
    case transportation = "Transportation"
    case translation = "Translation"
    case counseling = "Counseling"
    case mentorship = "Mentorship"
    
    var displayName: String {
        rawValue
    }
}

enum VolunteerInterest: String, CaseIterable {
    case victimAdvocacy = "Victim Advocacy"
    case housingSupport = "Housing Support"
    case legalAssistance = "Legal Assistance"
    case counselingServices = "Counseling Services"
    case employmentHelp = "Employment Help"
    case educationPrograms = "Education Programs"
    case childCare = "Child Care"
    case foodAssistance = "Food Assistance"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Volunteer Detail View
struct VolunteerDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let volunteer: Staff
    
    @State private var showingEditSheet = false
    @State private var showingHoursSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(volunteer.fullName)
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let role = volunteer.role {
                        Text(role.capitalized)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                ForgeButton(title: "Edit Profile", style: .secondary) {
                    showingEditSheet = true
                }
                
                ForgeButton(title: "Log Hours", style: .primary) {
                    showingHoursSheet = true
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Volunteer Information")
                    
                    ForgeCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "envelope.fill", title: "Email", value: volunteer.email)
                            
                            if let phone = volunteer.phone {
                                InfoRow(icon: "phone.fill", title: "Phone", value: phone)
                            }
                            
                            InfoRow(icon: "info.circle", title: "Status", value: volunteer.status?.capitalized ?? "Unknown")
                            
                            if let role = volunteer.role {
                                InfoRow(icon: "briefcase.fill", title: "Role", value: role.capitalized)
                            }
                            
                            if let lastLogin = volunteer.lastLogin {
                                InfoRow(icon: "calendar", title: "Last Login", value: lastLogin.formatted(date: .long, time: .shortened))
                            }
                        }
                    }
                    
                    // Hours Tracking
                    SectionHeader(title: "Hours Tracking")
                    
                    HStack(spacing: 16) {
                        ForgeCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("This Month")
                                    .font(.brandBodyBold)
                                    .foregroundColor(.textPrimary)
                                
                                Text("\(volunteerHours(volunteer)) hours")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.forgeTeal)
                                
                                Text("Volunteer hours this month")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        ForgeCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Total Hours")
                                    .font(.brandBodyBold)
                                    .foregroundColor(.textPrimary)
                                
                                Text("\(totalHours(volunteer)) hours")
                                    .font(.system(size: 32, weight: .bold, design: .default))
                                    .foregroundColor(.bronze)
                                
                                Text("Lifetime volunteer hours")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    // Assignments
                    SectionHeader(title: "Current Assignments")
                    
                    ForgeCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(volunteerAssignments(volunteer)) active assignments")
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                            
                            Text("View assignment details")
                                .font(.brandCaption)
                                .foregroundColor(.forgeTeal)
                        }
                    }
                    
                    // Skills
                    if let permissions = volunteer.permissions {
                        SectionHeader(title: "Skills")
                        
                        ForgeCard {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(permissions, id: \.self) { skill in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.forgeTeal)
                                            .font(.brandTiny)
                                        
                                        Text(skill.capitalized)
                                            .font(.brandCaption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Actions
                    SectionHeader(title: "Actions")
                    
                    HStack(spacing: 12) {
                        ForgeButton(title: "Log Hours", style: .primary) {
                            showingHoursSheet = true
                        }
                        
                        ForgeButton(title: "View Assignments", style: .secondary) {
                            // View assignments
                        }
                        
                        ForgeButton(title: "Send Message", style: .outline) {
                            // Send message
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingEditSheet) {
            EditVolunteerSheet(volunteer: volunteer)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingHoursSheet) {
            LogHoursSheet(volunteer: volunteer)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private func totalHours(_ volunteer: Staff) -> Int {
        // In production, would query actual hour logs
        return volunteerHours(volunteer) * 6 // Approximate total
    }
    
    private func volunteerHours(_ volunteer: Staff) -> Int {
        Int.random(in: 10...50)
    }
    
    private func volunteerAssignments(_ volunteer: Staff) -> Int {
        Int.random(in: 1...10)
    }
}

// MARK: - Log Hours Sheet
struct LogHoursSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let volunteer: Staff
    
    @State private var hours: String = ""
    @State private var activity = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Hours Entry")) {
                    TextField("Hours", text: $hours)
                        .keyboardType(.numberPad)
                    
                    TextField("Activity", text: $activity)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    DatePicker("Date", selection: $date)
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .navigationTitle("Log Volunteer Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Log Hours",
                        style: .primary,
                        isDisabled: hours.isEmpty || activity.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        logHours()
                    }
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func logHours() {
        isLoading = true
        
        // In production, this would create a VolunteerHours entity
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Edit Volunteer Sheet
struct EditVolunteerSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let volunteer: Staff
    
    @State private var status: String
    @State private var notes: String
    @State private var isLoading = false
    
    init(volunteer: Staff) {
        self.volunteer = volunteer
        _status = State(initialValue: volunteer.status ?? "active")
        _notes = State(initialValue: volunteer.value(forKey: "notes") as? String ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Status")) {
                    Picker("Status", selection: $status) {
                        Text("Active").tag("active")
                        Text("Inactive").tag("inactive")
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
            }
            .navigationTitle("Edit Volunteer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
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
        
        volunteer.status = status
        
        if !notes.isEmpty {
            volunteer.setValue(notes, forKey: "notes")
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error saving volunteer: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    VolunteerListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}