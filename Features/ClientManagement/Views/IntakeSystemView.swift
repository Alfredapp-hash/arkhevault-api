import SwiftUI

// MARK: - Intake System View
struct IntakeSystemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = IntakeSystemViewModel()
    
    @State private var selectedFormType: IntakeFormType = .basicClient
    @State private var showingNewFormSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intake System")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Digital intake forms with smart program routing")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "New Intake Form", style: .primary) {
                        showingNewFormSheet = true
                    }
                }
                
                // Intake Metrics
                HStack(spacing: 16) {
                    IntakeMetricCard(
                        title: "Forms Today",
                        value: "\(viewModel.formsToday)",
                        subtitle: "Completed intakes",
                        icon: "doc.text.fill",
                        color: .forgeTeal
                    )
                    
                    IntakeMetricCard(
                        title: "Pending Review",
                        value: "\(viewModel.pendingReview)",
                        subtitle: "Awaiting approval",
                        icon: "clock.fill",
                        color: .warningGold
                    )
                    
                    IntakeMetricCard(
                        title: "Auto-Routed",
                        value: "\(viewModel.autoRouted)",
                        subtitle: "Program suggestions",
                        icon: "arrow.right.arrow.left",
                        color: .successGreen
                    )
                    
                    IntakeMetricCard(
                        title: "Conversion Rate",
                        value: "\(viewModel.conversionRate)%",
                        subtitle: "Intake to enrollment",
                        icon: "chart.bar.fill",
                        color: .bronze
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Form Type Tabs
            Picker("Form Type", selection: $selectedFormType) {
                ForEach(IntakeFormType.allCases, id: \.self) { formType in
                    Text(formType.displayName).tag(formType)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Form List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.availableForms(for: selectedFormType), id: \.id) { form in
                        IntakeFormCard(form: form)
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewFormSheet) {
            NewIntakeFormSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
        .onChange(of: selectedFormType) { newValue in
            viewModel.filterForms(by: newValue)
        }
    }
}

// MARK: - Intake Metric Card
struct IntakeMetricCard: View {
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

// MARK: - Intake Form Card
struct IntakeFormCard: View {
    let form: IntakeForm
    
    var body: some View {
        ArkheCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(form.name)
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(form.type.displayName)
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    StatusBadge(
                        text: form.status.displayName,
                        status: form.status == .active ? .success : .neutral
                    )
                }
                
                // Description
                if let description = form.description {
                    Text(description)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fields: \(form.fieldCount)")
                            .font(.brandTiny)
                            .foregroundColor(.textMuted)
                        
                        Text("Avg. Time: \(form.estimatedTime)")
                            .font(.brandTiny)
                            .foregroundColor(.textMuted)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        if form.requiresReview {
                            HStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.warningGold)
                                    .font(.brandTiny)
                                
                                Text("Requires Review")
                                    .font(.brandTiny)
                                    .foregroundColor(.warningGold)
                            }
                        }
                        
                        if form.hasAutoRouting {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.arrow.left")
                                    .foregroundColor(.successGreen)
                                    .font(.brandTiny)
                                
                                Text("Auto-Routing")
                                    .font(.brandTiny)
                                    .foregroundColor(.successGreen)
                            }
                        }
                    }
                }
                
                // Quick Actions
                HStack(spacing: 8) {
                    ArkheButton(title: "Start Intake", style: .primary) {
                        // Start intake action
                    }
                    
                    ArkheIconButton(systemImage: "eye", style: .outline) {
                        // Preview form
                    }
                    
                    ArkheIconButton(systemImage: "pencil", style: .secondary) {
                        // Edit form
                    }
                }
            }
        }
    }
}

// MARK: - Intake System ViewModel
class IntakeSystemViewModel: ObservableObject {
    @Published var formsToday = 0
    @Published var pendingReview = 0
    @Published var autoRouted = 0
    @Published var conversionRate = 0
    @Published var availableForms: [IntakeForm] = []
    
    func loadData(context: NSManagedObjectContext) {
        // Load intake forms (in production, this would query Core Data)
        generateSampleForms()
        filterForms(by: .basicClient)
        
        // Calculate metrics (sample data for now)
        formsToday = Int.random(in: 5...15)
        pendingReview = Int.random(in: 1...5)
        autoRouted = Int.random(in: 10...25)
        conversionRate = Int.random(in: 65...85)
    }
    
    func filterForms(by formType: IntakeFormType) {
        availableForms = availableForms.filter { $0.type == formType }
    }
    
