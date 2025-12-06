//
//  OperationalStatusWidget.swift
//  ProTech
//
//  Operational metrics overview widget
//

import SwiftUI

struct OperationalStatusWidget: View {
    @State private var activeRepairs: Int = 0
    @State private var repairsByStatus: [String: Int] = [:]
    @State private var pendingEstimates: Int = 0
    @State private var unpaidInvoices: Int = 0
    @State private var overdueRepairs: Int = 0
    @State private var todayPickups: Int = 0
    
    private let metricsService = DashboardMetricsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Operational Status")
                    .font(AppTheme.Typography.headline)
                Spacer()
            }
            
            // Active Repairs Summary
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("ACTIVE REPAIRS")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                    Text("\(activeRepairs)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Status Breakdown
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.sm) {
                    DashboardStatusBadge(label: "Waiting", count: repairsByStatus["waiting"] ?? 0, color: .orange)
                    DashboardStatusBadge(label: "In Progress", count: repairsByStatus["in_progress"] ?? 0, color: .blue)
                    DashboardStatusBadge(label: "Completed", count: repairsByStatus["completed"] ?? 0, color: .green)
                }
            }
            .padding()
            .background(AppTheme.Colors.info.opacity(0.1))
            .cornerRadius(AppTheme.cardCornerRadius)
            
            // Action Items Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                ActionItemCard(
                    title: "Overdue",
                    count: overdueRepairs,
                    icon: "clock.badge.exclamationmark.fill",
                    color: overdueRepairs > 0 ? .red : .gray
                )
                
                ActionItemCard(
                    title: "Pending Estimates",
                    count: pendingEstimates,
                    icon: "doc.plaintext",
                    color: pendingEstimates > 0 ? .orange : .gray
                )
                
                ActionItemCard(
                    title: "Unpaid Invoices",
                    count: unpaidInvoices,
                    icon: "exclamationmark.triangle.fill",
                    color: unpaidInvoices > 0 ? .red : .gray
                )
                
                ActionItemCard(
                    title: "Today's Pickups",
                    count: todayPickups,
                    icon: "checkmark.circle.fill",
                    color: todayPickups > 0 ? .green : .gray
                )
            }
        }
        .glassCard()
        .task {
            await loadData()
        }
    }
    
    func loadData() async {
        await MainActor.run {
            activeRepairs = metricsService.getActiveRepairs()
            repairsByStatus = metricsService.getRepairsByStatus()
            pendingEstimates = metricsService.getPendingEstimates()
            unpaidInvoices = metricsService.getUnpaidInvoices().count
            overdueRepairs = metricsService.getOverdueRepairs().count
            todayPickups = metricsService.getTodayPickups().count
        }
    }
}

struct DashboardStatusBadge: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(AppTheme.Typography.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .cornerRadius(6)
        }
    }
}

struct ActionItemCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                }
                Spacer()
            }
            
            Text("\(count)")
                .font(AppTheme.Typography.title2)
                .bold()
                .foregroundColor(color)
            
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(AppTheme.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}
