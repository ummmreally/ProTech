//
//  ProductivityReportView.swift
//  ProTech
//
//  Productivity analytics and reports
//

import SwiftUI
import Charts

struct ProductivityReportView: View {
    @State private var selectedDateRange: DateRangeOption = .thisWeek
    @State private var stats: ProductivityStats?
    @State private var dailyData: [DailyProductivity] = []
    
    private let timeTrackingService = TimeTrackingService.shared
    
    enum DateRangeOption: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case last30Days = "Last 30 Days"
    }
    
    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedDateRange {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)
        case .thisWeek:
            let start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start)!
            return (start, end)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            return (start, end)
        case .last30Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return (start, end)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Date range selector
                dateRangeSelector
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Key metrics
                        if let stats = stats {
                            keyMetricsView(stats: stats)
                        }
                        
                        Divider()
                        
                        // Daily breakdown chart
                        if !dailyData.isEmpty {
                            dailyBreakdownChart
                        }
                        
                        Divider()
                        
                        // Insights
                        if let stats = stats {
                            insightsView(stats: stats)
                        }
                    }
                    .padding()
                }
            }
            .onAppear {
                loadData()
            }
            .onChange(of: selectedDateRange) { _, _ in
                loadData()
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Productivity Report")
                    .font(AppTheme.Typography.largeTitle)
                    .fontWeight(.bold)
                
                Text(dateRangeText)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: dateRange.start)) - \(formatter.string(from: dateRange.end))"
    }
    
    // MARK: - Date Range Selector
    
    private var dateRangeSelector: some View {
        HStack {
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRangeOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 500)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
    }
    
    // MARK: - Key Metrics
    
    private func keyMetricsView(stats: ProductivityStats) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Overview")
                .font(AppTheme.Typography.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                MetricCard(
                    title: "Total Hours",
                    value: String(format: "%.1f", stats.totalHours),
                    subtitle: "hours tracked",
                    color: .blue,
                    icon: "clock.fill"
                )
                
                MetricCard(
                    title: "Billable Hours",
                    value: String(format: "%.1f", stats.billableHours),
                    subtitle: String(format: "%.0f%% of total", stats.billablePercentage),
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Revenue",
                    value: stats.formattedTotalRevenue,
                    subtitle: "from billable hours",
                    color: .purple,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MetricCard(
                    title: "Tickets",
                    value: "\(stats.ticketCount)",
                    subtitle: "worked on",
                    color: .orange,
                    icon: "ticket.fill"
                )
                
                MetricCard(
                    title: "Avg per Ticket",
                    value: String(format: "%.1fh", stats.averageHoursPerTicket),
                    subtitle: "average time",
                    color: .indigo,
                    icon: "chart.bar.fill"
                )
                
                MetricCard(
                    title: "Non-Billable",
                    value: String(format: "%.1f", stats.nonBillableHours),
                    subtitle: "hours",
                    color: .red,
                    icon: "xmark.circle.fill"
                )
            }
        }
    }
    
    // MARK: - Daily Breakdown Chart
    
    private var dailyBreakdownChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Daily Breakdown")
                .font(AppTheme.Typography.headline)
            
            Chart(dailyData) { data in
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Hours", data.hours)
                )
                .foregroundStyle(AppTheme.Colors.primary)
                
                BarMark(
                    x: .value("Date", data.date, unit: .day),
                    y: .value("Billable", data.billableHours)
                )
                .foregroundStyle(Color.green)
            }
            .frame(height: 250)
            .chartYAxisLabel("Hours")
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            
            // Legend
            HStack(spacing: 24) {
                Label("Total Hours", systemImage: "square.fill")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(AppTheme.Typography.caption)
                
                Label("Billable Hours", systemImage: "square.fill")
                    .foregroundColor(.green)
                    .font(AppTheme.Typography.caption)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .glassCard()
    }
    
    // MARK: - Insights
    
    private func insightsView(stats: ProductivityStats) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Insights")
                .font(AppTheme.Typography.headline)
            
            VStack(spacing: AppTheme.Spacing.md) {
                if stats.billablePercentage >= 80 {
                    InsightCard(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Excellent Billable Ratio",
                        message: "You're billing \(String(format: "%.0f%%", stats.billablePercentage)) of your time. Keep it up!"
                    )
                } else if stats.billablePercentage >= 60 {
                    InsightCard(
                        icon: "checkmark.circle",
                        color: .orange,
                        title: "Good Billable Ratio",
                        message: "You're billing \(String(format: "%.0f%%", stats.billablePercentage)) of your time. Try to reduce non-billable tasks."
                    )
                } else {
                    InsightCard(
                        icon: "exclamationmark.triangle.fill",
                        color: .red,
                        title: "Low Billable Ratio",
                        message: "Only \(String(format: "%.0f%%", stats.billablePercentage)) of your time is billable. Focus on revenue-generating work."
                    )
                }
                
                if stats.averageHoursPerTicket > 4 {
                    InsightCard(
                        icon: "clock.badge.exclamationmark",
                        color: .orange,
                        title: "High Average Time",
                        message: "Tickets are taking \(String(format: "%.1f", stats.averageHoursPerTicket)) hours on average. Consider improving efficiency."
                    )
                }
                
                if stats.totalHours > 40 {
                    InsightCard(
                        icon: "flame.fill",
                        color: .purple,
                        title: "High Productivity",
                        message: "You've logged \(String(format: "%.1f", stats.totalHours)) hours. Great work ethic!"
                    )
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        // Note: In real implementation, you'd fetch technician ID from user session
        let dummyTechnicianId = UUID()
        
        stats = timeTrackingService.getProductivityStats(
            for: dummyTechnicianId,
            from: dateRange.start,
            to: dateRange.end
        )
        
        loadDailyData()
    }
    
    private func loadDailyData() {
        let calendar = Calendar.current
        var currentDate = dateRange.start
        var data: [DailyProductivity] = []
        
        while currentDate < dateRange.end {
            let entries = timeTrackingService.getDailyTimeEntries(for: currentDate)
            let totalHours = entries.reduce(0.0) { $0 + $1.duration / 3600.0 }
            let billableHours = entries.filter { $0.isBillable }.reduce(0.0) { $0 + $1.duration / 3600.0 }
            
            data.append(DailyProductivity(
                date: currentDate,
                hours: totalHours,
                billableHours: billableHours
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        dailyData = data
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(subtitle)
                    .font(AppTheme.Typography.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .glassCard()
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let icon: String
    let color: Color
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppTheme.Typography.subheadline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .glassCard()
    }
}

// MARK: - Daily Productivity Data

struct DailyProductivity: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
    let billableHours: Double
}
