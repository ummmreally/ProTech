//
//  ReportsView.swift
//  ProTech
//
//  Analytics and reports view
//

import SwiftUI
import Charts

struct ReportsView: View {
    @State private var selectedDateRange: DateRangeOption = .thisMonth
    @State private var selectedReportType: ReportType = .revenue
    @State private var showingExport = false
    
    private let reportingService = ReportingService.shared
    
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
        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        case .last30Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -30, to: end)!
            return (start, end)
        case .last90Days:
            let end = now
            let start = calendar.date(byAdding: .day, value: -90, to: end)!
            return (start, end)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Controls
                controlsView
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Key Metrics
                        keyMetricsView
                        
                        Divider()
                        
                        // Main Chart
                        mainChartView
                        
                        Divider()
                        
                        // Detailed Reports
                        detailedReportsView
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportReportView(
                    reportType: selectedReportType,
                    startDate: dateRange.start,
                    endDate: dateRange.end
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reports & Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Business insights and performance metrics")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: { printReport() }) {
                Label("Print", systemImage: "printer")
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingExport = true }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    // MARK: - Controls
    
    private var controlsView: some View {
        HStack {
            Picker("Date Range", selection: $selectedDateRange) {
                ForEach(DateRangeOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            
            Spacer()
            
            Picker("Report Type", selection: $selectedReportType) {
                ForEach(ReportType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 600)
        }
        .padding()
    }
    
    // MARK: - Key Metrics
    
    private var keyMetricsView: some View {
        let revenue = reportingService.getRevenue(from: dateRange.start, to: dateRange.end)
        let invoiceStats = reportingService.getInvoiceStats(from: dateRange.start, to: dateRange.end)
        let ticketStats = reportingService.getTicketStats(from: dateRange.start, to: dateRange.end)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Key Metrics")
                .font(.headline)
            
            HStack(spacing: 16) {
                MetricCard(
                    title: "Total Revenue",
                    value: formatCurrency(revenue),
                    subtitle: "This period",
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                MetricCard(
                    title: "Invoices",
                    value: "\(invoiceStats.totalInvoices)",
                    subtitle: "\(invoiceStats.paidInvoices) paid",
                    color: .blue,
                    icon: "doc.text.fill"
                )
                
                MetricCard(
                    title: "Tickets",
                    value: "\(ticketStats.totalTickets)",
                    subtitle: "\(ticketStats.completedTickets) completed",
                    color: .purple,
                    icon: "ticket.fill"
                )
                
                MetricCard(
                    title: "Avg Turnaround",
                    value: String(format: "%.1f hrs", ticketStats.averageTurnaroundHours),
                    subtitle: "Average per ticket",
                    color: .orange,
                    icon: "clock.fill"
                )
            }
        }
    }
    
    // MARK: - Main Chart
    
    private var mainChartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Trend")
                .font(.headline)
            
            let dailyRevenue = reportingService.getDailyRevenue(from: dateRange.start, to: dateRange.end)
            
            if dailyRevenue.isEmpty {
                Text("No data available for this period")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
            } else {
                Chart {
                    ForEach(Array(dailyRevenue.enumerated()), id: \.offset) { _, item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Revenue", NSDecimalNumber(decimal: item.amount).doubleValue)
                        )
                        .foregroundStyle(.green)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Revenue", NSDecimalNumber(decimal: item.amount).doubleValue)
                        )
                        .foregroundStyle(.green.opacity(0.2))
                    }
                }
                .frame(height: 250)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 7))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }
    
    // MARK: - Detailed Reports
    
    private var detailedReportsView: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Payment Methods
            paymentMethodsBreakdown
            
            // Top Customers
            topCustomersView
            
            // Ticket Status
            ticketStatusBreakdown
            
            // Technician Performance
            technicianLeaderboardView
        }
    }
    
    private var paymentMethodsBreakdown: some View {
        let methodRevenue = reportingService.getRevenueByPaymentMethod(from: dateRange.start, to: dateRange.end)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Revenue by Payment Method")
                .font(.headline)
            
            if methodRevenue.isEmpty {
                Text("No payment data available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(methodRevenue.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Text(item.method.capitalized)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.amount))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var topCustomersView: some View {
        let topCustomers = reportingService.getTopCustomers(limit: 5, from: dateRange.start, to: dateRange.end)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Top Customers")
                .font(.headline)
            
            if topCustomers.isEmpty {
                Text("No customer data available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(topCustomers.enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        
                        Text("\(item.customer.firstName ?? "") \(item.customer.lastName ?? "")")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.revenue))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var ticketStatusBreakdown: some View {
        let statusCounts = reportingService.getTicketsByStatus(from: dateRange.start, to: dateRange.end)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Tickets by Status")
                .font(.headline)
            
            if statusCounts.isEmpty {
                Text("No ticket data available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(statusCounts.enumerated()), id: \.offset) { _, item in
                    HStack {
                        Circle()
                            .fill(statusColor(for: item.status))
                            .frame(width: 8, height: 8)
                        
                        Text(item.status.capitalized.replacingOccurrences(of: "_", with: " "))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var technicianLeaderboardView: some View {
        let stats = reportingService.getTechnicianPerformance(from: dateRange.start, to: dateRange.end)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Technician Leaderboard")
                .font(.headline)
            
            if stats.isEmpty {
                Text("No technician data available")
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(stats.enumerated()), id: \.element.id) { index, item in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading) {
                            Text(item.technician.fullName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(Int(item.averageTurnaroundHours))h avg turnaround")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("\(item.ticketsClosed) tickets")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(formatCurrency(item.revenueGenerated))
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Helpers
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "completed", "picked_up":
            return .green
        case "in_progress":
            return .blue
        case "checked_in", "waiting", "pending":
            return .orange
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func printReport() {
        // Gather report data
        let revenue = reportingService.getRevenue(from: dateRange.start, to: dateRange.end)
        let invoiceStats = reportingService.getInvoiceStats(from: dateRange.start, to: dateRange.end)
        let ticketStats = reportingService.getTicketStats(from: dateRange.start, to: dateRange.end)
        let paymentMethods = reportingService.getRevenueByPaymentMethod(from: dateRange.start, to: dateRange.end)
        
        // Format date range
        let dateRangeString = "\(dateRange.start.formatted(date: .abbreviated, time: .omitted)) - \(dateRange.end.formatted(date: .abbreviated, time: .omitted))"
        
        // Prepare metrics
        let metrics: [String: String] = [
            "Total Revenue": formatCurrency(revenue),
            "Total Invoices": "\(invoiceStats.totalInvoices)",
            "Paid Invoices": "\(invoiceStats.paidInvoices)",
            "Unpaid Invoices": "\(invoiceStats.totalInvoices - invoiceStats.paidInvoices)",
            "Total Tickets": "\(ticketStats.totalTickets)",
            "Completed Tickets": "\(ticketStats.completedTickets)",
            "Average Turnaround": String(format: "%.1f hours", ticketStats.averageTurnaroundHours)
        ]
        
        // Prepare detailed breakdown
        var details = "PAYMENT METHOD BREAKDOWN:\n\n"
        for (method, amount) in paymentMethods {
            let percentage = revenue > 0 ? (amount / revenue) * 100 : 0
            details += String(format: "%@: %@ (%.1f%%)\n", method, formatCurrency(amount), NSDecimalNumber(decimal: percentage).doubleValue)
        }
        
        // Print the report
        DymoPrintService.shared.printReport(
            title: selectedReportType.rawValue,
            dateRange: dateRangeString,
            metrics: metrics,
            details: details
        )
    }
}

// MARK: - Export Report View
struct ExportReportView: View {
    @Environment(\.dismiss) var dismiss
    
    let reportType: ReportType
    let startDate: Date
    let endDate: Date
    
    @State private var exportFormat: ExportFormat = .csv
    
    private let reportingService = ReportingService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Options") {
                    Picker("Format", selection: $exportFormat) {
                        Text("CSV").tag(ExportFormat.csv)
                        Text("PDF").tag(ExportFormat.pdf)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Report Details") {
                    LabeledContent("Report Type", value: reportType.rawValue)
                    LabeledContent("Start Date", value: startDate.formatted(date: .abbreviated, time: .omitted))
                    LabeledContent("End Date", value: endDate.formatted(date: .abbreviated, time: .omitted))
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Export Report")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        exportReport()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func exportReport() {
        let csvData = reportingService.generateCSVReport(type: reportType, from: startDate, to: endDate)
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "\(reportType.rawValue)_\(Date().timeIntervalSince1970).csv"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? csvData.write(to: url, atomically: true, encoding: .utf8)
            }
            dismiss()
        }
    }
}

// MARK: - Supporting Types

enum DateRangeOption: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    case thisYear = "This Year"
    case last30Days = "Last 30 Days"
    case last90Days = "Last 90 Days"
}

enum ExportFormat {
    case csv
    case pdf
}
