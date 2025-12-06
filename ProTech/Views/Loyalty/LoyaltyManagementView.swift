//
//  LoyaltyManagementView.swift
//  ProTech
//
//  Admin view for managing loyalty program
//

import SwiftUI
import CoreData

struct LoyaltyManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: LoyaltyManagementTab = .overview
    @State private var program: LoyaltyProgram?
    @State private var showingProgramSetup = false
    
    var body: some View {
        NavigationStack {
            Group {
                if program == nil {
                    // No program exists - show setup
                    emptyState
                } else {
                    // Program exists - show management interface
                    VStack(spacing: 0) {
                        // Tab picker
                        Picker("View", selection: $selectedTab) {
                            ForEach(LoyaltyManagementTab.allCases, id: \.self) { tab in
                                Label(tab.title, systemImage: tab.icon).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        // Tab content
                        TabView(selection: $selectedTab) {
                            ForEach(LoyaltyManagementTab.allCases, id: \.self) { tab in
                                Group {
                                    switch tab {
                                    case .overview:
                                        LoyaltyOverviewTab(program: program!)
                                    case .tiers:
                                        LoyaltyTiersTab(program: program!)
                                    case .rewards:
                                        LoyaltyRewardsTab(program: program!)
                                    case .members:
                                        LoyaltyMembersTab()
                                    case .settings:
                                        LoyaltySettingsTab(program: program!)
                                    }
                                }
                                .tag(tab)
                            }
                        }
                        .tabViewStyle(.automatic)
                    }
                }
            }
            .navigationTitle("Loyalty Program")
            .onAppear {
                loadProgram()
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("No Loyalty Program Yet")
                    .font(AppTheme.Typography.title)
                    .bold()
                
                Text("Create a loyalty program to reward your customers and increase repeat business")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            
            Button {
                createProgram()
            } label: {
                Label("Create Loyalty Program", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
                    .padding()
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadProgram() {
        program = LoyaltyService.shared.getActiveProgram()
    }
    
    private func createProgram() {
        program = LoyaltyService.shared.createDefaultProgram()
    }
}

// MARK: - Loyalty Management Tabs

enum LoyaltyManagementTab: String, CaseIterable {
    case overview = "Overview"
    case tiers = "Tiers"
    case rewards = "Rewards"
    case members = "Members"
    case settings = "Settings"
    
    var title: String {
        self.rawValue
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .tiers: return "rosette"
        case .rewards: return "gift.fill"
        case .members: return "person.3.fill"
        case .settings: return "gear"
        }
    }
}

// MARK: - Overview Tab

struct LoyaltyOverviewTab: View {
    let program: LoyaltyProgram
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Stats cards
                let stats = LoyaltyService.shared.getLoyaltyStats()
                
                HStack(spacing: 16) {
                    LoyaltyStatCard(
                        title: "Total Members",
                        value: "\(stats.memberCount)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    LoyaltyStatCard(
                        title: "Total Points Issued",
                        value: "\(stats.totalPoints)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    LoyaltyStatCard(
                        title: "Avg Points/Member",
                        value: String(format: "%.0f", stats.avgPointsPerMember),
                        icon: "chart.bar.fill",
                        color: .green
                    )
                }
                
                // Top members
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Top Loyalty Members", systemImage: "crown.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        TopMembersList()
                    }
                }
                
                // Program info
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Program Details", systemImage: "info.circle.fill")
                            .font(.headline)
                        
                        DetailInfoRow(label: "Program Name", value: program.name ?? "ProTech Rewards", icon: "tag")
                        DetailInfoRow(label: "Points per Dollar", value: String(format: "%.1f", program.pointsPerDollar), icon: "dollarsign.circle")
                        DetailInfoRow(label: "Points per Visit", value: "\(program.pointsPerVisit)", icon: "person.wave.2")
                        DetailInfoRow(label: "Tiers Enabled", value: program.enableTiers ? "Yes" : "No", icon: "rosette")
                        DetailInfoRow(label: "Auto Notifications", value: program.enableAutoNotifications ? "Yes" : "No", icon: "bell")
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Supporting Views

struct LoyaltyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(AppTheme.Typography.title)
                .bold()
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
}

struct TopMembersList: View {
    @State private var topMembers: [LoyaltyMember] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if topMembers.isEmpty {
                Text("No members yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(topMembers.prefix(5).enumerated()), id: \.element.id) { index, member in
                    TopMemberRow(member: member, rank: index + 1)
                }
            }
        }
        .onAppear {
            topMembers = LoyaltyService.shared.getTopMembers(limit: 10)
        }
    }
}

struct TopMemberRow: View {
    @FetchRequest var customer: FetchedResults<Customer>
    let member: LoyaltyMember
    let rank: Int
    
    init(member: LoyaltyMember, rank: Int) {
        self.member = member
        self.rank = rank
        
        if let customerId = member.customerId {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", customerId as CVarArg)
            )
        } else {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        HStack {
            // Rank
            Text("#\(rank)")
                .font(.caption)
                .bold()
                .foregroundColor(.secondary)
                .frame(width: 30)
            
            // Customer name
            if let customer = customer.first {
                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                    .font(.subheadline)
            } else {
                Text("Unknown Customer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Points
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                Text("\(member.lifetimePoints)")
                    .font(.subheadline)
                    .bold()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LoyaltyManagementView()
        .environment(\.managedObjectContext, CoreDataManager.shared.viewContext)
}
