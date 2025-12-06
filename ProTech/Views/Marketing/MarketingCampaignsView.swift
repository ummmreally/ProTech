//
//  MarketingCampaignsView.swift
//  ProTech
//
//  Marketing campaigns dashboard
//

import SwiftUI
import Charts

struct MarketingCampaignsView: View {
    @State private var campaigns: [Campaign] = []
    @State private var searchText = ""
    @State private var filterType: String = "all"
    @State private var showingNewCampaign = false
    @State private var selectedCampaign: Campaign?
    @State private var showingCampaignDetail = false
    
    private let marketingService = MarketingService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var filteredCampaigns: [Campaign] {
        var filtered = campaigns
        
        if filterType != "all" {
            filtered = filtered.filter { $0.campaignType == filterType }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { campaign in
                campaign.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Filter bar
                filterBar
                
                Divider()
                
                // Campaigns list
                if filteredCampaigns.isEmpty {
                    emptyStateView
                } else {
                    campaignsListView
                }
            }
            .onAppear {
                loadCampaigns()
            }
            .sheet(isPresented: $showingNewCampaign) {
                CampaignBuilderView(campaign: nil)
                    .onDisappear {
                        loadCampaigns()
                    }
            }
            .sheet(isPresented: $showingCampaignDetail) {
                if let campaign = selectedCampaign {
                    CampaignDetailView(campaign: campaign)
                        .onDisappear {
                            loadCampaigns()
                        }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Marketing Campaigns")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
                
                Text("\(filteredCampaigns.count) campaign\(filteredCampaigns.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            NavigationLink(destination: SocialMediaManagerView()) {
                Label("Social Media", systemImage: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "00C853"))
                    .cornerRadius(AppTheme.buttonCornerRadius)
            }
            .buttonStyle(.plain)
            
            Button {
                showingNewCampaign = true
            } label: {
                Label("New Campaign", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    private var statisticsView: some View {
        let totalSent = campaigns.reduce(0) { $0 + Int($1.sendCount) }
        let totalOpens = campaigns.reduce(0) { $0 + Int($1.openCount) }
        let avgOpenRate = campaigns.isEmpty ? 0 : campaigns.reduce(0.0) { $0 + $1.openRate } / Double(campaigns.count)
        
        return HStack(spacing: 20) {
            MarketingStatCard(
                title: "Total Sent",
                value: "\(totalSent)",
                color: .blue
            )
            
            MarketingStatCard(
                title: "Opens",
                value: "\(totalOpens)",
                color: .green
            )
            
            MarketingStatCard(
                title: "Avg Open Rate",
                value: String(format: "%.1f%%", avgOpenRate),
                color: .purple
            )
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search campaigns...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground.opacity(0.5))
            .cornerRadius(AppTheme.cardCornerRadius)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Filter
            Picker("Type", selection: $filterType) {
                Text("All Types").tag("all")
                Text("Review Requests").tag("review_request")
                Text("Follow-ups").tag("follow_up")
                Text("Birthdays").tag("birthday")
                Text("Re-engagement").tag("re_engagement")
            }
            .pickerStyle(.segmented)
            .frame(width: 500)
        }
        .padding()
    }
    
    // MARK: - Campaigns List
    
    private var campaignsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredCampaigns, id: \.id) { campaign in
                    CampaignRow(campaign: campaign)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCampaign = campaign
                            showingCampaignDetail = true
                        }
                        .contextMenu {
                            campaignContextMenu(for: campaign)
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Campaigns")
                .font(AppTheme.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Create automated email campaigns to engage customers")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingNewCampaign = true
            } label: {
                Label("Create Campaign", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func campaignContextMenu(for campaign: Campaign) -> some View {
        Button {
            selectedCampaign = campaign
            showingCampaignDetail = true
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        if campaign.status == "draft" || campaign.status == "paused" {
            Button {
                marketingService.activateCampaign(campaign)
                loadCampaigns()
            } label: {
                Label("Activate", systemImage: "play.fill")
            }
        }
        
        if campaign.status == "active" {
            Button {
                marketingService.pauseCampaign(campaign)
                loadCampaigns()
            } label: {
                Label("Pause", systemImage: "pause.fill")
            }
        }
        
        Button(role: .destructive) {
            marketingService.deleteCampaign(campaign)
            loadCampaigns()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func loadCampaigns() {
        let request = Campaign.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        campaigns = (try? coreDataManager.viewContext.fetch(request)) ?? []
    }
}

// MARK: - Campaign Row

struct CampaignRow: View {
    let campaign: Campaign
    
    var body: some View {
        HStack(spacing: 16) {
            // Type icon
            Image(systemName: typeIcon)
                .font(.title2)
                .foregroundColor(typeColor)
                .frame(width: 40)
            
            // Campaign details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(campaign.name ?? "Untitled")
                        .font(.headline)
                    
                    Text(campaign.typeDisplay)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(typeColor.opacity(0.2))
                        .foregroundColor(typeColor)
                        .cornerRadius(4)
                }
                
                HStack(spacing: 12) {
                    Label("\(campaign.sendCount) sent", systemImage: "paperplane")
                        .font(.caption)
                    
                    if campaign.sendCount > 0 {
                        Text("•")
                        Label(String(format: "%.1f%% opened", campaign.openRate), systemImage: "envelope.open")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status badge
            Text(campaign.statusDisplay)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(6)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var typeIcon: String {
        switch campaign.campaignType {
        case "review_request": return "star.fill"
        case "follow_up": return "arrow.right.circle.fill"
        case "birthday": return "gift.fill"
        case "re_engagement": return "arrow.clockwise.circle.fill"
        default: return "envelope.fill"
        }
    }
    
    private var typeColor: Color {
        switch campaign.campaignType {
        case "review_request": return .yellow
        case "follow_up": return .blue
        case "birthday": return .pink
        case "re_engagement": return .purple
        default: return .gray
        }
    }
    
    private var statusColor: Color {
        switch campaign.status {
        case "active": return .green
        case "paused": return .orange
        case "completed": return .blue
        case "draft": return .gray
        default: return .gray
        }
    }
}

struct MarketingStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
}

// MARK: - Campaign Detail View

struct CampaignDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let campaign: Campaign
    
    @State private var showingEdit = false
    
    private let marketingService = MarketingService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Status and actions
                    statusCard
                    
                    Divider()
                    
                    // Performance metrics
                    metricsCard
                    
                    Divider()
                    
                    // Email content
                    contentCard
                    
                    Divider()
                    
                    // Settings
                    settingsCard
                }
                .padding()
            }
            .navigationTitle(campaign.name ?? "Campaign")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEdit = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                }
            }
        }
        .frame(width: 700, height: 650)
        .sheet(isPresented: $showingEdit) {
            CampaignBuilderView(campaign: campaign)
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Status")
                    .font(.headline)
                Spacer()
                Text(campaign.statusDisplay)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            }
            
            if let lastRun = campaign.lastRunDate {
                Text("Last run: \(lastRun.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetricCard(
                    title: "Sent",
                    value: "\(campaign.sendCount)",
                    subtitle: "emails delivered",
                    color: .blue,
                    icon: "paperplane.fill"
                )
                
                MetricCard(
                    title: "Opened",
                    value: "\(campaign.openCount)",
                    subtitle: String(format: "%.1f%% open rate", campaign.openRate),
                    color: .green,
                    icon: "envelope.open.fill"
                )
                
                MetricCard(
                    title: "Clicked",
                    value: "\(campaign.clickCount)",
                    subtitle: String(format: "%.1f%% click rate", campaign.clickRate),
                    color: .purple,
                    icon: "hand.tap.fill"
                )
            }
        }
    }
    
    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Email Content")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Subject")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(campaign.emailSubject ?? "")
                    .font(.body)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Body")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(campaign.emailBody ?? "")
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
            
            LabeledContent("Type", value: campaign.typeDisplay)
            LabeledContent("Target", value: campaign.targetSegment?.capitalized ?? "All")
            LabeledContent("Send Timing", value: "\(campaign.daysAfterEvent) days after event")
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}
