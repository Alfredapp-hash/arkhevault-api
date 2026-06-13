import SwiftUI

// MARK: - Program Management View
struct ProgramListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ProgramManagementViewModel()
    
    @State private var showingNewProgramSheet = false
    @State private var selectedProgram: Program?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Program Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Administer programs, track enrollments, and manage capacity")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "New Program", style: .primary) {
                        showingNewProgramSheet = true
                    }
                }
                
                // Program Metrics
                HStack(spacing: 16) {
                    ProgramMetricCard(
                        title: "Active Programs",
                        value: "\(viewModel.activePrograms)",
                        subtitle: "Currently operational",
                        icon: "star.fill",
                        color: .forgeTeal
                    )
                    
                    ProgramMetricCard(
                        title: "Total Enrollments",
                        value: "\(viewModel.totalEnrollments)",
                        subtitle: "Across all programs",
                        icon: "person.2.fill",
                        color: .bronze
                    )
                    
                    ProgramMetricCard(
                        title: "Capacity Utilization",
                        value: "\(viewModel.capacityUtilization)%",
                        subtitle: "Programs at capacity",
                        icon: "chart.pie.fill",
                        color: viewModel.capacityUtilization > 80 ? .dangerRed : .successGreen
                    )
                    
                    ProgramMetricCard(
                        title: "Programs Full",
                        value: "\(viewModel.programsAtCapacity)",
                        subtitle: "Waitlist only",
                        icon: "exclamationmark.triangle.fill",
                        color: .warningGold
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Program List
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(viewModel.programs, id: \.id) { program in
                        ProgramManagementCard(program: program) {
                            selectedProgram = program
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewProgramSheet) {
            NewProgramSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedProgram) { program in
            ProgramDetailView(program: program)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
    }
}

// MARK: - Program Metric Card
struct ProgramMetricCard: View {
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

// MARK: - Program Management Card
struct ProgramManagementCard: View {
    let program: Program
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(program.name)
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            Text(program.programType?.capitalized ?? "Program")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        StatusBadge(
                            text: program.status?.capitalized ?? "Unknown",
                            status: program.status == "active" ? .active : .neutral
                        )
                    }
                    
                    // Description
                    if let description = program.descriptionText {
                        Text(description)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                            .lineLimit(2)
                    }
                    
                    // Capacity
                    VStack(spacing: 8) {
                        HStack {
                            Text("Capacity")
                                .font(.brandTiny)
                                .foregroundColor(.textMuted)
                            
                            Spacer()
                            
                            Text("\(program.currentEnrollment)/\(program.capacity)")
                                .font(.brandCaption)
                                .foregroundColor(.textPrimary)
                        }
                        
                        ProgressView(value: Double(program.currentEnrollment) / Double(program.capacity))
                            .tint(program.isFull ? .dangerRed : .forgeTeal)
                        
                        if program.isFull {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.dangerRed)
                                    .font(.brandTiny)
                                
                                Text("Program at capacity - waitlist only")
                                    .font(.brandTiny)
                                    .foregroundColor(.dangerRed)
                            }
                        }
                    }
                    
                    // Quick Actions
                    HStack(spacing: 8) {
                        ArkheButton(title: "Manage", style: .primary) {
                            onTap()
                        }
                        
                        ArkheIconButton(systemImage: "person.badge.plus", style: .secondary) {
                            // Quick enrollment
                        }
                        
                        ArkheIconButton(systemImage: "chart.bar", style: .outline) {
                            // View reports
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Program Management ViewModel
class ProgramManagementViewModel: ObservableObject {
    @Published var activePrograms = 0
    @Published var totalEnrollments = 0
    @Published var capacityUtilization = 0
    @Published var programsAtCapacity = 0
    @Published var programs: [Program] = []
    
    func loadData(context: NSManagedObjectContext) {
        let allPrograms = Program.fetchAll(in: context)
        programs = allPrograms.filter { $0.status == "active" }
        
        activePrograms = programs.count
        totalEnrollments = programs.reduce(0) { $0 + $1.currentEnrollment }
        
        let totalCapacity = programs.reduce(0) { $0 + $1.capacity }
        capacityUtilization = totalCapacity > 0 ? Int((Double(totalEnrollments) / Double(totalCapacity)) * 100) : 0
        
        programsAtCapacity = programs.filter { $0.isFull }.count
    }
}

// MARK: - New Program Sheet
struct NewProgramSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var programName = ""
    @State private var programType: ProgramType = .victimAdvocacy
    @State private var description = ""
    @State private var capacity: Int = 50
    @State private var requiresReview = true
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Program Details")) {
                    TextField("Program Name", text: $programName)
                    
                    Picker("Program Type", selection: $programType) {
                        ForEach(ProgramType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Capacity Settings")) {
                    HStack {
                        Text("Capacity")
                        Spacer()
                        Stepper("\(capacity)", value: $capacity, in: 1...500)
                    }
                    
                    Toggle("Requires Supervisor Review for Enrollments", isOn: $requiresReview)
                }
                
                Section(header: Text("Eligibility Rules")) {
                    Text("Eligibility rules will be configured in the program settings after creation")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Section(header: Text("Grant Reporting")) {
                    Text("Grant reporting fields will be configured in the program settings")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
            }
            .navigationTitle("New Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Create Program",
                        style: .primary,
                        isDisabled: programName.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createProgram()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func createProgram() {
        isLoading = true
        
        let program = Program.create(
            in: viewContext,
            name: programName,
            programType: programType.rawValue,
            capacity: Int16(capacity)
        )
        
        program.descriptionText = description.isEmpty ? nil : description
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating program: \(error)")
            isLoading = false
        }
    }
}

enum ProgramType: String, CaseIterable {
    case victimAdvocacy = "Victim Advocacy"
    case housingAssistance = "Housing Assistance"
    case veteranSupport = "Veteran Support"
    case recoveryServices = "Recovery Services"
    case courtAdvocacy = "Court Advocacy"
    case employmentReadiness = "Employment Readiness"
    case familySupport = "Family Support"
    case legalAssistance = "Legal Assistance"
    case counselingServices = "Counseling Services"
    case financialAssistance = "Financial Assistance"
    case transportation = "Transportation Services"
    case donationAssistance = "Donation Assistance"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Program Detail View
struct ProgramDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let program: Program
    
    @State private var selectedTab: ProgramTab = .overview
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text(program.programType?.capitalized ?? "Program")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                ArkheButton(title: "Edit Program", style: .secondary) {
                    showingEditSheet = true
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Capacity Banner
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Capacity: \(program.currentEnrollment)/\(program.capacity)")
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text("\(program.availableCapacity) slots available")
                        .font(.brandCaption)
                        .foregroundColor(program.isFull ? .dangerRed : .textSecondary)
                }
                
                Spacer()
                
                ProgressView(value: Double(program.currentEnrollment) / Double(program.capacity))
                    .tint(program.isFull ? .dangerRed : .forgeTeal)
                    .frame(width: 200)
            }
            .padding()
            .background(program.isFull ? Color.dangerRed.opacity(0.1) : Color.successGreen.opacity(0.1))
            
            // Tab Content
            Picker("Program Tab", selection: $selectedTab) {
                ForEach(ProgramTab.allCases, id: \.self) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                Group {
                    switch selectedTab {
                    case .overview:
                        ProgramOverviewTab(program: program)
                    case .enrollments:
                        ProgramEnrollmentsTab(program: program)
                    case .eligibility:
                        ProgramEligibilityTab(program: program)
                    case .reporting:
                        ProgramReportingTab(program: program)
                    case .settings:
                        ProgramSettingsTab(program: program)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingEditSheet) {
            EditProgramSheet(program: program)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

enum ProgramTab: String, CaseIterable {
    case overview = "Overview"
    case enrollments = "Enrollments"
    case eligibility = "Eligibility"
    case reporting = "Reporting"
    case settings = "Settings"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Program Tab Views
struct ProgramOverviewTab: View {
    let program: Program
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Program Details")
            
            ArkheCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "star.fill", title: "Program Name", value: program.name)
                    InfoRow(icon: "list.bullet", title: "Program Type", value: program.programType?.displayName ?? "Unknown")
                    InfoRow(icon: "info.circle", title: "Status", value: program.status?.capitalized ?? "Unknown")
                    
                    if let description = program.descriptionText {
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
            
            SectionHeader(title: "Capacity Information")
            
            ArkheCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "person.2.fill", title: "Total Capacity", value: "\(program.capacity)")
                    InfoRow(icon: "person.fill", title: "Current Enrollments", value: "\(program.currentEnrollment)")
                    InfoRow(icon: "minus.circle", title: "Available Slots", value: "\(program.availableCapacity)")
                    
                    if program.isFull {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.dangerRed)
                            
                            Text("Program is at capacity - waitlist only")
                                .font(.brandCaption)
                                .foregroundColor(.dangerRed)
                        }
                    }
                }
            }
            
            SectionHeader(title: "Quick Actions")
            
            HStack(spacing: 12) {
                ArkheButton(title: "Enroll Client", style: .primary) {
                    // Enroll action
                }
                
                ArkheButton(title: "View Waitlist", style: .secondary) {
                    // Waitlist action
                }
                
                ArkheButton(title: "Generate Report", style: .outline) {
                    // Report action
                }
            }
        }
    }
}

struct ProgramEnrollmentsTab: View {
    let program: Program
    
    var body: some View {
        ArkheCard {
            Text("Program enrollments list coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ProgramEligibilityTab: View {
    let program: Program
    
    var body: some View {
        ArkheCard {
            VStack(spacing: 16) {
                SectionHeader(title: "Eligibility Rules")
                
                Text("Configure eligibility rules for this program")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    EligibilityRuleRow(
                        rule: "Age Requirement",
                        value: "18+",
                        isEnabled: true
                    )
                    
                    EligibilityRuleRow(
                        rule: "Veteran Status",
                        value: "Must be veteran",
                        isEnabled: false
                    )
                    
                    EligibilityRuleRow(
                        rule: "Housing Status",
                        value: "Unstable or homeless",
                        isEnabled: true
                    )
                    
                    EligibilityRuleRow(
                        rule: "Geographic Requirement",
                        value: "Must reside in service area",
                        isEnabled: true
                    )
                }
                
                ArkheButton(title: "Add Eligibility Rule", style: .outline) {
                    // Add rule action
                }
            }
        }
    }
}

struct EligibilityRuleRow: View {
    let rule: String
    let value: String
    var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isEnabled)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(rule)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                
                Text(value)
                    .font(.brandTiny)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            ArkheIconButton(systemImage: "pencil", style: .outline) {
                // Edit rule
            }
        }
        .padding(.vertical, 8)
    }
}

