import SwiftUI
import Charts

// MARK: - Report List View
struct ReportListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ReportListViewModel()
    
    @State private var selectedReportType: ReportType = .grant
    @State private var selectedTimeframe: ReportTimeframe = .thisMonth
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reports & Analytics")
                            .font(.brandTitle)
                            .foregroundColor(.textPrimary)
                        
                        Text("Generate reports, track metrics, and analyze impact")
                            .font(.brandCaption)
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    ArkheButton(title: "Generate Report", style: .primary) {
                        // Generate report action
                    }
                }
                
                // Report Type Tabs
                Picker("Report Type", selection: $selectedReportType) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // Timeframe Selector
                HStack {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(ReportTimeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.displayName).tag(timeframe)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 150)
                    
                    Spacer()
                    
                    ArkheIconButton(systemImage: "square.and.arrow.down", style: .secondary) {
                        // Export report
                    }
                }
            }
            .padding()
            .background(Color.darkCharcoal)
            
            // Report Content
            ScrollView {
                Group {
                    switch selectedReportType {
                    case .grant:
                        GrantReportView(timeframe: selectedTimeframe)
                            .environment(\.managedObjectContext, viewContext)
                    case .impact:
                        ImpactReportView(timeframe: selectedTimeframe)
                            .environment(\.managedObjectContext, viewContext)
                    case .performance:
                        PerformanceReportView(timeframe: selectedTimeframe)
                            .environment(\.managedObjectContext, viewContext)
                    case .custom:
                        CustomReportView()
                    }
                }
                .padding()
            }
        }
        .background(Color.deepCharcoal)
    }
}

enum ReportType: String, CaseIterable {
    case grant = "Grant Reports"
    case impact = "Impact Reports"
    case performance = "Performance Reports"
    case custom = "Custom Reports"
    
    var displayName: String {
        rawValue
    }
}

enum ReportTimeframe: String, CaseIterable {
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisQuarter = "This Quarter"
    case thisYear = "This Year"
    case custom = "Custom"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Grant Report View
struct GrantReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = GrantReportViewModel()
    
    let timeframe: ReportTimeframe
    
    var body: some View {
        VStack(spacing: 20) {
            // Grant Summary Metrics
            HStack(spacing: 16) {
                GrantMetricCard(
                    title: "Total Clients Served",
                    value: "\(viewModel.totalClientsServed)",
                    subtitle: "Unique clients",
                    icon: "person.2.fill",
                    color: .forgeTeal
                )
                
                GrantMetricCard(
                    title: "Program Completions",
                    value: "\(viewModel.programCompletions)",
                    subtitle: "Programs completed",
                    icon: "star.fill",
                    color: .bronze
                )
                
                GrantMetricCard(
                    title: "Service Hours",
                    value: formatHours(viewModel.serviceHours),
                    subtitle: "Total hours provided",
                    icon: "clock.fill",
                    color: .successGreen
                )
                
                GrantMetricCard(
                    title: "Success Rate",
                    value: "\(viewModel.successRate)%",
                    subtitle: "Program completion rate",
                    icon: "checkmark.circle.fill",
                    color: .infoBlue
                )
            }
            
            // Program-Specific Metrics
            SectionHeader(title: "Program Performance")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.programMetrics, id: \.id) { metric in
                        ProgramMetricCard(metric: metric)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Client Demographics
            SectionHeader(title: "Client Demographics")
            
            HStack(spacing: 16) {
                ArkheCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Demographic Distribution")
                            .font(.brandSubheading)
                            .foregroundColor(.textPrimary)
                        
                        Chart(viewModel.demographicData) { data in
                            BarMark(
                                x: .value("Category", data.category),
                                y: .value("Count", data.count)
                            )
                            .foregroundStyle(Color.forgeTeal)
                            .cornerRadius(4)
                        }
                        .frame(height: 200)
                    }
                }
                
                ArkheCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Housing Status")
                            .font(.brandSubheading)
                            .foregroundColor(.textPrimary)
                        
                        Chart(viewModel.housingData) { data in
                            PieMark(angle: .value("Count", data.count))
                            .foregroundStyle(Color.bronze.opacity(data.opacity))
                        }
                        .frame(height: 200)
                        
                        Legend(position: .bottom, alignment: .center) {
                            ForEach(viewModel.housingData) { data in
                                LegendItem(
                                    label: data.status,
                                    symbol: { Circle().fill(Color.bronze.opacity(data.opacity)) }
                                )
                            }
                        }
                    }
                }
            }
            
            // Outcomes Tracking
            SectionHeader(title: "Grant-Specific Outcomes")
            
            ArkheCard {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.outcomes, id: \.id) { outcome in
                        OutcomeRow(outcome: outcome)
                        Divider()
                            .background(Color.lightCharcoal)
                    }
                }
            }
            
            // Narrative Generation
            SectionHeader(title: "AI-Generated Grant Narrative")
            
            ArkheCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.generatedNarrative)
                        .font(.brandBody)
                        .foregroundColor(.textPrimary)
                    
                    HStack {
                        ArkheButton(title: "Regenerate", style: .secondary) {
                            viewModel.generateNarrative(context: viewContext)
                        }
                        
                        ArkheButton(title: "Copy to Clipboard", style: .outline) {
                            // Copy action
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadData(context: viewContext, timeframe: timeframe)
        }
    }
    
    private func formatHours(_ hours: Double) -> String {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: hours)) ?? "0"
    }
}

