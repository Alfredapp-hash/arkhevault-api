import SwiftUI

// MARK: - Client Timeline Tab
struct ClientTimelineTab: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var timelineEvents: [TimelineEvent] = []
    @State private var selectedFilter: TimelineFilter = .all
    @State private var dateRange: DateRange = .allTime
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                SectionHeader(title: "Activity Timeline", subtitle: "\(filteredEvents.count) events")
                
                ArkheButton(title: "Add Event", style: .primary) {
                    // Add event action
                }
            }
            
            // Filters
            HStack(spacing: 12) {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TimelineFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Picker("Date Range", selection: $dateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 150)
                
                Spacer()
            }
            
            // Timeline
            if filteredEvents.isEmpty {
                ArkheCard {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted)
                        
                        Text("No activity yet")
                            .font(.brandBody)
                            .foregroundColor(.textSecondary)
                        
                        Text("Activity will appear here as events occur")
                            .font(.brandCaption)
                            .foregroundColor(.textMuted)
                    }
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(groupedEvents.keys.sorted(by: >), id: \.self) { date in
                            VStack(alignment: .leading, spacing: 12) {
                                // Date Header
                                Text(formatDate(date))
                                    .font(.brandBodyBold)
                                    .foregroundColor(.textPrimary)
                                    .padding(.leading, 20)
                                
                                // Events for this date
                                ForEach(groupedEvents[date] ?? [], id: \.id) { event in
                                    TimelineEventRow(event: event)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadTimelineEvents()
        }
        .onChange(of: selectedFilter) { newValue in
            applyFilter()
        }
        .onChange(of: dateRange) { newValue in
            applyFilter()
        }
    }
    
    private var filteredEvents: [TimelineEvent] {
        var filtered = timelineEvents
        
        // Apply type filter
        switch selectedFilter {
        case .all:
            break
        case .caseNotes:
            filtered = filtered.filter { $0.type == .caseNote }
        case .tasks:
            filtered = filtered.filter { $0.type == .task }
        case .enrollments:
            filtered = filtered.filter { $0.type == .enrollment }
        case .safetyFlags:
            filtered = filtered.filter { $0.type == .safetyFlag }
        case .communications:
            filtered = filtered.filter { $0.type == .communication }
        case .documents:
            filtered = filtered.filter { $0.type == .document }
        }
        
        // Apply date filter
        switch dateRange {
        case .allTime:
            break
        case .today:
            filtered = filtered.filter { Calendar.current.isDateInToday($0.date) }
        case .thisWeek:
            let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            filtered = filtered.filter { $0.date >= startOfWeek }
        case .thisMonth:
            let startOfMonth = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
            filtered = filtered.filter { $0.date >= startOfMonth }
        case .last30Days:
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= thirtyDaysAgo }
        case .last90Days:
            let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
            filtered = filtered.filter { $0.date >= ninetyDaysAgo }
        }
        
        return filtered
    }
    
    private var groupedEvents: [Date: [TimelineEvent]] {
        Dictionary(grouping: filteredEvents) { event in
            Calendar.current.startOfDay(for: event.date)
        }
    }
    
    private func loadTimelineEvents() {
        var events: [TimelineEvent] = []
        
        // Load case notes
        if let notesSet = client.caseNotes, let notes = notesSet.allObjects as? [CaseNote] {
            for note in notes {
                events.append(TimelineEvent(
                    id: note.id ?? UUID(),
                    type: .caseNote,
                    title: "Case Note Added",
                    description: note.noteType?.capitalized ?? "Case Note",
                    date: note.createdAt ?? Date(),
                    user: note.staff?.fullName ?? "System",
                    icon: "doc.text.fill",
                    color: .forgeTeal
                ))
            }
        }
        
        // Load tasks
        if let tasksSet = client.tasks, let tasks = tasksSet.allObjects as? [Task] {
            for task in tasks {
                events.append(TimelineEvent(
                    id: task.id ?? UUID(),
                    type: .task,
                    title: "Task \(task.status?.capitalized ?? "Created")",
                    description: task.taskName,
                    date: task.createdAt ?? Date(),
                    user: task.createdBy?.fullName ?? "System",
                    icon: task.status == "completed" ? "checkmark.circle.fill" : "clock.fill",
                    color: task.status == "completed" ? .successGreen : .warningGold
                ))
            }
        }
        
        // Load enrollments
        if let enrollmentsSet = client.programEnrollments, let enrollments = enrollmentsSet.allObjects as? [ProgramEnrollment] {
            for enrollment in enrollments {
                events.append(TimelineEvent(
                    id: enrollment.id ?? UUID(),
                    type: .enrollment,
                    title: "Enrolled in Program",
                    description: enrollment.program?.name ?? "Program",
                    date: enrollment.enrollmentDate ?? Date(),
                    user: enrollment.createdBy?.fullName ?? "System",
                    icon: "star.fill",
                    color: .bronze
                ))
            }
        }
        
        // Load safety flags
        if let flagsSet = client.safetyFlags, let flags = flagsSet.allObjects as? [SafetyFlag] {
            for flag in flags {
                events.append(TimelineEvent(
                    id: flag.id ?? UUID(),
                    type: .safetyFlag,
                    title: flag.isActive ? "Safety Flag Created" : "Safety Flag Resolved",
                    description: flag.flagType?.capitalized ?? "Safety Flag",
                    date: flag.isActive ? (flag.createdAt ?? Date()) : (flag.resolvedAt ?? Date()),
                    user: flag.isActive ? (flag.createdBy?.fullName ?? "System") : (flag.resolvedBy?.fullName ?? "System"),
                    icon: flag.isActive ? "exclamationmark.triangle.fill" : "checkmark.shield.fill",
                    color: flag.isActive ? .dangerRed : .successGreen
                ))
            }
        }
        
        // Load communications
        if let communicationsSet = client.communications, let communications = communicationsSet.allObjects as? [Communication] {
            for communication in communications {
                events.append(TimelineEvent(
                    id: communication.id ?? UUID(),
                    type: .communication,
                    title: "Communication Logged",
                    description: communication.communicationType?.capitalized ?? "Communication",
                    date: communication.createdAt ?? Date(),
                    user: communication.staff?.fullName ?? "System",
                    icon: "phone.fill",
                    color: .infoBlue
                ))
            }
        }
        
        // Load documents
        if let documentsSet = client.documents, let documents = documentsSet.allObjects as? [Document] {
            for document in documents {
                events.append(TimelineEvent(
                    id: document.id ?? UUID(),
                    type: .document,
                    title: "Document Uploaded",
                    description: document.documentName ?? "Document",
                    date: document.uploadDate ?? Date(),
                    user: document.uploadedBy?.fullName ?? "System",
                    icon: "doc.fill",
                    color: .successGreen
                ))
            }
        }
        
        // Load safe house placements
        if let placementsSet = client.safeHousePlacements, let placements = placementsSet.allObjects as? [SafeHousePlacement] {
            for placement in placements {
                events.append(TimelineEvent(
                    id: placement.id ?? UUID(),
                    type: .safeHouse,
                    title: "Safe House Placement",
                    description: placement.safeHouse?.codeName ?? "Safe House",
                    date: placement.placementDate ?? Date(),
                    user: placement.createdBy?.fullName ?? "System",
                    icon: "house.fill",
                    color: .warningGold
                ))
            }
        }
        
        // Load appointments
        if let appointmentsSet = client.appointments, let appointments = appointmentsSet.allObjects as? [Appointment] {
            for appointment in appointments {
                events.append(TimelineEvent(
                    id: appointment.id ?? UUID(),
                    type: .appointment,
                    title: "Appointment Scheduled",
                    description: appointment.appointmentType?.capitalized ?? "Appointment",
                    date: appointment.startTime ?? Date(),
                    user: appointment.createdBy?.fullName ?? "System",
                    icon: "calendar",
                    color: .forgeTeal
                ))
            }
        }
        
        // Sort by date descending
        timelineEvents = events.sorted { $0.date > $1.date }
    }
    
    private func applyFilter() {
        // Filter is computed property
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

enum TimelineFilter: String, CaseIterable {
    case all = "All Events"
    case caseNotes = "Case Notes"
    case tasks = "Tasks"
    case enrollments = "Enrollments"
    case safetyFlags = "Safety Flags"
    case communications = "Communications"
    case documents = "Documents"
    
    var displayName: String {
        rawValue
    }
}

enum DateRange: String, CaseIterable {
    case allTime = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Timeline Event Data Model
struct TimelineEvent: Identifiable {
    let id: UUID
    let type: EventType
    let title: String
    let description: String
    let date: Date
    let user: String
    let icon: String
    let color: Color
}

enum EventType {
    case caseNote, task, enrollment, safetyFlag, communication, document, safeHouse, appointment
}

// MARK: - Timeline Event Row
struct TimelineEventRow: View {
    let event: TimelineEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon and Line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(event.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: event.icon)
                        .foregroundColor(event.color)
                        .font(.system(size: 18, weight: .medium))
                }
                
                Rectangle()
                    .fill(Color.lightCharcoal)
                    .frame(width: 2)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(event.title)
                        .font(.brandBodyBold)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    Text(event.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.brandTiny)
                        .foregroundColor(.textMuted)
                }
                
                Text(event.description)
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.textSecondary)
                        .font(.brandTiny)
                    
                    Text("By \(event.user)")
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Add Timeline Event Sheet
struct AddTimelineEventSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let client: Client
    
    @State private var eventType: EventTypeChoice = .caseNote
    @State private var title = ""
    @State private var description = ""
    @State private var eventDate = Date()
    @State private var notes = ""
    @State private var isLoading = false
    
    enum EventTypeChoice: String, CaseIterable {
        case caseNote = "Case Note"
        case task = "Task"
        case communication = "Communication"
        case safetyFlag = "Safety Flag"
        case document = "Document"
        case appointment = "Appointment"
        case other = "Other"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    Picker("Event Type", selection: $eventType) {
                        ForEach(EventTypeChoice.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    TextField("Title", text: $title)
                    
                    TextField("Description", text: $description)
                    
                    DatePicker("Event Date", selection: $eventDate)
                }
                
                Section(header: Text("Additional Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Note")) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.forgeTeal)
                        
                        Text("This will create a manual timeline event. Most events are automatically generated by the system.")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                }
            }
            .navigationTitle("Add Timeline Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Add Event",
                        style: .primary,
                        isDisabled: title.isEmpty || description.isEmpty || isLoading,
                        isLoading: isLoading
                    ) {
                        addEvent()
                    }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 400)
    }
    
    private func addEvent() {
        // In production, this would create a custom timeline event entity
        // For now, we'll simulate the action
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

// MARK: - Timeline Summary View
struct TimelineSummaryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let client: Client
    
    @State private var summary: TimelineSummary?
    
    var body: some View {
        VStack(spacing: 20) {
            SectionHeader(title: "Activity Summary")
            
            if let summary = summary {
                HStack(spacing: 16) {
                    SummaryCard(
                        title: "Total Events",
                        value: "\(summary.totalEvents)",
                        icon: "clock.arrow.circlepath",
                        color: .forgeTeal
                    )
                    
                    SummaryCard(
                        title: "Case Notes",
                        value: "\(summary.caseNotes)",
                        icon: "doc.text.fill",
                        color: .bronze
                    )
                    
                    SummaryCard(
                        title: "Tasks",
                        value: "\(summary.tasks)",
                        icon: "checkmark.circle.fill",
                        color: .successGreen
                    )
                    
                    SummaryCard(
                        title: "Enrollments",
                        value: "\(summary.enrollments)",
                        icon: "star.fill",
                        color: .warningGold
                    )
                }
                
                // Recent Activity Chart
                SectionHeader(title: "Activity Trends")
                
                ArkheCard {
                    Text("Activity chart coming soon")
                        .font(.brandBody)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .onAppear {
            generateSummary()
        }
    }
    
    private func generateSummary() {
        var totalEvents = 0
        var caseNotes = 0
        var tasks = 0
        var enrollments = 0
        
        if let notesSet = client.caseNotes {
            caseNotes = notesSet.count
            totalEvents += caseNotes
        }
        
        if let tasksSet = client.tasks {
            tasks = tasksSet.count
            totalEvents += tasks
        }
        
        if let enrollmentsSet = client.programEnrollments {
            enrollments = enrollmentsSet.count
            totalEvents += enrollments
        }
        
        if let flagsSet = client.safetyFlags {
            totalEvents += flagsSet.count
        }
        
        if let communicationsSet = client.communications {
            totalEvents += communicationsSet.count
        }
        
        if let documentsSet = client.documents {
            totalEvents += documentsSet.count
        }
        
        summary = TimelineSummary(
            totalEvents: totalEvents,
            caseNotes: caseNotes,
            tasks: tasks,
            enrollments: enrollments
        )
    }
}

struct TimelineSummary {
    let totalEvents: Int
    let caseNotes: Int
    let tasks: Int
    let enrollments: Int
}

struct SummaryCard: View {
    let title: String
    let value: String
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
                .font(.system(size: 24, weight: .bold, design: .default))
                .foregroundColor(.textPrimary)
            
            Text(title)
                .font(.brandCaption)
                .foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.lightCharcoal)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    ClientTimelineTab(client: CoreDataController.preview.container.viewContext.fetch(Client.self).first!)
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}