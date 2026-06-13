import SwiftUI
import Charts

// MARK: - Dashboard View
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            ArkheLogo(size: .compact, style: .iconOnly)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Executive Dashboard")
                                    .font(.brandTitle)
                                    .foregroundColor(.textPrimary)
                                
                                Text("Real-time organizational metrics and insights")
                                    .font(.brandCaption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Date Range Selector
                    HStack(spacing: 8) {
                        Text("Last 30 Days")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                        
                        Image(systemName: "chevron.down")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.lightCharcoal)
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Key Metrics Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    MetricCard(
                        title: "Active Clients",
                        value: "\(viewModel.totalActiveClients)",
                        subtitle: "+\(viewModel.newClientsThisMonth) this month",
                        icon: "person.2.fill",
                        color: .forgeTeal,
                        trend: .up
                    )
                    
                    MetricCard(
                        title: "Active Programs",
                        value: "\(viewModel.activePrograms)",
                        subtitle: "\(viewModel.programCapacity - viewModel.currentEnrollment) slots available",
                        icon: "star.fill",
                        color: .bronze,
                        trend: .neutral
                    )
                    
                    MetricCard(
                        title: "Open Tasks",
                        value: "\(viewModel.openTasks)",
                        subtitle: "\(viewModel.overdueTasks) overdue",
                        icon: "checkmark.circle.fill",
                        color: .warningGold,
                        trend: viewModel.overdueTasks > 0 ? .down : .up
                    )
                    
                    MetricCard(
                        title: "High Risk",
                        value: "\(viewModel.highRiskClients)",
                        subtitle: "Requires attention",
                        icon: "exclamationmark.triangle.fill",
                        color: .dangerRed,
                        trend: .neutral
                    )
                }
                .padding(.horizontal)
                
                // Charts Row
                HStack(spacing: 16) {
                    // Client Trends Chart
                    ArkheCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Client Trends", subtitle: "Last 6 months")
                            
                            Chart(viewModel.clientTrendData) { data in
                                LineMark(
                                    x: .value("Month", data.month),
                                    y: .value("Clients", data.count)
                                )
                                .foregroundStyle(Color.forgeTeal)
                                .interpolationMethod(.catmullRom)
                                
                                AreaMark(
                                    x: .value("Month", data.month),
                                    y: .value("Clients", data.count)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.forgeTeal.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                            .frame(height: 200)
                        }
                    }
                    
                    // Program Distribution
                    ArkheCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Program Distribution", subtitle: "Current enrollments")
                            
                            Chart(viewModel.programDistribution) { data in
                                BarMark(
                                    x: .value("Program", data.program),
                                    y: .value("Enrollments", data.count)
                                )
                                .foregroundStyle(Color.bronze)
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Activity Feed and Quick Actions
                HStack(spacing: 16) {
                    // Recent Activity
                    ArkheCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Recent Activity", subtitle: "Latest updates")
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.recentActivities.prefix(5)) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                        }
                    }
                    
                    // Quick Actions
                    ArkheCard {
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "Quick Actions", subtitle: "Common tasks")
                            
                            VStack(spacing: 12) {
                                QuickActionButton(
                                    icon: "person.badge.plus",
                                    title: "New Client",
                                    subtitle: "Add a new client"
                                ) {
                                    // Navigate to client creation
                                }
                                
                                QuickActionButton(
                                    icon: "doc.text",
                                    title: "New Note",
                                    subtitle: "Create case note"
                                ) {
                                    // Navigate to note creation
                                }
                                
                                QuickActionButton(
                                    icon: "calendar.badge.plus",
                                    title: "Schedule",
                                    subtitle: "Add appointment"
                                ) {
                                    // Navigate to scheduling
                                }
                                
                                QuickActionButton(
                                    icon: "chart.bar.doc.horizontal",
                                    title: "Generate Report",
                                    subtitle: "Create report"
                                ) {
                                    // Navigate to reports
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Risk Overview
                ArkheCard {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Risk Overview", subtitle: "Clients requiring attention")
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.highRiskClients.prefix(5)) { client in
                                    RiskClientCard(client: client)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Bottom padding
                Color.clear
                    .frame(height: 20)
            }
        }
        .background(Color.deepCharcoal)
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
    }
}

// MARK: - Dashboard ViewModel
class DashboardViewModel: ObservableObject {
    @Published var totalActiveClients = 0
    @Published var newClientsThisMonth = 0
    @Published var activePrograms = 0
    @Published var programCapacity = 0
    @Published var currentEnrollment = 0
    @Published var openTasks = 0
    @Published var overdueTasks = 0
    @Published var highRiskClients = 0
    @Published var clientTrendData: [ClientTrendData] = []
    @Published var programDistribution: [ProgramDistribution] = []
    @Published var recentActivities: [ActivityItem] = []
    @Published var highRiskClientsList: [Client] = []
    
