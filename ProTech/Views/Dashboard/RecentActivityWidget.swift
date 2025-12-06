//
//  RecentActivityWidget.swift
//  ProTech
//
//  Recent business activity feed widget
//

import SwiftUI

struct RecentActivityWidget: View {
    @State private var activities: [ActivityItem] = []
    
    private let metricsService = DashboardMetricsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(AppTheme.Typography.headline)
                Spacer()
            }
            
            if activities.isEmpty {
                // Empty State
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Recent Activity")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Activity List
                VStack(spacing: 0) {
                    ForEach(activities) { activity in
                        DashboardActivityRow(activity: activity)
                        
                        if activity.id != activities.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(AppTheme.Colors.cardBackground.opacity(0.5))
                .cornerRadius(AppTheme.cardCornerRadius)
            }
        }
        .glassCard()
        .task {
            await loadActivity()
        }
    }
    
    private func loadActivity() async {
        await MainActor.run {
            activities = metricsService.getRecentActivity(limit: 8)
        }
    }
}

private struct DashboardActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: activity.icon)
                    .font(.system(size: 14))
                    .foregroundColor(activity.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(activity.title)
                    .font(AppTheme.Typography.subheadline)
                if let subtitle = activity.subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Timestamp
            Text(activity.timeAgo)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 10)
    }
}
