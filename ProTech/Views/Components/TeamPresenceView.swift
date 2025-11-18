//
//  TeamPresenceView.swift
//  ProTech
//
//  Real-time team presence and activity monitoring
//

import SwiftUI
import Combine

// MARK: - Team Member Presence

struct TeamMemberPresence: View {
    let employee: Employee
    @StateObject private var presenceMonitor = PresenceMonitor()
    @State private var isOnline = false
    @State private var lastSeen: Date?
    @State private var currentActivity: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with presence indicator
            ZStack(alignment: .bottomTrailing) {
                // Avatar
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(employee.initials)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Presence dot
                Circle()
                    .fill(presenceColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .scaleEffect(isOnline ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.3), value: isOnline)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(employee.fullName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(presenceText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let activity = currentActivity {
                        Text("• \(activity)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Role badge
            Text(employee.role ?? "")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isOnline ? Color.green.opacity(0.05) : Color.clear)
        .cornerRadius(8)
        .onAppear {
            if let employeeId = employee.id {
                presenceMonitor.startMonitoring(employeeId: employeeId)
            }
        }
        .onDisappear {
            presenceMonitor.stopMonitoring()
        }
        .onChange(of: presenceMonitor.isOnline) { _, newValue in
            isOnline = newValue
        }
        .onChange(of: presenceMonitor.lastActivity) { _, newValue in
            currentActivity = newValue
        }
    }
    
    private var presenceColor: Color {
        if isOnline {
            return .green
        } else if let lastSeen = lastSeen,
                  Date().timeIntervalSince(lastSeen) < 300 { // Within 5 minutes
            return .orange
        } else {
            return .gray
        }
    }
    
    private var presenceText: String {
        if isOnline {
            return "Online"
        } else if let lastSeen = lastSeen {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return "Seen \(formatter.localizedString(for: lastSeen, relativeTo: Date()))"
        } else {
            return "Offline"
        }
    }
}

// MARK: - Team Dashboard

struct TeamDashboard: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Employee.isActive, ascending: false),
            NSSortDescriptor(keyPath: \Employee.lastName, ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == true")
    )
    private var employees: FetchedResults<Employee>
    
    @StateObject private var teamPresence = TeamPresenceManager()
    @State private var selectedFilter: TeamFilter = .all
    @State private var searchText = ""
    
    enum TeamFilter: String, CaseIterable {
        case all = "All"
        case online = "Online"
        case managers = "Managers"
        case technicians = "Technicians"
        
        var icon: String {
            switch self {
            case .all: return "person.3"
            case .online: return "wifi"
            case .managers: return "star"
            case .technicians: return "wrench"
            }
        }
    }
    
    var filteredEmployees: [Employee] {
        employees.filter { employee in
            // Search filter
            if !searchText.isEmpty {
                let searchLower = searchText.lowercased()
                let matchesName = employee.fullName.lowercased().contains(searchLower)
                let matchesEmail = employee.email?.lowercased().contains(searchLower) ?? false
                if !matchesName && !matchesEmail {
                    return false
                }
            }
            
            // Team filter
            switch selectedFilter {
            case .all:
                return true
            case .online:
                return employee.id.map { teamPresence.onlineEmployees.contains($0) } ?? false
            case .managers:
                return ["admin", "manager"].contains(employee.role ?? "")
            case .technicians:
                return employee.role == "technician"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Team")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Online count
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("\(teamPresence.onlineCount) online")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Search and filters
                HStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search team...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)
                    
                    // Filters
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(TeamFilter.allCases, id: \.self) { filter in
                            Label(filter.rawValue, systemImage: filter.icon)
                                .tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Team list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEmployees) { employee in
                        TeamMemberPresence(employee: employee)
                    }
                }
                .padding()
            }
        }
        .onAppear {
            teamPresence.startMonitoring()
        }
        .onDisappear {
            teamPresence.stopMonitoring()
        }
    }
}

// MARK: - Activity Feed

struct TeamActivityFeed: View {
    @State private var activities: [TeamActivity] = []
    @StateObject private var activityMonitor = ActivityMonitor()
    
    struct TeamActivity: Identifiable, Equatable {
        let id = UUID()
        let employeeName: String
        let action: String
        let timestamp: Date
        let icon: String
        let color: Color
        
        static func == (lhs: TeamActivity, rhs: TeamActivity) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Activity Feed", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                
                Spacer()
                
                if activityMonitor.isConnected {
                    LiveStatusIndicator(isLive: true)
                }
            }
            
            // Activities
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .onAppear {
            activityMonitor.startMonitoring()
        }
        .onDisappear {
            activityMonitor.stopMonitoring()
        }
        .onChange(of: activityMonitor.latestActivity) { _, newActivity in
            if let activity = newActivity {
                withAnimation {
                    activities.insert(activity, at: 0)
                    // Keep only last 50 activities
                    if activities.count > 50 {
                        activities.removeLast()
                    }
                }
            }
        }
    }
}

struct ActivityRow: View {
    let activity: TeamActivityFeed.TeamActivity
    @State private var isNew = true
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.icon)
                .font(.system(size: 14))
                .foregroundColor(activity.color)
                .frame(width: 24, height: 24)
                .background(activity.color.opacity(0.15))
                .cornerRadius(6)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(activity.employeeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(activity.action)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isNew {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isNew ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isNew = false
                }
            }
        }
    }
}

// MARK: - Presence Monitor

@MainActor
class PresenceMonitor: ObservableObject {
    @Published var isOnline = false
    @Published var lastSeen: Date?
    @Published var lastActivity: String?
    
    private let supabase = SupabaseService.shared
    // TODO: Uncomment when Supabase Realtime types are available
    // private var channel: RealtimeChannel?
    private var employeeId: UUID?
    private var presenceTimer: Timer?
    
    func startMonitoring(employeeId: UUID) {
        self.employeeId = employeeId
        // TODO: Implement proper Supabase Realtime presence tracking
        print("Presence monitoring not yet implemented for employee: \(employeeId)")
    }
    
    func stopMonitoring() {
        presenceTimer?.invalidate()
        presenceTimer = nil
    }
}

// MARK: - Team Presence Manager

@MainActor
class TeamPresenceManager: ObservableObject {
    @Published var onlineEmployees: Set<UUID> = []
    @Published var onlineCount: Int = 0
    
    private let supabase = SupabaseService.shared
    // TODO: Uncomment when Supabase Realtime types are available
    // private var channel: RealtimeChannel?
    
    func startMonitoring() {
        // TODO: Implement proper Supabase Realtime presence tracking
        print("Team presence monitoring not yet implemented")
    }
    
    func stopMonitoring() {
        // TODO: Implement when realtime is available
    }
}

// MARK: - Activity Monitor

@MainActor
class ActivityMonitor: ObservableObject {
    @Published var latestActivity: TeamActivityFeed.TeamActivity?
    @Published var isConnected = false
    
    private let supabase = SupabaseService.shared
    // TODO: Uncomment when Supabase Realtime types are available
    // private var channel: RealtimeChannel?
    
    func startMonitoring() {
        // TODO: Implement proper Supabase Realtime activity monitoring
        print("Activity monitoring not yet implemented")
    }
    
    func stopMonitoring() {
        // TODO: Implement when realtime is available
        isConnected = false
    }
}

// Employee extensions (fullName, initials) are now defined in Employee.swift

#Preview {
    TeamDashboard()
}
