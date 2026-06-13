import SwiftUI

// MARK: - Task Management View
struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = TaskListViewModel()
    
    @State private var selectedFilter: TaskFilter = .all
    @State private var selectedPriority: TaskPriority = .all
    @State private var showingNewTaskSheet = false
    @State private var selectedTask: Task?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Task Management")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Manage tasks, automate workflows, and track progress")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "New Task", style: .primary) {
                        showingNewTaskSheet = true
                    }
                }
                
                // Task Metrics
                HStack(spacing: 16) {
                    TaskMetricCard(
                        title: "Total Tasks",
                        value: "\(viewModel.totalTasks)",
                        subtitle: "All tasks in system",
                        icon: "list.bullet",
                        color: .forgeTeal
                    )
                    
                    TaskMetricCard(
                        title: "Due Today",
                        value: "\(viewModel.dueToday)",
                        subtitle: "Requires attention",
                        icon: "calendar.badge.exclamationmark",
                        color: .warningGold
                    )
                    
                    TaskMetricCard(
                        title: "Overdue",
                        value: "\(viewModel.overdueTasks)",
                        subtitle: "Past due date",
                        icon: "exclamationmark.triangle.fill",
                        color: .dangerRed
                    )
                    
                    TaskMetricCard(
                        title: "Completed Today",
                        value: "\(viewModel.completedToday)",
                        subtitle: "Tasks finished",
                        icon: "checkmark.circle.fill",
                        color: .successGreen
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                
                Picker("Priority", selection: $selectedPriority) {
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Text(priority.displayName).tag(priority)
                    }
                }
                
                Spacer()
                
                Text("\(viewModel.filteredTasks.count) tasks")
                    .font(.brandCaption)
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal)
            
            // Task List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.filteredTasks, id: \.id) { task in
                        TaskCard(task: task) {
                            selectedTask = task
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewTaskSheet) {
            NewTaskSheet()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
        .onChange(of: selectedFilter) { newValue in
            viewModel.filter = newValue
        }
        .onChange(of: selectedPriority) { newValue in
            viewModel.priorityFilter = newValue
        }
    }
}

// MARK: - Task Metric Card
struct TaskMetricCard: View {
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

// MARK: - Task Card
struct TaskCard: View {
    let task: Task
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard(backgroundColor: priorityBackgroundColor) {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.taskName)
                                .font(.brandBodyBold)
                                .foregroundColor(.textPrimary)
                            
                            if let client = task.client {
                                Text(client.fullName)
                                    .font(.brandTiny)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            StatusBadge(
                                text: task.priorityEnum.displayName,
                                status: priorityStatus
                            )
                            
                            StatusBadge(
                                text: task.status?.capitalized ?? "Unknown",
                                status: taskStatus
                            )
                        }
                    }
                    