    func loadData(context: NSManagedObjectContext) {
        // Load clients
        let clients = Client.fetchAll(in: context)
        totalActiveClients = clients.filter { $0.status == "active" }.count
        
        // Calculate new clients this month
        let calendar = Calendar.current
        let thisMonth = calendar.dateInterval(of: .month, for: Date())
        newClientsThisMonth = clients.filter { client in
            guard let createdAt = client.createdAt,
                  let monthInterval = thisMonth else { return false }
            return monthInterval.contains(createdAt)
        }.count
        
        // Load programs
        let programs = Program.fetchAll(in: context)
        activePrograms = programs.filter { $0.status == "active" }.count
        programCapacity = Int(programs.reduce(0) { $0 + $1.capacity })
        currentEnrollment = Int(programs.reduce(0) { $0 + $1.currentEnrollment })
        
        // Load tasks
        let allTasks = context.fetch(Task.self)
        openTasks = allTasks.filter { $0.status == "pending" || $0.status == "in_progress" }.count
        overdueTasks = allTasks.filter { $0.isOverdue }.count
        
        // Load high risk clients
        highRiskClientsList = clients.filter { $0.riskLevel == "high" || $0.riskLevel == "critical" }
        highRiskClients = highRiskClientsList.count
        
        // Generate trend data (sample data for now)
        generateSampleTrendData()
        
        // Generate program distribution (sample data for now)
        generateSampleProgramDistribution()
        
        // Generate recent activities (sample data for now)
        generateSampleActivities()
    }
    
    private func generateSampleTrendData() {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]
        clientTrendData = months.enumerated().map { index, month in
            ClientTrendData(month: month, count: 20 + index * 5 + Int.random(in: 0...10))
        }
    }
    
    private func generateSampleProgramDistribution() {
        programDistribution = [
            ProgramDistribution(program: "Victim Advocacy", count: 15),
            ProgramDistribution(program: "Housing Assistance", count: 12),
            ProgramDistribution(program: "Veteran Support", count: 8),
            ProgramDistribution(program: "Recovery Services", count: 10),
            ProgramDistribution(program: "Legal Aid", count: 6)
        ]
    }
    
    private func generateSampleActivities() {
        let activities = [
            ActivityItem(title: "New client enrolled", subtitle: "Jane Doe - Victim Advocacy", time: "2 hours ago", type: .client),
            ActivityItem(title: "Safety flag resolved", subtitle: "John Smith - Risk reduced to low", time: "4 hours ago", type: .safety),
            ActivityItem(title: "Program completed", subtitle: "Mary Johnson - Housing Assistance", time: "6 hours ago", type: .program),
            ActivityItem(title: "New task assigned", subtitle: "Follow-up call for Robert Brown", time: "8 hours ago", type: .task),
            ActivityItem(title: "Document uploaded", subtitle: "Court document for Sarah Davis", time: "1 day ago", type: .document)
        ]
        recentActivities = activities
    }
}

// MARK: - Supporting Data Models
struct ClientTrendData: Identifiable {
    let id = UUID()
    let month: String
    let count: Int
}

struct ProgramDistribution: Identifiable {
    let id = UUID()
    let program: String
    let count: Int
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let time: String
    let type: ActivityType
    
    enum ActivityType {
        case client, safety, program, task, document
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: Trend
    
    enum Trend {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.15))
                    .cornerRadius(8)
                
                Spacer()
                
                if trend != .neutral {
                    HStack(spacing: 4) {
                        Image(systemName: trend == .up ? "arrow.up.right" : "arrow.down.right")
                            .font(.brandTiny)
                            .foregroundColor(trend == .up ? .successGreen : .dangerRed)
                    }
                }
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
                    .foregroundColor(textSecondary(for: trend))
            }
        }
        .padding()
        .background(Color.lightCharcoal)
        .cornerRadius(12)
        .forgeShadow()
    }
    
    private func textSecondary(for trend: Trend) -> Color {
        switch trend {
        case .up: return .successGreen
        case .down: return .dangerRed
        case .neutral: return .textSecondary
        }
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor(for: activity.type))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                
                Text(activity.subtitle)
                    .font(.brandTiny)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()
            
            Text(activity.time)
                .font(.brandTiny)
                .foregroundColor(.textMuted)
        }
        .padding(.vertical, 8)
    }
    
    private func iconColor(for type: ActivityItem.ActivityType) -> Color {
        switch type {
        case .client: return .forgeTeal
        case .safety: return .dangerRed
        case .program: return .bronze
        case .task: return .warningGold
        case .document: return .infoBlue
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.forgeTeal)
                    .frame(width: 36, height: 36)
                    .background(Color.forgeTeal.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.brandCaption)
                        .foregroundColor(.textPrimary)
                    
                    Text(subtitle)
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.brandTiny)
                    .foregroundColor(.textMuted)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RiskClientCard: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(riskColor)
                    .frame(width: 10, height: 10)
                
                Text(client.fullName)
                    .font(.brandCaption)
                    .foregroundColor(.textPrimary)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(icon: "shield.fill", title: "Risk Level", value: client.riskLevel?.capitalized ?? "Unknown", iconColor: riskColor)
                InfoRow(icon: "phone.fill", title: "Contact", value: client.contactPhone ?? "Not provided")
                InfoRow(icon: "clock.fill", title: "Last Contact", value: client.lastContactDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never")
            }
            
            ArkheButton(title: "View Profile", style: .outline) {
                // Navigate to client profile
            }
        }
        .padding()
        .frame(width: 200)
        .background(riskColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(riskColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var riskColor: Color {
        switch client.riskLevel {
        case "critical": return .riskCritical
        case "high": return .riskHigh
        case "medium": return .riskMedium
        default: return .riskLow
        }
    }
}

// MARK: - Core Data Fetch Extension
extension NSManagedObjectContext {
    func fetch<T: NSManagedObject>(_ entity: T.Type) -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        
        do {
            return try fetch(request)
        } catch {
            print("Error fetching \(entity): \(error)")
            return []
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}