struct ProgramReportingTab: View {
    let program: Program
    
    var body: some View {
        ArkheCard {
            VStack(spacing: 16) {
                SectionHeader(title: "Grant Reporting Fields")
                
                Text("Configure fields required for grant reporting")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    ReportingFieldRow(
                        fieldName: "Service Hours Provided",
                        isRequired: true
                    )
                    
                    ReportingFieldRow(
                        fieldName: "Goals Achieved",
                        isRequired: true
                    )
                    
                    ReportingFieldRow(
                        fieldName: "Client Satisfaction Score",
                        isRequired: false
                    )
                    
                    ReportingFieldRow(
                        fieldName: "Referral Outcomes",
                        isRequired: true
                    )
                }
                
                ArkheButton(title: "Add Reporting Field", style: .outline) {
                    // Add field action
                }
            }
        }
    }
}

struct ReportingFieldRow: View {
    let fieldName: String
    var isRequired: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $isRequired)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fieldName)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                
                if isRequired {
                    Text("Required for reporting")
                        .font(.brandTiny)
                        .foregroundColor(.warningGold)
                }
            }
            
            Spacer()
            
            ArkheIconButton(systemImage: "pencil", style: .outline) {
                // Edit field
            }
        }
        .padding(.vertical, 8)
    }
}

struct ProgramSettingsTab: View {
    let program: Program
    
    var body: some View {
        ArkheCard {
            Text("Program settings coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Edit Program Sheet
struct EditProgramSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let program: Program
    
    @State private var programName: String
    @State private var description: String
    @State private var capacity: Int
    @State private var isLoading = false
    
    init(program: Program) {
        self.program = program
        _programName = State(initialValue: program.name)
        _description = State(initialValue: program.descriptionText ?? "")
        _capacity = State(initialValue: Int(program.capacity))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Program Details")) {
                    TextField("Program Name", text: $programName)
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Capacity Settings")) {
                    HStack {
                        Text("Capacity")
                        Spacer()
                        Stepper("\(capacity)", value: $capacity, in: 1...500)
                    }
                }
            }
            .navigationTitle("Edit Program")
            .navigationBarTitleDisplayMode(.inline)
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
                        isDisabled: programName.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        saveChanges()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func saveChanges() {
        isLoading = true
        
        program.name = programName
        program.descriptionText = description.isEmpty ? nil : description
        program.capacity = Int16(capacity)
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error saving program: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Preview
#Preview {
    ProgramListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}