//
//  AlertsWidget.swift
//  ProTech
//
//  Critical alerts and action items widget
//

import SwiftUI

struct AlertsWidget: View {
    @State private var alerts: [DashboardAlert] = []
    
    private let metricsService = DashboardMetricsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Requires Attention")
                    .font(AppTheme.Typography.headline)
                
                if !alerts.isEmpty {
                    Text("(\(alerts.count))")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if alerts.isEmpty {
                // Empty State
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("All Clear!")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                    Text("No action items require attention")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Alert List
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(alerts) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
        }
        .glassCard()
        .task {
            await loadAlerts()
        }
    }
    
    private func loadAlerts() async {
        await MainActor.run {
            alerts = metricsService.getCriticalAlerts()
        }
    }
}

struct AlertRow: View {
    let alert: DashboardAlert
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Severity Indicator
            Circle()
                .fill(alert.severity.iconColor)
                .frame(width: 8, height: 8)
            
            // Alert Icon
            Image(systemName: alert.icon)
                .foregroundColor(alert.severity.color)
                .frame(width: 24)
            
            // Alert Content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(alert.title)
                    .font(AppTheme.Typography.subheadline)
                    .bold()
                Text(alert.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(alert.severity.color.opacity(0.06))
        .cornerRadius(AppTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(alert.severity.color.opacity(0.2), lineWidth: 1)
        )
    }
}
