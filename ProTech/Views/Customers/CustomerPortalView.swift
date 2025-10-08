//
//  CustomerPortalView.swift
//  ProTech
//
//  Customer Portal - Self-service interface for customers
//

import SwiftUI
import CoreData

struct CustomerPortalView: View {
    let customer: Customer
    
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var selectedTab: PortalTab = .overview
    @State private var stats: CustomerPortalStats?
    @State private var showingLogout = false
    
    enum PortalTab {
        case overview
        case checkIn
        case repairs
        case invoices
        case estimates
        case payments
    }
    
    var body: some View {
        NavigationView {
            // Sidebar
            List(selection: $selectedTab) {
                Section("Portal") {
                    Label("Overview", systemImage: "house.fill")
                        .tag(PortalTab.overview)
                    
                    Label("Check In", systemImage: "hand.raised.fill")
                        .tag(PortalTab.checkIn)
                    
                    Label("My Repairs", systemImage: "wrench.and.screwdriver.fill")
                        .tag(PortalTab.repairs)
                        .badge(stats?.activeRepairs ?? 0)
                    
                    Label("Invoices", systemImage: "doc.text.fill")
                        .tag(PortalTab.invoices)
                        .badge(stats?.unpaidInvoices ?? 0)
                    
                    Label("Estimates", systemImage: "doc.plaintext.fill")
                        .tag(PortalTab.estimates)
                        .badge(stats?.pendingEstimates ?? 0)
                    
                    Label("Payments", systemImage: "creditcard.fill")
                        .tag(PortalTab.payments)
                }
                
                Section {
                    Button {
                        showingLogout = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Customer Portal")
            
            // Main Content
            Group {
                switch selectedTab {
                case .overview:
                    PortalOverviewView(customer: customer, stats: stats)
                case .checkIn:
                    PortalCheckInView(customer: customer)
                case .repairs:
                    PortalRepairsView(customer: customer)
                case .invoices:
                    PortalInvoicesView(customer: customer)
                case .estimates:
                    PortalEstimatesView(customer: customer)
                case .payments:
                    PortalPaymentsView(customer: customer)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .confirmationDialog("Sign Out", isPresented: $showingLogout) {
            Button("Sign Out", role: .destructive) {
                NotificationCenter.default.post(name: .customerPortalLogout, object: nil)
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .task {
            loadStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { _ in
            loadStats()
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { _ in
            loadStats()
        }
    }
    
    private func loadStats() {
        stats = portalService.getPortalStats(for: customer)
    }
}

// MARK: - Overview View

struct PortalOverviewView: View {
    let customer: Customer
    let stats: CustomerPortalStats?
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Welcome Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back, \(customer.firstName ?? "Customer")!")
                        .font(.largeTitle)
                        .bold()
                    
                    Text("Here's your account overview")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                if let alerts = stats?.alerts, !alerts.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(alerts) { alert in
                                PortalAlertRow(alert: alert)
                                if alert.id != alerts.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } label: {
                        Label("Attention Needed", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
                
                // Stats Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    PortalStatCard(
                        title: "Active Repairs",
                        value: "\(stats?.activeRepairs ?? 0)",
                        icon: "wrench.and.screwdriver.fill",
                        color: .blue
                    )
                    
                    PortalStatCard(
                        title: "Completed Repairs",
                        value: "\(stats?.completedRepairs ?? 0)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    PortalStatCard(
                        title: "Pending Estimates",
                        value: "\(stats?.pendingEstimates ?? 0)",
                        icon: "doc.plaintext.fill",
                        color: .orange
                    )
                    
                    PortalStatCard(
                        title: "Unpaid Invoices",
                        value: "\(stats?.unpaidInvoices ?? 0)",
                        icon: "exclamationmark.triangle.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                if let trends = stats?.trends, !trends.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(trends) { metric in
                                PortalTrendRow(metric: metric, currencyFormatter: currencyFormatter, numberFormatter: numberFormatter)
                                if metric.id != trends.last?.id {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        Label("30-Day Trends", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                // Financial Overview
                GroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Spent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(currencyString(for: stats?.totalSpent))
                                .font(.title2)
                                .bold()
                        }
                        
                        Spacer()
                        
                        Divider()
                        
                        Spacer()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Outstanding Balance")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(currencyString(for: stats?.outstandingBalance))
                                .font(.title2)
                                .bold()
                                .foregroundColor((stats?.outstandingBalance ?? 0) > 0 ? .red : .green)
                        }
                    }
                    .padding()
                } label: {
                    Label("Financial Summary", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                if !quickActions.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(quickActions) { action in
                                quickActionLink(for: action)
                            }
                        }
                    } label: {
                        Label("Suggested Actions", systemImage: "bolt.fill")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                if let engagement = stats?.engagement {
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Last portal activity", systemImage: "clock.arrow.circlepath")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(engagement.lastCustomerAction.map { relativeFormatter.localizedString(for: $0, relativeTo: Date()) } ?? "No activity yet")
                                    .bold()
                            }
                            
                            HStack {
                                Label("Approvals (30d)", systemImage: "checkmark.circle")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(engagement.approvalsLast30Days)")
                                    .bold()
                            }
                            
                            HStack {
                                Label("Payments (30d)", systemImage: "creditcard")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(engagement.paymentsLast30Days)")
                                    .bold()
                            }
                            
                            if let averageApprovalTime = engagement.averageApprovalTime {
                                HStack {
                                    Label("Avg. approval time", systemImage: "timer")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatted(duration: averageApprovalTime))
                                        .bold()
                                }
                            }
                        }
                    } label: {
                        Label("Engagement Insights", systemImage: "person.fill.checkmark")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                if let activity = stats?.recentActivity, !activity.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(activity) { item in
                                PortalActivityRow(activity: item, relativeFormatter: relativeFormatter)
                                if item.id != activity.last?.id {
                                    Divider()
                                }
                            }
                        }
                    } label: {
                        Label("Recent Activity", systemImage: "list.bullet.rectangle")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Overview")
    }
    
    private var quickActions: [PortalQuickAction] {
        guard let stats else { return [] }
        var actions: [PortalQuickAction] = []
        
        if stats.pendingEstimates > 0 {
            actions.append(PortalQuickAction(title: "Review pending estimates", icon: "doc.plaintext.fill", tint: .orange, destination: .estimates))
        }
        
        if !stats.expiringEstimates.isEmpty {
            actions.append(PortalQuickAction(title: "Approve expiring estimates", icon: "hourglass", tint: .red, destination: .estimates))
        }
        
        if stats.unpaidInvoices > 0 {
            actions.append(PortalQuickAction(title: "Pay outstanding invoices", icon: "doc.text.fill", tint: .red, destination: .invoices))
        }
        
        if !stats.overdueInvoices.isEmpty {
            actions.append(PortalQuickAction(title: "View overdue invoices", icon: "exclamationmark.triangle", tint: .orange, destination: .invoices))
        }
        
        if stats.activeRepairs > 0 {
            actions.append(PortalQuickAction(title: "Check active repairs", icon: "wrench.and.screwdriver.fill", tint: .blue, destination: .repairs))
        }
        
        if !stats.recentPayments.isEmpty {
            actions.append(PortalQuickAction(title: "View latest payments", icon: "creditcard.fill", tint: .green, destination: .payments))
        }
        
        return Array(actions.prefix(4))
    }
    
    @ViewBuilder
    private func quickActionLink(for action: PortalQuickAction) -> some View {
        switch action.destination {
        case .repairs:
            NavigationLink(destination: PortalRepairsView(customer: customer)) {
                QuickActionRow(action: action)
            }
        case .estimates:
            NavigationLink(destination: PortalEstimatesView(customer: customer)) {
                QuickActionRow(action: action)
            }
        case .invoices:
            NavigationLink(destination: PortalInvoicesView(customer: customer)) {
                QuickActionRow(action: action)
            }
        case .payments:
            NavigationLink(destination: PortalPaymentsView(customer: customer)) {
                QuickActionRow(action: action)
            }
        }
    }
    
    private func formatted(duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    private func currencyString(for value: Decimal?) -> String {
        guard let value else {
            return currencyFormatter.string(from: 0) ?? "$0.00"
        }
        return currencyFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }
}

struct PortalQuickAction: Identifiable {
    enum Destination {
        case repairs
        case estimates
        case invoices
        case payments
    }
    
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
    let destination: Destination
}

struct QuickActionRow: View {
    let action: PortalQuickAction
    
    var body: some View {
        HStack {
            Image(systemName: action.icon)
                .foregroundColor(action.tint)
                .frame(width: 24)
            
            Text(action.title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

struct PortalAlertRow: View {
    let alert: PortalDashboardAlert
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.headline)
                Text(alert.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var iconName: String {
        switch alert.kind {
        case .estimateExpiring:
            return "hourglass"
        case .invoiceOverdue:
            return "exclamationmark.triangle.fill"
        case .newPayment:
            return "creditcard"
        }
    }
    
    private var iconColor: Color {
        switch alert.kind {
        case .estimateExpiring:
            return .orange
        case .invoiceOverdue:
            return .red
        case .newPayment:
            return .green
        }
    }
}

struct PortalTrendRow: View {
    let metric: PortalTrendMetric
    let currencyFormatter: NumberFormatter
    let numberFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(metric.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatted(value: metric.currentValue))
                    .font(.headline)
            }
            
            let delta = metric.delta
            let isPositive = delta >= 0
            HStack(spacing: 6) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                Text(formatted(value: delta, includeSign: true))
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                Text("vs previous 30 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatted(value: Decimal, includeSign: Bool = false) -> String {
        switch metric.unit {
        case "currency":
            let string = currencyFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
            if includeSign {
                return value >= 0 ? "+\(string)" : string
            }
            return string
        default:
            let string = numberFormatter.string(from: NSDecimalNumber(decimal: value)) ?? "0"
            if includeSign {
                return value >= 0 ? "+\(string)" : string
            }
            return string
        }
    }
}

struct PortalActivityRow: View {
    let activity: PortalActivity
    let relativeFormatter: RelativeDateTimeFormatter
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.title)
                        .font(.headline)
                    Spacer()
                    Text(relativeFormatter.localizedString(for: activity.date, relativeTo: Date()))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(activity.detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var iconName: String {
        switch activity.type {
        case .repair:
            return "wrench.and.screwdriver"
        case .estimate:
            return "doc.plaintext"
        case .invoice:
            return "doc.text"
        case .payment:
            return "creditcard"
        }
    }
    
    private var iconColor: Color {
        switch activity.type {
        case .repair:
            return .blue
        case .estimate:
            return .orange
        case .invoice:
            return .purple
        case .payment:
            return .green
        }
    }
}

// MARK: - Repairs View

struct PortalRepairsView: View {
    let customer: Customer
    
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var tickets: [Ticket] = []
    @State private var selectedTicket: Ticket?
    @State private var filterOption: TicketFilter = .all
    
    enum TicketFilter {
        case all
        case active
        case completed
    }
    
    var filteredTickets: [Ticket] {
        switch filterOption {
        case .all:
            return tickets
        case .active:
            return tickets.filter { $0.status != "completed" && $0.status != "picked_up" && $0.status != "cancelled" }
        case .completed:
            return tickets.filter { $0.status == "completed" || $0.status == "picked_up" }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Picker
            Picker("Filter", selection: $filterOption) {
                Text("All").tag(TicketFilter.all)
                Text("Active").tag(TicketFilter.active)
                Text("Completed").tag(TicketFilter.completed)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if filteredTickets.isEmpty {
                ContentUnavailableView {
                    Label("No Repairs", systemImage: "wrench.and.screwdriver")
                } description: {
                    Text("You don't have any \(filterOption == .all ? "" : filterOption == .active ? "active" : "completed") repairs at the moment.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTickets) { ticket in
                            Button {
                                selectedTicket = ticket
                            } label: {
                                PortalTicketCard(ticket: ticket)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Repairs")
        .sheet(item: $selectedTicket) { ticket in
            PortalTicketDetailView(ticket: ticket)
        }
        .task {
            tickets = portalService.fetchTickets(for: customer)
        }
    }
}

// MARK: - Invoices View

struct PortalInvoicesView: View {
    let customer: Customer
    
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var invoices: [Invoice] = []
    @State private var selectedInvoice: Invoice?
    
    var body: some View {
        VStack {
            if invoices.isEmpty {
                ContentUnavailableView {
                    Label("No Invoices", systemImage: "doc.text")
                } description: {
                    Text("You don't have any invoices yet.")
                }
            } else {
                List(invoices) { invoice in
                    Button {
                        selectedInvoice = invoice
                    } label: {
                        PortalInvoiceRow(invoice: invoice)
                    }
                }
            }
        }
        .navigationTitle("Invoices")
        .sheet(item: $selectedInvoice) { invoice in
            PortalInvoiceDetailView(invoice: invoice)
        }
        .task {
            invoices = portalService.fetchInvoices(for: customer)
        }
    }
}

// MARK: - Estimates View

struct PortalEstimatesView: View {
    let customer: Customer
    
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var estimates: [Estimate] = []
    @State private var selectedEstimate: Estimate?
    
    var body: some View {
        VStack {
            if estimates.isEmpty {
                ContentUnavailableView {
                    Label("No Estimates", systemImage: "doc.plaintext")
                } description: {
                    Text("You don't have any estimates yet.")
                }
            } else {
                List(estimates) { estimate in
                    Button {
                        selectedEstimate = estimate
                    } label: {
                        PortalEstimateRow(estimate: estimate)
                    }
                }
            }
        }
        .navigationTitle("Estimates")
        .sheet(item: $selectedEstimate) { estimate in
            PortalEstimateDetailView(estimate: estimate, customer: customer)
        }
        .task {
            loadEstimates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { _ in
            loadEstimates()
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { _ in
            loadEstimates()
        }
    }

    private func loadEstimates() {
        estimates = portalService.fetchEstimates(for: customer)
    }
}

// MARK: - Payments View

struct PortalPaymentsView: View {
    let customer: Customer
    
    @StateObject private var portalService = CustomerPortalService.shared
    @State private var payments: [Payment] = []
    
    var body: some View {
        VStack {
            if payments.isEmpty {
                ContentUnavailableView {
                    Label("No Payments", systemImage: "creditcard")
                } description: {
                    Text("You don't have any payment history yet.")
                }
            } else {
                List(payments) { payment in
                    PortalPaymentRow(payment: payment)
                }
            }
        }
        .navigationTitle("Payment History")
        .task {
            payments = portalService.fetchPayments(for: customer)
        }
    }
}

// MARK: - Supporting Components

private struct PortalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(.title, design: .rounded))
                .bold()
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
// MARK: - Notification Extension

extension Notification.Name {
    static let customerPortalLogout = Notification.Name("customerPortalLogout")
}
