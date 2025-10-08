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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }
            
            if activities.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Recent Activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Activity List
                VStack(spacing: 0) {
                    ForEach(activities) { activity in
                        ActivityRow(activity: activity)
                        
                        if activity.id != activities.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(Color.white.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadActivity()
        }
    }
    
    private func loadActivity() {
        activities = metricsService.getRecentActivity(limit: 8)
    }
}

struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 28)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                if let subtitle = activity.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Timestamp
            Text(activity.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
