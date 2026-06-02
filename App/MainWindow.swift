import SwiftUI

// MARK: - Main Window
struct MainWindow: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @State private var selectedTab: AppTab = .dashboard
    @State private var sidebarWidth: CGFloat = 250
    @State private var isSidebarVisible = true
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            if isSidebarVisible {
                SidebarView(selectedTab: $selectedTab, currentUser: authManager.currentUser)
                    .frame(minWidth: 200, idealWidth: sidebarWidth, maxWidth: 300)
            }
        } detail: {
            // Main Content
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .clients:
                    ClientListView()
                case .programs:
                    ProgramListView()
                case .safety:
                    SafetyDashboardView()
                case .tasks:
                    TaskListView()
                case .calendar:
                    CalendarView()
                case .referrals:
                    ReferralListView()
                case .reports:
                    ReportListView()
                case .volunteers:
                    VolunteerListView()
                case .safeHouses:
                    SafeHouseListView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.deepCharcoal)
            .navigationTitle(selectedTab.title)
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        withAnimation {
                            isSidebarVisible.toggle()
                        }
                    }) {
                        Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 8) {
                        if let user = authManager.currentUser {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color.forgeTeal)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(user.firstName.prefix(1)))
                                            .font(.brandBodyBold)
                                            .foregroundColor(.warmIvory)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(user.fullName)
                                        .font(.brandCaption)
                                        .foregroundColor(.textPrimary)
                                    Text(user.role?.capitalized ?? "Staff")
                                        .font(.brandTiny)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.lightCharcoal)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            Image(systemName: "power")
                                .foregroundColor(.dangerRed)
                        }
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
    }
}

// MARK: - Sidebar View
struct SidebarView: View {
    @Binding var selectedTab: AppTab
    let currentUser: Staff?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Logo
                    ForgeLogo(size: .compact, style: .iconOnly)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(BrandSystem.appName)
                            .font(.brandSubheading)
                            .foregroundColor(.textPrimary)
                        Text(BrandSystem.tagline)
                            .font(.brandTiny)
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                
                Divider()
                    .background(Color.lightCharcoal)
            }
            
            // Navigation Items
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        SidebarItem(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            withAnimation {
                                selectedTab = tab
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // User Info
            if let user = currentUser {
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.lightCharcoal)
                    
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.bronze)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(user.firstName.prefix(1)))
                                    .font(.brandBodyBold)
                                    .foregroundColor(.warmIvory)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.fullName)
                                .font(.brandCaption)
                                .foregroundColor(.textPrimary)
                            Text(user.role?.capitalized ?? "Staff")
                                .font(.brandTiny)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(Color.darkCharcoal)
    }
}

// MARK: - Sidebar Item
struct SidebarItem: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .forgeTeal : .textSecondary)
                    .frame(width: 20)
                
                Text(tab.title)
                    .font(.brandBody)
                    .foregroundColor(isSelected ? .forgeTeal : .textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.forgeTeal.opacity(0.1) : Color.clear)
            .overlay(
                Rectangle()
                    .fill(Color.forgeTeal)
                    .frame(width: 3),
                alignment: .leading
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - App Tabs
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case clients = "Clients"
    case programs = "Programs"
    case safety = "Safety"
    case tasks = "Tasks"
    case calendar = "Calendar"
    case referrals = "Referrals"
    case reports = "Reports"
    case volunteers = "Volunteers"
    case safeHouses = "Safe Houses"
    case settings = "Settings"
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .clients: return "person.2.fill"
        case .programs: return "star.fill"
        case .safety: return "shield.fill"
        case .tasks: return "checkmark.circle.fill"
        case .calendar: return "calendar"
        case .referrals: return "arrow.right.arrow.left"
        case .reports: return "doc.text.fill"
        case .volunteers: return "hand.raised.fill"
        case .safeHouses: return "house.fill"
        case .settings: return "gear"
        }
    }
    
    var title: String {
        rawValue
    }
}

// MARK: - Placeholder Views (to be implemented)
struct DashboardView: View {
    var body: some View {
        ForgeCard {
            Text("Dashboard")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Executive dashboard coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ClientListView: View {
    var body: some View {
        ForgeCard {
            Text("Client Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Client list and management coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ProgramListView: View {
    var body: some View {
        ForgeCard {
            Text("Program Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Program administration coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct SafetyDashboardView: View {
    var body: some View {
        ForgeCard {
            Text("Safety Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Safety flags and risk assessment coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct TaskListView: View {
    var body: some View {
        ForgeCard {
            Text("Task Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Task tracking and work queues coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct CalendarView: View {
    var body: some View {
        ForgeCard {
            Text("Calendar")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Appointment scheduling coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ReferralListView: View {
    var body: some View {
        ForgeCard {
            Text("Referral Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Partner directory and referrals coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct ReportListView: View {
    var body: some View {
        ForgeCard {
            Text("Reports & Analytics")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Grant reporting and analytics coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct VolunteerListView: View {
    var body: some View {
        ForgeCard {
            Text("Volunteer Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Volunteer profiles and assignments coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct SafeHouseListView: View {
    var body: some View {
        ForgeCard {
            Text("Safe House Management")
                .font(.brandHeading)
                .foregroundColor(.textPrimary)
            Text("Safe house placement tracking coming soon")
                .font(.brandBody)
                .foregroundColor(.textSecondary)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                SectionHeader(title: "Account Settings")
                
                ForgeCard {
                    VStack(alignment: .leading, spacing: 16) {
                        if let user = authManager.currentUser {
                            InfoRow(icon: "person.fill", title: "Name", value: user.fullName)
                            InfoRow(icon: "envelope.fill", title: "Email", value: user.email)
                            InfoRow(icon: "briefcase.fill", title: "Role", value: user.role?.capitalized ?? "Staff")
                        }
                    }
                }
                
                SectionHeader(title: "Application Settings")
                
                ForgeCard {
                    Text("Additional settings coming soon")
                        .font(.brandBody)
                        .foregroundColor(.textSecondary)
                }
                
                ForgeButton(
                    title: "Sign Out",
                    style: .danger
                ) {
                    authManager.logout()
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
#Preview {
    MainWindow()
        .environment(\.managedObjectContext, CoreDataController.preview.container.viewContext)
        .environmentObject(AuthenticationManager.shared)
}