    private func generateSampleForms() {
        availableForms = [
            IntakeForm(
                id: UUID(),
                name: "Basic Client Intake",
                type: .basicClient,
                description: "Standard client intake form for initial assessment",
                fieldCount: 15,
                estimatedTime: "15-20 min",
                status: .active,
                requiresReview: false,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Emergency Assistance Intake",
                type: .emergencyAssistance,
                description: "Rapid intake for emergency situations",
                fieldCount: 8,
                estimatedTime: "5-10 min",
                status: .active,
                requiresReview: true,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Victim Advocacy Intake",
                type: .victimAdvocacy,
                description: "Comprehensive intake for victim advocacy services",
                fieldCount: 25,
                estimatedTime: "30-45 min",
                status: .active,
                requiresReview: true,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Housing Intake",
                type: .housing,
                description: "Housing needs assessment and placement",
                fieldCount: 20,
                estimatedTime: "20-30 min",
                status: .active,
                requiresReview: false,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Veteran Support Intake",
                type: .veteranSupport,
                description: "Veteran-specific services and benefits assessment",
                fieldCount: 18,
                estimatedTime: "25-35 min",
                status: .active,
                requiresReview: false,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Recovery Support Intake",
                type: .recoverySupport,
                description: "Recovery program assessment and placement",
                fieldCount: 22,
                estimatedTime: "30-40 min",
                status: .active,
                requiresReview: true,
                hasAutoRouting: true
            ),
            IntakeForm(
                id: UUID(),
                name: "Safe House Screening",
                type: .safeHouseScreening,
                description: "Confidential safe house eligibility screening",
                fieldCount: 30,
                estimatedTime: "45-60 min",
                status: .active,
                requiresReview: true,
                hasAutoRouting: false
            )
        ]
    }
}

// MARK: - Intake Form Data Model
struct IntakeForm: Identifiable {
    let id: UUID
    let name: String
    let type: IntakeFormType
    let description: String
    let fieldCount: Int
    let estimatedTime: String
    let status: FormStatus
    let requiresReview: Bool
    let hasAutoRouting: Bool
}

enum IntakeFormType: String, CaseIterable {
    case basicClient = "Basic Client"
    case emergencyAssistance = "Emergency Assistance"
    case victimAdvocacy = "Victim Advocacy"
    case housing = "Housing"
    case veteranSupport = "Veteran Support"
    case recoverySupport = "Recovery Support"
    case courtAdvocacy = "Court Advocacy"
    case employmentReadiness = "Employment Readiness"
    case familySupport = "Family Support"
    case safeHouseScreening = "Safe House Screening"
    case donationAssistance = "Donation Assistance"
    case volunteer = "Volunteer"
    case partnerReferral = "Partner Referral"
    
    var displayName: String {
        rawValue
    }
}

enum FormStatus {
    case active, inactive, draft
}

extension FormStatus {
    var displayName: String {
        switch self {
        case .active: return "Active"
        case .inactive: return "Inactive"
        case .draft: return "Draft"
        }
    }
}

