import SwiftUI

// MARK: - Client Programs Tab
struct ClientProgramsTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var showingEnrollSheet = false
    @State private var selectedEnrollment: ProgramEnrollment?
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with Add Button
            HStack {
                SectionHeader(title: "Program Enrollments", subtitle: "\(client.activeProgramsCount) active programs")
                
                ForgeButton(title: "Enroll in Program", style: .primary) {
                    showingEnrollSheet = true
                }
            }
            
            // Active Enrollments
            if let enrollments = client.programEnrollments?.allObjects as? [ProgramEnrollment],
               !enrollments.filter({ $0.isActive }).isEmpty {
                
                VStack(spacing: 12) {
                    ForEach(enrollments.filter { $0.isActive }, id: \.id) { enrollment in
                        ProgramEnrollmentCard(enrollment: enrollment) {
                            selectedEnrollment = enrollment
                        }
                    }
                }
            } else {
                ForgeCard {
                    VStack(spacing: 12) {
                        Image(systemName: "star.slash")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No Active Program Enrollments")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Enroll this client in a program to track their progress")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            // Available Programs
            SectionHeader(title: "Available Programs", subtitle: "Programs client can enroll in")
            
            AvailableProgramsView(client: client)
        }
        .sheet(isPresented: $showingEnrollSheet) {
            ProgramEnrollmentSheet(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedEnrollment) { enrollment in
            ProgramEnrollmentDetailView(enrollment: enrollment)
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Program Enrollment Card
struct ProgramEnrollmentCard: View {
    let enrollment: ProgramEnrollment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ForgeCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            if let program = enrollment.program {
                                Text(program.name)
                                    .font(.brandBodyBold)
                                    .foregroundColor(.textPrimary)
                                
                                Text(program.programType?.capitalized ?? "Program")
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        StatusBadge(
                            text: enrollment.status?.capitalized ?? "Unknown",
                            status: enrollmentStatus
                        )
                    }
                    
                    Divider()
                        .background(Color.lightCharcoal)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(icon: "calendar", title: "Enrolled", value: enrollment.enrollmentDate.formatted(date: .abbreviated, time: .omitted))
                        
                        if let expectedDate = enrollment.expectedCompletionDate {
                            InfoRow(icon: "flag.checkered", title: "Expected Completion", value: expectedDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        
                        if let staff = enrollment.assignedStaff {
                            InfoRow(icon: "person.fill", title: "Assigned Staff", value: staff.fullName)
                        }
                        
                        if let goals = enrollment.goals, !goals.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Goals")
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                                
                                ForEach(goals.prefix(3), id: \.self) { goal in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.forgeTeal)
                                            .frame(width: 4, height: 4)
                                        
                                        Text(goal)
                                            .font(.brandCaption)
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Progress
                    if enrollment.isCompleted {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.successGreen)
                            
                            Text("Completed on \(enrollment.actualCompletionDate?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        ProgressView(value: enrollmentProgress)
                            .tint(.forgeTeal)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var enrollmentStatus: StatusBadge.Status {
        switch enrollment.status {
        case "active": return .active
        case "completed": return .success
        case "withdrawn": return .warning
        case "suspended": return .danger
        default: return .neutral
        }
    }
    
    private var enrollmentProgress: Double {
        // Calculate progress based on enrollment date and expected completion
        guard let startDate = enrollment.enrollmentDate as Date?,
              let expectedDate = enrollment.expectedCompletionDate as Date? else {
            return 0.0
        }
        
        let totalDuration = expectedDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        
        return min(max(elapsed / totalDuration, 0.0), 1.0)
    }
}

// MARK: - Available Programs View
struct AvailableProgramsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var availablePrograms: [Program] = []
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(availablePrograms, id: \.id) { program in
                    AvailableProgramCard(program: program, client: client)
                }
            }
            .padding()
        }
        .onAppear {
            loadAvailablePrograms()
        }
    }
    
    private func loadAvailablePrograms() {
        let allPrograms = Program.fetchAll(in: viewContext)
        let enrolledProgramIds = Set((client.programEnrollments?.allObjects as? [ProgramEnrollment])?.compactMap { $0.program?.id } ?? [])
        
        availablePrograms = allPrograms.filter { program in
            program.status == "active" && !enrolledProgramIds.contains(program.id)
        }
    }
}

// MARK: - Available Program Card
struct AvailableProgramCard: View {
    let program: Program
    let client: Client
    
    @State private var showingEnrollDialog = false
    
    var body: some View {
        ForgeCard {
            VStack(alignment: .leading, spacing: 12) {
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
                    
                    if program.isFull {
                        StatusBadge(text: "Full", status: .warning)
                    } else {
                        StatusBadge(text: "\(program.availableCapacity) slots", status: .success)
                    }
                }
                
                if let description = program.descriptionText {
                    Text(description)
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                        .lineLimit(2)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Capacity")
                            .font(.brandTiny)
                            .foregroundColor(.textMuted)
                        
                        Text("\(program.currentEnrollment)/\(program.capacity)")
                            .font(.brandCaption)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    ForgeButton(
                        title: "Enroll",
                        style: .primary,
                        isDisabled: program.isFull
                    ) {
                        showingEnrollDialog = true
                    }
                }
            }
        }
        .alert("Enroll in Program", isPresented: $showingEnrollDialog) {
            Alert(
                title: Text("Enroll \(client.fullName) in \(program.name)?"),
                message: Text("This will add \(client.fullName) to the \(program.name) program."),
                primaryButton: .default(Text("Enroll")) {
                    enrollInProgram()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func enrollInProgram() {
        // Implementation would go here
        print("Enroll \(client.fullName) in \(program.name)")
    }
}

// MARK: - Program Enrollment Sheet
struct ProgramEnrollmentSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var selectedProgram: Program?
    @State private var assignedStaff: Staff?
    @State private var expectedCompletionDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var goals: [String] = []
    @State private var newGoal = ""
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Program Selection")) {
                    Picker("Program", selection: $selectedProgram) {
                        Text("Select a program").tag(nil as Program?)
                        ForEach(availablePrograms, id: \.id) { program in
                            Text(program.name).tag(program as Program?)
                        }
                    }
                }
                
                if selectedProgram != nil {
                    Section(header: Text("Enrollment Details")) {
                        DatePicker("Expected Completion", selection: $expectedCompletionDate)
                        
                        Picker("Assigned Staff", selection: $assignedStaff) {
                            Text("Unassigned").tag(nil as Staff?)
                            ForEach(availableStaff, id: \.id) { staff in
                                Text(staff.fullName).tag(staff as Staff?)
                            }
                        }
                    }
                    
                    Section(header: Text("Goals")) {
                        ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                            HStack {
                                Text(goal)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                                
                                Spacer()
                                
                                Button(action: {
                                    goals.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.dangerRed)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("Add goal", text: $newGoal)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            Button(action: addGoal) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.forgeTeal)
                            }
                            .disabled(newGoal.isEmpty)
                        }
                    }
                    
                    Section(header: Text("Notes")) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                }
            }
            .navigationTitle("Enroll in Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ForgeButton(
                        title: "Enroll",
                        style: .primary,
                        isDisabled: selectedProgram == nil || isLoading,
                        isLoading: isLoading
                    ) {
                        enrollClient()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var availablePrograms: [Program] {
        let allPrograms = Program.fetchAll(in: viewContext)
        let enrolledProgramIds = Set((client.programEnrollments?.allObjects as? [ProgramEnrollment])?.compactMap { $0.program?.id } ?? [])
        return allPrograms.filter { program in
            program.status == "active" && !enrolledProgramIds.contains(program.id) && !program.isFull
        }
    }
    
    private var availableStaff: [Staff] {
        Staff.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func addGoal() {
        guard !newGoal.isEmpty else { return }
        goals.append(newGoal)
        newGoal = ""
    }
    
    private func enrollClient() {
        guard let program = selectedProgram else { return }
        
        isLoading = true
        
        let staff = assignedStaff ?? Staff.fetchAll(in: viewContext).first
        
        let enrollment = ProgramEnrollment.create(
            in: viewContext,
            client: client,
            program: program,
            assignedStaff: staff ?? Staff(context: viewContext),
            createdBy: staff ?? Staff(context: viewContext)
        )
        
        enrollment.expectedCompletionDate = expectedCompletionDate
        enrollment.goals = goals
        enrollment.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error enrolling client: \(error)")
            isLoading = false
        }
    }
}

// MARK: - Program Enrollment Detail View
struct ProgramEnrollmentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let enrollment: ProgramEnrollment
    
    @State private var selectedTab: EnrollmentTab = .overview
    @State private var showingCompleteDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let program = enrollment.program {
                        Text(program.name)
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                    }
                    
                    Text("Enrolled: \(enrollment.enrollmentDate.formatted(date: .long, time: .omitted))")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if enrollment.isActive {
                    ForgeButton(title: "Complete Enrollment", style: .primary) {
                        showingCompleteDialog = true
                    }
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Tab Content
            Picker("Enrollment Tab", selection: $selectedTab) {
                ForEach(EnrollmentTab.allCases, id: \.self) { tab in
                    Text(tab.displayName).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            ScrollView {
                Group {
                    switch selectedTab {
                    case .overview:
                        EnrollmentOverviewTab(enrollment: enrollment)
                    case .notes:
                        EnrollmentNotesTab(enrollment: enrollment)
                    case .tasks:
                        EnrollmentTasksTab(enrollment: enrollment)
                    case .documents:
                        EnrollmentDocumentsTab(enrollment: enrollment)
                    case .outcomes:
                        EnrollmentOutcomesTab(enrollment: enrollment)
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color.deepCharcoal)
        .alert("Complete Enrollment", isPresented: $showingCompleteDialog) {
            Alert(
                title: Text("Complete this enrollment?"),
                message: Text("This will mark the program as completed and record the completion date."),
                primaryButton: .default(Text("Complete")) {
                    completeEnrollment()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func completeEnrollment() {
        enrollment.complete()
        try? viewContext.save()
        dismiss()
    }
}

enum EnrollmentTab: String, CaseIterable {
    case overview = "Overview"
    case notes = "Notes"
    case tasks = "Tasks"
    case documents = "Documents"
    case outcomes = "Outcomes"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Enrollment Tab Views
struct EnrollmentOverviewTab: View {
    let enrollment: ProgramEnrollment
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Enrollment Details")
            
            ForgeCard {
                VStack(spacing: 12) {
                    InfoRow(icon: "star.fill", title: "Program", value: enrollment.program?.name ?? "Unknown")
                    InfoRow(icon: "calendar", title: "Enrollment Date", value: enrollment.enrollmentDate.formatted(date: .long, time: .omitted))
                    
                    if let expectedDate = enrollment.expectedCompletionDate {
                        InfoRow(icon: "flag.checkered", title: "Expected Completion", value: expectedDate.formatted(date: .long, time: .omitted))
                    }
                    
                    if enrollment.isCompleted, let actualDate = enrollment.actualCompletionDate {
                        InfoRow(icon: "checkmark.circle.fill", title: "Actual Completion", value: actualDate.formatted(date: .long, time: .omitted), iconColor: .successGreen)
                    }
                    
                    if let staff = enrollment.assignedStaff {
                        InfoRow(icon: "person.fill", title: "Assigned Staff", value: staff.fullName)
                    }
                    
                    InfoRow(icon: "info.circle", title: "Status", value: enrollment.status?.capitalized ?? "Unknown")
                }
            }
            
            if let goals = enrollment.goals, !goals.isEmpty {
                SectionHeader(title: "Goals")
                
                ForgeCard {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(goals.enumerated()), id: \.offset) { index, goal in
                            HStack(spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                                
                                Text(goal)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                }
            }
            
            if let notes = enrollment.notes, !notes.isEmpty {
                SectionHeader(title: "Notes")
                
                ForgeCard {
                    Text(notes)
                        .font(.brandBody)
                        .foregroundColor(.textPrimary)
                }
            }
        }
    }
}

struct EnrollmentNotesTab: View {
    let enrollment: ProgramEnrollment
    
    var body: some View {
        ForgeCard {
            Text("Program-specific notes coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct EnrollmentTasksTab: View {
    let enrollment: ProgramEnrollment
    
    var body: some View {
        ForgeCard {
            Text("Program-specific tasks coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct EnrollmentDocumentsTab: View {
    let enrollment: ProgramEnrollment
    
    var body: some View {
        ForgeCard {
            Text("Program-specific documents coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct EnrollmentOutcomesTab: View {
    let enrollment: ProgramEnrollment
    
    var body: some View {
        ForgeCard {
            Text("Program outcomes tracking coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}