                    // Details
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let dueDate = task.dueDate {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .foregroundColor(task.isOverdue ? .dangerRed : .textSecondary)
                                        .font(.brandTiny)
                                    
                                    Text(dueDateText)
                                        .font(.brandCaption)
                                        .foregroundColor(task.isOverdue ? .dangerRed : .textPrimary)
                                }
                            }
                            
                            if let staff = task.assignedStaff {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.textSecondary)
                                        .font(.brandTiny)
                                    
                                    Text(staff.fullName)
                                        .font(.brandCaption)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if task.autoCreated {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.forgeTeal)
                                    .font(.brandTiny)
                                
                                Text("Auto-generated")
                                    .font(.brandTiny)
                                    .foregroundColor(.forgeTeal)
                            }
                        }
                    }
                    
                    // Notes Preview
                    if let notes = task.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                            
                            Text(notes)
                                .font(.brandCaption)
                                .foregroundColor(.textPrimary)
                                .lineLimit(2)
                        }
                    }
                    
                    // Actions
                    HStack(spacing: 8) {
                        ArkheButton(title: "Complete", style: .primary, isDisabled: task.status == "completed") {
                            completeTask()
                        }
                        
                        ArkheIconButton(systemImage: "phone", style: .secondary) {
                            // Call related action
                        }
                        
                        ArkheIconButton(systemImage: "doc.text", style: .outline) {
                            // Add note action
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityBackgroundColor: Color {
        switch task.priorityEnum {
        case .urgent: return Color.dangerRed.opacity(0.1)
        case .high: return Color.riskHigh.opacity(0.1)
        case .medium: return Color.warningGold.opacity(0.1)
        case .low: return Color.lightCharcoal
        }
    }
    
    private var priorityStatus: StatusBadge.Status {
        switch task.priorityEnum {
        case .urgent: return .danger
        case .high: return .danger
        case .medium: return .warning
        case .low: return .info
        }
    }
    
    private var taskStatus: StatusBadge.Status {
        switch task.status {
        case "completed": return .success
        case "in_progress": return .active
        case "cancelled": return .neutral
        default: return .info
        }
    }
    
    private var dueDateText: String {
        guard let dueDate = task.dueDate else { return "No due date" }
        
        if task.isOverdue {
            return "Overdue: \(dueDate.formatted(date: .abbreviated, time: .omitted))"
        }
        
        return dueDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private func completeTask() {
        // In production, this would update the task status
        print("Complete task: \(task.taskName)")
    }
}

// MARK: - Task List ViewModel
class TaskListViewModel: ObservableObject {
    @Published var totalTasks = 0
    @Published var dueToday = 0
    @Published var overdueTasks = 0
    @Published var completedToday = 0
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var filter: TaskFilter = .all
    @Published var priorityFilter: TaskPriority = .all
    
    func loadData(context: NSManagedObjectContext) {
        let request = NSFetchRequest<Task>(entityName: "Task")
        request.sortDescriptors = [
            NSSortDescriptor(key: "dueDate", ascending: true),
            NSSortDescriptor(key: "priority", ascending: false)
        ]
        
        do {
            tasks = try context.fetch(request)
            applyFilters()
            
            // Calculate metrics
            totalTasks = tasks.count
            dueToday = tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return Calendar.current.isDateInToday(dueDate) && task.status != "completed"
            }.count
            
            overdueTasks = tasks.filter { $0.isOverdue }.count
            
            let today = Calendar.current.startOfDay(for: Date())
            completedToday = tasks.filter { task in
                guard let completionDate = task.completionDate else { return false }
                return task.status == "completed" && Calendar.current.isDate(completionDate, inSameDayAs: today)
            }.count
            
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
    
    func applyFilters() {
        filteredTasks = tasks.filter { task in
            // Apply status filter
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .myTasks:
                matchesFilter = task.assignedStaff?.email == "current_user" // Would check current user
            case .overdue:
                matchesFilter = task.isOverdue
            case .dueToday:
                matchesFilter = task.dueDate != nil && Calendar.current.isDateInToday(task.dueDate!)
            case .completed:
                matchesFilter = task.status == "completed"
            }
            
            // Apply priority filter
            let matchesPriority: Bool
            switch priorityFilter {
            case .all:
                matchesPriority = true
            default:
                matchesPriority = task.priorityEnum.rawValue == priorityFilter.rawValue
            }
            
            return matchesFilter && matchesPriority
        }
    }
}

enum TaskFilter: String, CaseIterable {
    case all = "All Tasks"
    case myTasks = "My Tasks"
    case overdue = "Overdue"
    case dueToday = "Due Today"
    case completed = "Completed"
    
    var displayName: String {
        rawValue
    }
}

enum TaskPriority: String, CaseIterable {
    case all = "All Priorities"
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    
    var displayName: String {
        rawValue
    }
}

extension Task.PriorityEnum {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
}

// MARK: - New Task Sheet
struct NewTaskSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var taskName = ""
    @State private var taskType: TaskType = .general
    @State private var selectedClient: Client?
    @State private var selectedStaff: Staff?
    @State private var dueDate: Date = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var priority: Task.PriorityEnum = .medium
    @State private var notes = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Task Details")) {
                    TextField("Task Name", text: $taskName)
                    
                    Picker("Task Type", selection: $taskType) {
                        ForEach(TaskType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    DatePicker("Due Date", selection: $dueDate)
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(Task.PriorityEnum.allCases, id: \.self) { priority in
                            Text(priority.displayName).tag(priority)
                        }
                    }
                }
                
                Section(header: Text("Assignment")) {
                    Picker("Client", selection: $selectedClient) {
                        Text("No client").tag(nil as Client?)
                        ForEach(availableClients, id: \.id) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                    
                    Picker("Assigned Staff", selection: $selectedStaff) {
                        Text("Unassigned").tag(nil as Staff?)
                        ForEach(availableStaff, id: \..id) { staff in
                            Text(staff.fullName).tag(staff as Staff?)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Automation")) {
                    Toggle("Auto-create follow-up tasks", isOn: .constant(false))
                    
                    Text("Task automation rules can be configured in Settings")
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Create Task",
                        style: .primary,
                        isDisabled: taskName.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        createTask()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private var availableClients: [Client] {
        Client.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private var availableStaff: [Staff] {
        Staff.fetchAll(in: viewContext).filter { $0.status == "active" }
    }
    
    private func createTask() {
        guard let client = selectedClient,
              let staff = selectedStaff ?? availableStaff.first else { return }
        
        isLoading = true
        
        let task = Task.create(
            in: viewContext,
            taskName: taskName,
            client: client,
            assignedStaff: staff,
            dueDate: dueDate,
            priority: priority.rawValue,
            createdBy: staff
        )
        
        task.taskType = taskType.rawValue
        task.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error creating task: \(error)")
            isLoading = false
        }
    }
}

enum TaskType: String, CaseIterable {
    case general = "General"
    case callClient = "Call Client"
    case uploadDocument = "Upload Document"
    case scheduleAppointment = "Schedule Appointment"
    case completeIntake = "Complete Intake"
    case followUpPartner = "Follow Up with Partner"
    case submitApplication = "Submit Application"
    case verifyHousing = "Verify Housing Status"
    case confirmCourtDate = "Confirm Court Date"
    case reviewSafetyPlan = "Review Safety Plan"
    case sendReferral = "Send Referral"
    case completeProgramGoal = "Complete Program Goal"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Task Detail View
struct TaskDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let task: Task
    
    @State private var showingCompleteDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.taskName)
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    if let client = task.client {
                        Text(client.fullName)
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                if task.status != "completed" {
                    ArkheButton(title: "Complete Task", style: .primary) {
                        showingCompleteDialog = true
                    }
                }
            }
            .padding()
            .background(task.status == "completed" ? Color.successGreen.opacity(0.1) : priorityBackgroundColor)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Task Details")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            InfoRow(icon: "list.bullet", title: "Task Type", value: task.taskType?.displayName ?? "General")
                            
                            if let dueDate = task.dueDate {
                                InfoRow(
                                    icon: task.isOverdue ? "exclamationmark.triangle.fill" : "calendar",
                                    title: "Due Date",
                                    value: dueDate.formatted(date: .long, time: .shortened),
                                    iconColor: task.isOverdue ? .dangerRed : .forgeTeal
                                )
                            }
                            
                            InfoRow(icon: "flag.fill", title: "Priority", value: task.priorityEnum.displayName, iconColor: priorityColor)
                            
                            InfoRow(icon: "info.circle", title: "Status", value: task.status?.capitalized ?? "Unknown")
                            
                            if let staff = task.assignedStaff {
                                InfoRow(icon: "person.fill", title: "Assigned Staff", value: staff.fullName)
                            }
                            
                            if task.autoCreated, let trigger = task.autoTriggerEvent {
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.forgeTeal)
                                    
                                    Text("Auto-generated: \(trigger)")
                                        .font(.brandCaption)
                                        .foregroundColor(.forgeTeal)
                                }
                            }
                        }
                    }
                    
                    // Client Information
                    if let client = task.client {
                        SectionHeader(title: "Related Client")
                        
                        ArkheCard {
                            VStack(spacing: 12) {
                                InfoRow(icon: "person.fill", title: "Name", value: client.fullName)
                                
                                if let phone = client.contactPhone {
                                    InfoRow(icon: "phone.fill", title: "Phone", value: phone)
                                }
                                
                                if let email = client.contactEmail {
                                    InfoRow(icon: "envelope.fill", title: "Email", value: email)
                                }
                                
                                InfoRow(icon: "shield.fill", title: "Risk Level", value: client.riskLevel?.capitalized ?? "Unknown", iconColor: riskColor)
                                
                                Button(action: {
                                    // Navigate to client profile
                                }) {
                                    HStack(spacing: 8) {
                                        Text("View Full Client Profile")
                                            .font(.brandCaption)
                                            .foregroundColor(.forgeTeal)
                                        
                                        Image(systemName: "arrow.right")
                                            .font(.brandTiny)
                                            .foregroundColor(.forgeTeal)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = task.notes, !notes.isEmpty {
                        SectionHeader(title: "Notes")
                        
                        ArkheCard {
                            VStack(alignment: . leading, spacing: 8) {
                                Text(notes)
                                    .font(.brandBody)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    
                    // Timeline
                    SectionHeader(title: "Timeline")
                    
                    ArkheCard {
                        VStack(spacing: 16) {
                            TimelineItem(
                                icon: "plus.circle.fill",
                                title: "Task Created",
                                date: task.createdAt,
                                user: task.createdBy?.fullName ?? "System"
                            )
                            
                            if let completionDate = task.completionDate {
                                TimelineItem(
                                    icon: "checkmark.circle.fill",
                                    title: "Task Completed",
                                    date: completionDate,
                                    user: task.assignedStaff?.fullName ?? "System",
                                    color: .successGreen
                                )
                            }
                        }
                    }
                    
                    // Quick Actions
                    if task.status != "completed" {
                        SectionHeader(title: "Quick Actions")
                        
                        HStack(spacing: 12) {
                            ArkheButton(title: "Call Client", style: .primary) {
                                // Call action
                            }
                            
                            ArkheButton(title: "Add Note", style: .secondary) {
                                // Add note action
                            }
                            
                            ArkheButton(title: "Reschedule", style: .outline) {
                                // Reschedule action
                            }
                            
                            ArkheButton(title: "Escalate", style: .danger) {
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
        .alert("Complete Task", isPresented: $showingCompleteDialog) {
            Alert(
                title: Text("Complete Task"),
                message: Text("This will mark the task as completed and record the completion date."),
                primaryButton: .default(Text("Complete")) {
                    completeTask()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var priorityBackgroundColor: Color {
        switch task.priorityEnum {
        case .urgent: return Color.dangerRed.opacity(0.15)
        case .high: return Color.riskHigh.opacity(0.15)
        case .medium: return Color.warningGold.opacity(0.15)
        case .low: return Color.lightCharcoal
        }
    }
    
    private var priorityColor: Color {
        switch task.priorityEnum {
        case .urgent: return .dangerRed
        case .high: return .riskHigh
        case .medium: return .warningGold
        case .low: return .successGreen
        }
    }
    
    private var riskColor: Color {
        task.client?.riskLevelEnum.color ?? .riskLow
    }
    
    private func completeTask() {
        task.complete()
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Staff Work Queue
struct StaffWorkQueueView: View {
    @Environment(\. mutable object) private var viewContext
    @StateObject private var viewModel = WorkQueueViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SectionHeader(title: "My Work Queue")
                
                // Tasks Due Today
                VStack(spacing: 12) {
                    SectionHeader(title: "Due Today", subtitle: "\(viewModel.tasksDueToday.count) tasks")
                    
                    if viewModel.tasksDueToday.isEmpty {
                        ArkheCard {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.successGreen)
                                
                                Text("No tasks due today")
                                    .font(.brandBody)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    } else {
                        ForEach(viewModel.tasksDueToday, id: \.id) { task in
                            WorkQueueTaskCard(task: task)
                        }
                    }
                }
                
                // Overdue Tasks
                if !viewModel.overdueTasks.isEmpty {
                    VStack(spacing: 12) {
                        SectionHeader(title: "Overdue", subtitle: "\(viewModel.overdueTasks.count) tasks require attention")
                        
                        ForEach(viewModel.overdueTasks, id: \.id) { task in
                            WorkQueueTaskCard(task: task)
                        }
                    }
                }
                
                // High Risk Clients
                if !viewModel.highRiskClients.isEmpty {
                    VStack(spacing: 12) {
                        SectionHeader(title: "High Risk Clients", subtitle: "\(viewModel.highRiskClients.count) clients need attention")
                        
                        ForEach(viewModel.highRiskClients, id: \. id) { client in
                            HighRiskClientCard(client: client)
                        }
                    }
                }
                
                // New Assignments
                if !viewModel.newAssignments.isEmpty {
                    VStack(spacing: 12) {
                        SectionHeader(title: "New Assignments", subtitle: "\(viewModel.newAssignments.count) new assignments")
                        
                        ForEach(viewModel.newAssignments, id: \.id) { task in
                            WorkQueueTaskCard(task: task)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.deepCharcoal)
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
    }
}

// MARK: - Work Queue Task Card
struct WorkQueueTaskCard: View {
    let task: Task
    
    var body: some View {
        ArkheCard {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.taskName)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    if let client = task.client {
                        Text(client.fullName)
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let dueDate = task.dueDate {
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.brandTiny)
                            .foregroundColor(task.isOverdue ? .dangerRed : .textPrimary)
                    }
                    
                    StatusBadge(
                        text: task.priorityEnum.displayName,
                        status: priorityStatus
                    )
                }
            }
        }
    }
    
    private var priorityStatus: StatusBadge.Status {
        switch task.priorityEnum {
        case .urgent: return .danger
        case .high: return .danger
        case .medium: return .warning
        case .low: return .info
        }
    }
}

// MARK: - High Risk Client Card
struct HighRiskClientCard: View {
    let client: Client
    
    var body: some View {
        ArkheCard(backgroundColor: .dangerRed.opacity(0.1)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.fullName)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Text("High Risk - Immediate attention required")
                        .font(.brandTiny)
                        .foregroundColor(.dangerRed)
                }
                
                Spacer()
                
                ArkheButton(title: "View Profile", style: .danger) {
                    // Navigate to client
                }
            }
        }
    }
}

// MARK: - Work Queue ViewModel
class WorkQueueViewModel: ObservableObject {
    @Published var tasksDueToday: [Task] = []
    @Published var overdueTasks: [Task] = []
    @Published var highRiskClients: [Client] = []
    @Published var newAssignments: [Task] = []
    
    func loadData(context: NSManagedObjectContext) {
        // Load tasks due today
        let taskRequest = NSFetchRequest<Task>(entityName: "Task")
        taskRequest.predicate = NSPredicate(format: "dueDate >= %@ AND dueDate < %@ AND status != 'completed'",
                                      argumentArray: [
                                        Calendar.current.startOfDay(for: Date()) as NSDate,
                                        Calendar.current.date(byAdding: .day, value: 1, to: Date())! as NSDate
                                      ] as [Any])
        
        do {
            tasksDueToday = try context.fetch(taskRequest)
            
            // Load overdue tasks
            let overdueRequest = NSFetchRequest<Task>(entityName: "Task")
            overdueRequest.predicate = NSPredicate(format: "dueDate < %@ AND status != 'completed'",
                                            argument: Date() as NSDate)
            overdueTasks = try context.fetch(overdueRequest)
            
            // Load high risk clients
            let clientRequest = NSFetchRequest<Client>(entityName: "Client")
            clientRequest.predicate = NSPredicate(format: "riskLevel IN {'high', 'critical'} AND status == 'active'")
            
            highRiskClients = try context.fetch(clientRequest)
            
            // Load new assignments (tasks created in last 24 hours)
            let newTaskRequest = NSFetchRequest<Task>(entityName: "Task")
            newTaskRequest.predicate = NSPredicate(format: "createdAt >= %@", 
                                            argument: Calendar.current.date(byAdding: .day, value: -1, to: Date())! as NSDate)
            newAssignments = try context.fetch(newTaskRequest)
            
        } catch {
            print("Error loading work queue data: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    TaskListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}