// MARK: - New Intake Form Sheet
struct NewIntakeFormSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var formName = ""
    @State private var selectedType: IntakeFormType = .basicClient
    @State private var description = ""
    @State private var requiresReview = true
    @State private var enableAutoRouting = true
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Form Details")) {
                    TextField("Form Name", text: $formName)
                    
                    Picker("Form Type", selection: $selectedType) {
                        ForEach(IntakeFormType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    TextField("Description", text: $description)
                }
                
                Section(header: Text("Settings")) {
                    Toggle("Requires Supervisor Review", isOn: $requiresReview)
                    
                    Toggle("Enable Smart Program Routing", isOn: $enableAutoRouting)
                }
                
                Section(header: Text("Form Builder")) {
                    Text("Form builder will be available in the next phase")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                    
                    NavigationLink("Open Form Builder") {
                        Text("Coming Soon")
                            .font(.brandBody)
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .navigationTitle("New Intake Form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Create Form",
                        style: .primary,
                        isDisabled: formName.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createForm()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func createForm() {
        isLoading = true
        
        // In production, this would save to Core Data
        // For now, we'll simulate the creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Dynamic Intake Form View (for actual intake completion)
struct DynamicIntakeFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let intakeForm: IntakeForm
    
    @State private var formResponses: [String: String] = [:]
    @State private var currentPage = 0
    @State private var isSubmitting = false
    @State private var suggestedPrograms: [Program] = []
    @State private var showingResults = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(intakeForm.name)
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                ProgressView(value: Double(currentPage + 1) / Double(totalPages))
                    .tint(.forgeTeal)
                    .frame(width: 200)
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Form Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Personal Information")
                    
                    ArkheCard {
                        VStack(spacing: 16) {
                            FormField(label: "First Name", placeholder: "Enter first name", text: $formResponses["firstName"])
                            FormField(label: "Last Name", placeholder: "Enter last name", text: $formResponses["lastName"])
                            FormField(label: "Date of Birth", placeholder: "Enter date of birth", text: $formResponses["dateOfBirth"])
                            FormField(label: "Phone Number", placeholder: "Enter phone number", text: $formResponses["phoneNumber"])
                            FormField(label: "Email Address", placeholder: "Enter email address", text: $formResponses["email"])
                        }
                    }
                    
                    SectionHeader(title: "Situation Assessment")
                    
                    ArkheCard {
                        VStack(spacing: 16) {
                            FormField(label: "Current Housing Status", placeholder: "Select housing status", text: $formResponses["housingStatus"])
                            FormField(label: "Employment Status", placeholder: "Select employment status", text: $formResponses["employmentStatus"])
                            FormField(label: "Transportation Access", placeholder: "Select transportation status", text: $formResponses["transportation"])
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Immediate Safety Concerns")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                TextField("Describe any immediate safety concerns", text: $formResponses["safetyConcerns"])
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                        }
                    }
                    
                    SectionHeader(title: "Needs Assessment")
                    
                    ArkheCard {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Services Needed")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                TextField("Check all that apply", text: $formResponses["servicesNeeded"])
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How did you hear about us?")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                TextField("Referral source", text: $formResponses["referralSource"])
                                    .textFieldStyle(PlainTextFieldStyle())
                            }
                        }
                    }
                    
                    // Navigation
                    HStack(spacing: 12) {
                        ArkheButton(title: "Previous", style: .outline, isDisabled: currentPage == 0) {
                            if currentPage > 0 {
                                currentPage -= 1
                            }
                        }
                        
                        Spacer()
                        
                        ArkheButton(
                            title: currentPage < totalPages - 1 ? "Next" : "Submit Intake",
                            style: .primary,
                            isLoading: isSubmitting
                        ) {
                            if currentPage < totalPages - 1 {
                                currentPage += 1
                            } else {
                                submitIntake()
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingResults) {
            IntakeResultsView(
                formResponses: formResponses,
                suggestedPrograms: suggestedPrograms,
                onEnroll: { program in
                    // Enroll in program
                    dismiss()
                }
            )
        }
    }
    
    private var totalPages: Int {
        3 // Would be calculated based on form configuration
    }
    
    private func submitIntake() {
        isSubmitting = true
        
        // Simulate smart routing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            generateProgramSuggestions()
            isSubmitting = false
            showingResults = true
        }
    }
    
    private func generateProgramSuggestions() {
        // In production, this would use AI service to analyze responses
        // For now, we'll simulate based on form type
        let allPrograms = Program.fetchAll(in: viewContext)
        suggestedPrograms = Array(allPrograms.prefix(3))
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.brandCaption)
                .foregroundColor(.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(ArkheTextFieldStyle())
        }
    }
}

// MARK: - Intake Results View
struct IntakeResultsView: View {
    @Environment(\.dismiss) private var dismiss
    
    let formResponses: [String: String]
    let suggestedPrograms: [Program]
    let onEnroll: (Program) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Success Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.successGreen)
                    
                    Text("Intake Submitted Successfully")
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text("Client information has been processed")
                        .font(.brandBody)
                        .foregroundColor(.textSecondary)
                }
                
                // Program Suggestions
                if !suggestedPrograms.isEmpty {
                    SectionHeader(title: "Recommended Programs")
                    
                    VStack(spacing: 12) {
                        ForEach(suggestedPrograms, id: \.id) { program in
                            ProgramSuggestionCard(program: program) {
                                onEnroll(program)
                            }
                        }
                    }
                }
                
                // Summary
                SectionHeader(title: "Intake Summary")
                
                ArkheCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Client Information Collected")
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        ForEach(Array(formResponses.prefix(5)), id: \.key) { response in
                            if !response.value.isEmpty {
                                HStack {
                                    Text(response.key.capitalized)
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Spacer()
                                    
                                    Text(response.value)
                                        .font(.brandCaption)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                ArkheButton(title: "Complete", style: .primary) {
                    dismiss()
                }
            }
            .padding()
            .navigationTitle("Intake Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
    }
}

// MARK: - Program Suggestion Card
struct ProgramSuggestionCard: View {
    let program: Program
    let onEnroll: () -> Void
    
    var body: some View {
        ArkheCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text(program.programType?.capitalized ?? "Program")
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                    
                    Text("Based on your intake responses")
                        .font(.brandTiny)
                        .foregroundColor(.forgeTeal)
                }
                
                Spacer()
                
                ArkheButton(title: "Enroll", style: .primary) {
                    onEnroll()
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    IntakeSystemView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}