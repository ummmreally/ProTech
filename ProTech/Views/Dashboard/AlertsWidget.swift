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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("Requires Attention")
                    .font(.headline)
                
                if !alerts.isEmpty {
                    Text("(\(alerts.count))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if alerts.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("All Clear!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("No action items require attention")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Alert List
                VStack(spacing: 8) {
                    ForEach(alerts) { alert in
                        AlertRow(alert: alert)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
        HStack(spacing: 12) {
            // Severity Indicator
            Circle()
                .fill(alert.severity.iconColor)
                .frame(width: 8, height: 8)
            
            // Alert Icon
            Image(systemName: alert.icon)
                .foregroundColor(alert.severity.color)
                .frame(width: 24)
            
            // Alert Content
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.title)
                    .font(.subheadline)
                    .bold()
                Text(alert.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Button
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(alert.severity.color.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(alert.severity.color.opacity(0.2), lineWidth: 1)
        )
    }
}
