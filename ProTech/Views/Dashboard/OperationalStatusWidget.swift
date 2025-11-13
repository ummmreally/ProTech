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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Operational Status")
                    .font(.headline)
                Spacer()
            }
            
            // Active Repairs Summary
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE REPAIRS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(activeRepairs)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Status Breakdown
                VStack(alignment: .trailing, spacing: 6) {
                    DashboardStatusBadge(label: "Waiting", count: repairsByStatus["waiting"] ?? 0, color: .orange)
                    DashboardStatusBadge(label: "In Progress", count: repairsByStatus["in_progress"] ?? 0, color: .blue)
                    DashboardStatusBadge(label: "Completed", count: repairsByStatus["completed"] ?? 0, color: .green)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Action Items Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(count)")
                .font(.caption)
                .bold()
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(4)
        }
    }
}

struct ActionItemCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text("\(count)")
                .font(.title2)
                .bold()
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