// MARK: - Grant Report ViewModel
class GrantReportViewModel: ObservableObject {
    @Published var totalClientsServed = 0
    @Published var programCompletions = 0
    @Published var serviceHours: Double = 0
    @Published var successRate = 0
    @Published var programMetrics: [ProgramMetric] = []
    @Published var demographicData: [DemographicData] = []
    @Published var housingData: [HousingData] = []
    @Published var outcomes: [OutcomeData] = []
    @Published var generatedNarrative = ""
    
    func loadData(context: NSManagedObjectContext, timeframe: ReportTimeframe) {
        // Load data from Core Data
        let clients = Client.fetchAll(in: context)
        totalClientsServed = clients.filter { $0.status == "active" }.count
        
        let programs = Program.fetchAll(in: context)
        programCompletions = programs.reduce(0) { $0 + $1.currentEnrollment }
        
        serviceHours = Double(Int.random(in: 500...2000))
        successRate = Int.random(in: 75...95)
        
        // Generate sample program metrics
        programMetrics = [
            ProgramMetric(id: UUID(), name: "Victim Advocacy", enrollments: 25, completions: 20, successRate: 80),
            ProgramMetric(id: UUID(), name: "Housing Assistance", enrollments: 30, completions: 25, successRate: 83),
            ProgramMetric(id: UUID(), name: "Veteran Support", enrollments: 15, completions: 12, successRate: 80),
            ProgramMetric(id: UUID(), name: "Recovery Services", enrollments: 20, completions: 15, successRate: 75)
        ]
        
        // Generate sample demographic data
        demographicData = [
            DemographicData(category: "Age 18-25", count: 15),
            DemographicData(category: "Age 26-35", count: 22),
            DemographicData(category: "Age 36-45", count: 18),
            DemographicData(category: "Age 46+", count: 10)
        ]
        
        // Generate sample housing data
        housingData = [
            HousingData(status: "Stable", count: 35, opacity: 1.0),
            HousingData(status: "Transitional", count: 20, opacity: 0.7),
            HousingData(status: "Unstable", count: 15, opacity: 0.4),
            HousingData(status: "Homeless", count: 5, opacity: 0.2)
        ]
        
        // Generate sample outcomes
        outcomes = [
            OutcomeData(id: UUID(), metric: "Clients Housed", target: 40, achieved: 35),
            OutcomeData(id: UUID(), metric: "Employment Placements", target: 25, achieved: 22),
            OutcomeData(id: UUID(), metric: "Legal Cases Resolved", target: 15, achieved: 12),
            OutcomeData(id: UUID(), metric: "Counseling Sessions", target: 100, achieved: 95)
        ]
        
        generateNarrative(context: context)
    }
    
