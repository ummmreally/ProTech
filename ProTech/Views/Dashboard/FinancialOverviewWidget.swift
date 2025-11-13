//
//  FinancialOverviewWidget.swift
//  ProTech
//
//  Financial metrics overview widget
//

import SwiftUI

struct FinancialOverviewWidget: View {
    @State private var todayRevenue: Decimal = 0
    @State private var weekRevenue: Decimal = 0
    @State private var monthRevenue: Decimal = 0
    @State private var outstandingBalance: Decimal = 0
    @State private var averageTicketValue: Decimal = 0
    @State private var revenueGrowth: Double = 0
    
    private let metricsService = DashboardMetricsService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Financial Overview")
                    .font(.headline)
                Spacer()
            }
            
            // Revenue Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                FinancialMetricCard(
                    title: "Today",
                    value: formatCurrency(todayRevenue),
                    icon: "calendar.circle.fill",
                    color: .green
                )
                
                FinancialMetricCard(
                    title: "This Week",
                    value: formatCurrency(weekRevenue),
                    icon: "calendar.badge.clock",
                    color: .blue
                )
                
                FinancialMetricCard(
                    title: "This Month",
                    value: formatCurrency(monthRevenue),
                    icon: "chart.bar.fill",
                    color: .purple,
                    badge: revenueGrowth != 0 ? formatGrowth(revenueGrowth) : nil,
                    badgeColor: revenueGrowth >= 0 ? .green : .red
                )
                
                FinancialMetricCard(
                    title: "Outstanding",
                    value: formatCurrency(outstandingBalance),
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            
            // Average Ticket Value
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Ticket Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(averageTicketValue))
                        .font(.title3)
                        .bold()
                }
                Spacer()
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .task {
            await loadData()
        }
    }
    
    private func loadData() async {
        await MainActor.run {
            todayRevenue = metricsService.getTodayRevenue()
            weekRevenue = metricsService.getWeekRevenue()
            monthRevenue = metricsService.getMonthRevenue()
            outstandingBalance = metricsService.getOutstandingBalance()
            averageTicketValue = metricsService.getAverageTicketValue()
            revenueGrowth = metricsService.getRevenueGrowth()
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        return formatter.string(from: value as NSDecimalNumber) ?? "$0"
    }
    
    private func formatGrowth(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : ""
        return String(format: "\(sign)%.1f%%", value)
    }
}

struct FinancialMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var badge: String? = nil
    var badgeColor: Color = .green
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                if let badge = badge {
                    Text(badge)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(badgeColor.opacity(0.2))
                        .foregroundColor(badgeColor)
                        .cornerRadius(4)
                }
            }
            
            Text(value)
                .font(.title2)
                .bold()
            
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
