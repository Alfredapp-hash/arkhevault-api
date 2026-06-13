import SwiftUI
import EventKit

// MARK: - Calendar View
struct CalendarView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = CalendarViewModel()
    
    @State private var selectedDate: Date = Date()
    @State private var showingNewAppointmentSheet = false
    @State private var selectedAppointment: Appointment?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendar")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Manage appointments and schedule events")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        ArkheButton(title: "Previous", style: .outline) {
                            viewModel.changeMonth(by: -1)
                        }
                        
                        Text(viewModel.currentMonth)
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                            .frame(width: 150)
                        
                        ArkheButton(title: "Next", style: .outline) {
                            viewModel.changeMonth(by: 1)
                        }
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "New Appointment", style: .primary) {
                        showingNewAppointmentSheet = true
                    }
                }
                
                // Calendar Metrics
                HStack(spacing: 16) {
                    CalendarMetricCard(
                        title: "Today's Appointments",
                        value: "\(viewModel.todayAppointmentsCount)",
                        subtitle: "Scheduled today",
                        icon: "calendar.badge.clock",
                        color: .forgeTeal
                    )
                    
                    CalendarMetricCard(
                        title: "This Week",
                        value: "\(viewModel.weekAppointmentsCount)",
                        subtitle: "Appointments this week",
                        icon: "calendar.badge.checkmark",
                        color: .bronze
                    )
                    
                    CalendarMetricCard(
                        title: "Pending",
                        value: "\(viewModel.pendingAppointmentsCount)",
                        subtitle: "Awaiting confirmation",
                        icon: "clock.fill",
                        color: .warningGold
                    )
                    
                    CalendarMetricCard(
                        title: "Completed",
                        value: "\(viewModel.completedThisWeek)",
                        subtitle: "Completed this week",
                        icon: "checkmark.circle.fill",
                        color: .successGreen
                    )
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Calendar Grid
            CalendarGridView(
                selectedDate: $selectedDate,
                appointments: viewModel.appointmentsForMonth,
                onDateSelected: { date in
                    selectedDate = date
                }
            )
            .padding(.horizontal)
            
            // Day's Appointments
            VStack(spacing: 16) {
                SectionHeader(
                    title: formatSelectedDate(selectedDate),
                    subtitle: "\(viewModel.appointmentsForDate(selectedDate).count) appointments"
                )
                
                if viewModel.appointmentsForDate(selectedDate).isEmpty {
                    ArkheCard {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.textMuted)
                            
                            Text("No appointments scheduled")
                                .font(.brandBody)
                                .foregroundColor(.textSecondary)
                        }
                    }
                } else {
                    ForEach(viewModel.appointmentsForDate(selectedDate), id: \.id) { appointment in
                        AppointmentCard(appointment: appointment) {
                            selectedAppointment = appointment
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.deepCharcoal)
        .sheet(isPresented: $showingNewAppointmentSheet) {
            NewAppointmentSheet(selectedDate: selectedDate)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailView(appointment: appointment)
                .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            viewModel.loadAppointments(context: viewContext)
        }
    }
    
    private func formatSelectedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Metric Card
struct CalendarMetricCard: View {
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

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    @Binding var selectedDate: Date
    let appointments: [Date: [Appointment]]
    let onDateSelected: (Date) -> Void
    
    @State private var currentMonth: Date = Date()
    
    private let calendar = Calendar.current
    
    var body: some View {
        ArkheCard {
            VStack(spacing: 12) {
                // Day Headers
                HStack {
                    ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                        Text(day)
                            .font(.brandTiny)
                            .fontWeight(.semibold)
                            .foregroundColor(.textSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                
                Divider()
                    .background(Color.lightCharcoal)
                
                // Calendar Days
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        CalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            hasAppointments: appointments[calendar.startOfDay(for: date)]?.isEmpty == false,
                            appointmentCount: appointments[calendar.startOfDay(for: date)]?.count ?? 0
                        ) {
                            onDateSelected(date)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let numberOfDays = calendar.dateComponents([.day], from: monthInterval.start, to: monthInterval.end).day ?? 0
        let firstDayOfMonth = calendar.dateComponents([.day, .month, .year], from: monthInterval.start)
        var firstWeekday = calendar.date(from: firstDayOfMonth)
        
        // Adjust to Sunday as first day
        let weekday = calendar.component(.weekday, from: firstWeekday!)
        let daysToSubtract = (weekday - 1) % 7
        firstWeekday = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstWeekday!)
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks x 7 days
            if let date = calendar.date(byAdding: .day, value: i, to: firstWeekday!) {
                days.append(date)
            }
        }
        
        return days
    }
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasAppointments: Bool
    let appointmentCount: Int
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.brandBody)
                    .fontWeight(isToday || isSelected ? .bold : .regular)
                    .foregroundColor(isInCurrentMonth ? .textPrimary : .textMuted)
                
                if hasAppointments {
                    HStack(spacing: 2) {
                        ForEach(0..<min(appointmentCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isSelected ? Color.warmIvory : Color.forgeTeal)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .frame(width: 40, height: 40)
            .background(cellBackgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isInCurrentMonth)
    }
    
    private var isInCurrentMonth: Bool {
        calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    private var cellBackgroundColor: Color {
        if isSelected {
            return .forgeTeal
        } else if isToday {
            return .forgeTeal.opacity(0.2)
        } else if hasAppointments {
            return .forgeTeal.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        isSelected ? .forgeTeal : Color.clear
    }
}

// MARK: - Appointment Card
struct AppointmentCard: View {
    let appointment: Appointment
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ArkheCard(backgroundColor: statusBackgroundColor) {
                HStack(spacing: 16) {
                    // Time
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(appointment.startTime))
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(formatTime(appointment.endTime))
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(width: 60)
                    
                    Divider()
                        .frame(height: 40)
                    
                    // Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appointment.title)
                            .font(.brandBodyBold)
                            .foregroundColor(.textPrimary)
                        
                        Text(appointment.appointmentType?.capitalized ?? "Appointment")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        if let client = appointment.client {
                            Text(client.fullName)
                                .font(.brandTiny)
                                .foregroundColor(.forgeTeal)
                        }
                    }
                    
                    Spacer()
                    
                    // Status
                    StatusBadge(
                        text: appointment.status?.capitalized ?? "Scheduled",
                        status: appointmentStatus
                    )
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private var statusBackgroundColor: Color {
        switch appointment.status {
        case "completed":
            return Color.successGreen.opacity(0.1)
        case "cancelled":
            return Color.lightCharcoal
        case "no_show":
            return Color.dangerRed.opacity(0.1)
        default:
            return Color.lightCharcoal
        }
    }
    
    private var appointmentStatus: StatusBadge.Status {
        switch appointment.status {
        case "completed": return .success
        case "cancelled": return .neutral
        case "no_show": return .danger
        default: return .active
        }
    }
}

// MARK: - Calendar ViewModel
class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date = Date()
    @Published var appointments: [Appointment] = []
    @Published var todayAppointmentsCount = 0
    @Published var weekAppointmentsCount = 0
    @Published var pendingAppointmentsCount = 0
    @Published var completedThisWeek = 0
    
    private let calendar = Calendar.current
    
    func loadAppointments(context: NSManagedObjectContext) {
        let request = NSFetchRequest<Appointment>(entityName: "Appointment")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        
        do {
            appointments = try context.fetch(request)
            calculateMetrics()
        } catch {
            print("Error loading appointments: \(error)")
        }
    }
    
    func changeMonth(by value: Int) {
        currentMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) ?? currentMonth
    }
    
    func appointmentsForDate(_ date: Date) -> [Appointment] {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        
        return appointments.filter { appointment in
            guard let startTime = appointment.startTime else { return false }
            return startTime >= dayStart && startTime < dayEnd
        }
    }
    
    var appointmentsForMonth: [Date: [Appointment]] {
        var grouped: [Date: [Appointment]] = [:]
        
        for appointment in appointments {
            guard let startTime = appointment.startTime else { continue }
            let day = calendar.startOfDay(for: startTime)
            
            if grouped[day] == nil {
                grouped[day] = []
            }
            grouped[day]?.append(appointment)
        }
        
        return grouped
    }
    
    var currentMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func calculateMetrics() {
        todayAppointmentsCount = appointmentsForDate(Date()).count
        
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let weekEnd = calendar.dateInterval(of: .weekOfYear, for: Date())?.end ?? Date()
        
        weekAppointmentsCount = appointments.filter { appointment in
            guard let startTime = appointment.startTime else { return false }
            return startTime >= weekStart && startTime < weekEnd
        }.count
        
        pendingAppointmentsCount = appointments.filter { $0.status == "pending" || $0.status == "scheduled" }.count
        
        completedThisWeek = appointments.filter { appointment in
            guard let startTime = appointment.startTime,
                  let endTime = appointment.endTime else { return false }
            return appointment.status == "completed" &&
                   startTime >= weekStart &&
                   startTime < weekEnd
        }.count
    }
}

// MARK: - New Appointment Sheet
struct NewAppointmentSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let selectedDate: Date
    
    @State private var title = ""
    @State private var appointmentType: AppointmentType = .general
    @State private var selectedClient: Client?
    @State private var selectedStaff: Staff?
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var location = ""
    @State private var notes = ""
    @State private var sendReminder = true
    @State private var syncWithCalendar = true
    @State private var isLoading = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        let calendar = Calendar.current
        _startTime = State(initialValue: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? Date())
        _endTime = State(initialValue: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: selectedDate) ?? Date())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appointment Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Appointment Type", selection: $appointmentType) {
                        ForEach(AppointmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    DatePicker("Start Time", selection: $startTime)
                    
                    DatePicker("End Time", selection: $endTime)
                    
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Participants")) {
                    Picker("Client", selection: $selectedClient) {
                        Text("No client").tag(nil as Client?)
                        ForEach(availableClients, id: \.id) { client in
                            Text(client.fullName).tag(client as Client?)
                        }
                    }
                    
                    Picker("Staff", selection: $selectedStaff) {
                        Text("Unassigned").tag(nil as Staff?)
                        ForEach(availableStaff, id: \.id) { staff in
                            Text(staff.fullName).tag(staff as Staff?)
                        }
                    }
                }
                
                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                
                Section(header: Text("Options")) {
                    Toggle("Send Reminder", isOn: $sendReminder)
                    
                    Toggle("Sync with System Calendar", isOn: $syncWithCalendar)
                    
                    if syncWithCalendar {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.forgeTeal)
                            
                            Text("Appointment will be added to macOS Calendar app")
                                .font(.brandCaption)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    ArkheButton(
                        title: "Schedule",
                        style: .primary,
                        isDisabled: title.isEmpty || startTime >= endTime || isLoading,
                        isLoading: isLoading
                    ) {
                        scheduleAppointment()
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
    
    private func scheduleAppointment() {
        guard let currentUser = Staff.fetchAll(in: viewContext).first else { return }
        
        isLoading = true
        
        let appointment = Appointment(context: viewContext)
        appointment.id = UUID()
        appointment.title = title
        appointment.appointmentType = appointmentType.rawValue
        appointment.startTime = startTime
        appointment.endTime = endTime
        appointment.location = location.isEmpty ? nil : location
        appointment.status = "scheduled"
        appointment.reminderSent = false
        appointment.createdAt = Date()
        appointment.client = selectedClient
        appointment.staff = selectedStaff
        appointment.createdBy = currentUser
        
        if !notes.isEmpty {
            appointment.setValue(notes, forKey: "notes")
        }
        
        // Sync with system calendar if enabled
        if syncWithCalendar {
            syncWithSystemCalendar(appointment: appointment)
        }
        
        do {
            try viewContext.save()
            isLoading = false
            dismiss()
        } catch {
            print("Error scheduling appointment: \(error)")
            isLoading = false
        }
    }
    
    private func syncWithSystemCalendar(appointment: Appointment) {
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            if granted, let startTime = appointment.startTime, let endTime = appointment.endTime {
                let event = EKEvent(eventStore: eventStore)
                event.title = appointment.title
                event.startDate = startTime
                event.endDate = endTime
                event.notes = appointment.location
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                try? eventStore.save(event, span: .thisEvent)
            }
        }
    }
}

enum AppointmentType: String, CaseIterable {
    case general = "General"
    case intake = "Intake"
    case followUp = "Follow-up"
    case counseling = "Counseling"
    case legal = "Legal Consultation"
    case medical = "Medical Appointment"
    case housing = "Housing Meeting"
    case court = "Court Appearance"
    case program = "Program Session"
    case volunteer = "Volunteer Meeting"
    case training = "Training"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Appointment Detail View
struct AppointmentDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let appointment: Appointment
    
    @State private var showingCompleteDialog = false
    @State private var showingCancelDialog = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.title)
                        .font(.brandTitle)
                        .foregroundColor(.textPrimary)
                    
                    Text(appointment.appointmentType?.capitalized ?? "Appointment")
                        .font(.brandCaption)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                if appointment.status == "scheduled" {
                    ArkheButton(title: "Complete", style: .primary) {
                        showingCompleteDialog = true
                    }
                    
                    ArkheButton(title: "Cancel", style: .danger) {
                        showingCancelDialog = true
                    }
                }
            }
            .padding()
            .background(statusBackgroundColor)
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    SectionHeader(title: "Appointment Details")
                    
                    ArkheCard {
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Time")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(formatTime(appointment.startTime))
                                        .font(.brandBodyBold)
                                        .foregroundColor(.textPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("End Time")
                                        .font(.brandCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Text(formatTime(appointment.endTime))
                                        .font(.brandBodyBold)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            
                            Divider()
                                .background(Color.lightCharcoal)
                            
                            InfoRow(icon: "list.bullet", title: "Type", value: appointment.appointmentType?.displayName ?? "General")
                            InfoRow(icon: "info.circle", title: "Status", value: appointment.status?.capitalized ?? "Scheduled")
                            
                            if let location = appointment.location {
                                InfoRow(icon: "location.fill", title: "Location", value: location)
                            }
                        }
                    }
                    
                    // Participants
                    if appointment.client != nil || appointment.staff != nil {
                        SectionHeader(title: "Participants")
                        
                        ArkheCard {
                            VStack(spacing: 12) {
                                if let client = appointment.client {
                                    InfoRow(icon: "person.fill", title: "Client", value: client.fullName)
                                }
                                
                                if let staff = appointment.staff {
                                    InfoRow(icon: "briefcase.fill", title: "Staff", value: staff.fullName)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = appointment.value(forKey: "notes") as? String {
                        SectionHeader(title: "Notes")
                        
                        ArkheCard {
                            Text(notes)
                                .font(.brandBody)
                                .foregroundColor(.textPrimary)
                        }
                    }
                    
                    // Actions
                    SectionHeader(title: "Actions")
                    
                    HStack(spacing: 12) {
                        ArkheButton(title: "Edit", style: .primary) {
                            // Edit action
                        }
                        
                        ArkheButton(title: "Reschedule", style: .secondary) {
                            // Reschedule action
                        }
                        
                        ArkheButton(title: "Delete", style: .danger) {
                            // Delete action
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 500)
        .background(Color.deepCharcoal)
        .alert("Complete Appointment", isPresented: $showingCompleteDialog) {
            Alert(
                title: Text("Complete Appointment"),
                message: Text("Mark this appointment as completed?"),
                primaryButton: .default(Text("Complete")) {
                    completeAppointment()
                },
                secondaryButton: .cancel()
            )
        }
        .alert("Cancel Appointment", isPresented: $showingCancelDialog) {
            Alert(
                title: Text("Cancel Appointment"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Cancel")) {
                    appointment.status = "cancelled"
                    try? viewContext.save()
                    dismiss()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var statusBackgroundColor: Color {
        switch appointment.status {
        case "completed":
            return Color.successGreen.opacity(0.15)
        case "cancelled":
            return Color.lightCharcoal
        case "no_show":
            return Color.dangerRed.opacity(0.15)
        default:
            return Color.lightCharcoal
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a on MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func completeAppointment() {
        appointment.status = "completed"
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Preview
#Preview {
    CalendarView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}