    func generateNarrative(context: NSManagedObjectContext) {
        let metrics = GrantMetrics(
            totalClientsServed: totalClientsServed,
            programsCompleted: programCompletions,
            serviceHours: serviceHours,
            successRate: successRate
        )
        
        Task {
            do {
                generatedNarrative = try await AIService.shared.generateGrantNarrative(
                    metrics: metrics,
                    timeframe: timeframe.displayName
                )
            } catch {
                generatedNarrative = "Narrative generation failed. Please try again."
            }
        }
    }
}

struct ProgramMetric: Identifiable {
    let id: UUID
    let name: String
    let enrollments: Int16
    let completions: Int16
    let successRate: Int
}

struct DemographicData: Identifiable {
    let category: String
    let count: Int
}

struct HousingData: Identifiable {
    let status: String
    let count: Int
    let opacity: Double
}

struct OutcomeData: Identifiable {
    let id: UUID
    let metric: String
    let target: Int
    let achieved: Int
}

// MARK: - Grant Metric Card
struct GrantMetricCard: View {
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

// MARK: - Program Metric Card
struct ProgramMetricCard: View {
    let metric: ProgramMetric
    
    var body: some View {
        ArkheCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(metric.name)
                    .font(.brandBodyBold)
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Enrollments:")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                        
                        Text("\(metric.enrollments)")
                            .font(.brandCaption)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text("Completions:")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                        
                        Text("\(metric.completions)")
                            .font(.brandCaption)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    
                    ProgressView(value: Double(metric.completions) / Double(metric.enrollments))
                        .tint(.forgeTeal)
                    
                    HStack {
                        Text("Success Rate:")
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                        
                        Text("\(metric.successRate)%")
                            .font(.brandCaption)
                            .foregroundColor(.successGreen)
                        
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 250)
    }
}

// MARK: - Outcome Row
struct OutcomeRow: View {
    let outcome: OutcomeData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(outcome.metric)
                    .font(.brandBody)
                    .foregroundColor(.textPrimary)
                
                HStack(spacing: 8) {
                    Text("Target: \(outcome.target)")
                        .font(.brandTiny)
                        .foregroundColor(.textSecondary)
                    
                    Text("Achieved: \(outcome.achieved)")
                        .font(.brandTiny)
                        .foregroundColor(outcome.achieved >= outcome.target ? .successGreen : .warningGold)
                }
            }
            
            Spacer()
            
            ProgressView(value: Double(outcome.achieved) / Double(outcome.target))
                .tint(outcome.achieved >= outcome.target ? .successGreen : .warningGold)
                .frame(width: 150)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Impact Report View
struct ImpactReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let timeframe: ReportTimeframe
    
    var body: some View {
        ArkheCard {
            VStack(spacing: 20) {
                Text("Impact Report")
                    .font(.brandTitle)
                    .foregroundColor(.textPrimary)
                
                Text("Impact reports coming soon")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
    }
}

// MARK: - Performance Report View
struct PerformanceReportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let timeframe: ReportTimeframe
    
    var body: some View {
        ArkheCard {
            VStack(spacing: 20) {
                Text("Performance Report")
                    .font(.brandTitle)
                    .foregroundColor(.textPrimary)
                
                Text("Performance reports coming soon")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
    }
}

// MARK: - Custom Report View
struct CustomReportView: View {
    var body: some View {
        ArkheCard {
            VStack(spacing: 20) {
                Text("Custom Report Builder")
                    .font(.brandTitle)
                    .foregroundColor(.textPrimary)
                
                Text("Custom report builder coming soon")
                    .font(.brandBody)
                    .foregroundColor(.textSecondary)
            }
            .padding()
        }
    }
}

// MARK: - Report List ViewModel
class ReportListViewModel: ObservableObject {
    // Placeholder for future implementation
}

// MARK: - Preview
#Preview {
    ReportListView()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
}