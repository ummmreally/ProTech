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
                
                // Financial Overview
                GroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Spent")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(currencyFormatter.string(from: stats?.totalSpent as NSDecimalNumber? ?? 0) ?? "$0.00")
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
                            Text(currencyFormatter.string(from: stats?.outstandingBalance as NSDecimalNumber? ?? 0) ?? "$0.00")
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
                
                // Quick Actions
                GroupBox {
                    VStack(spacing: 12) {
                        if (stats?.activeRepairs ?? 0) > 0 {
                            NavigationLink(destination: PortalRepairsView(customer: customer)) {
                                QuickActionRow(title: "View Active Repairs", icon: "wrench.and.screwdriver.fill", color: .blue)
                            }
                        }
                        
                        if (stats?.pendingEstimates ?? 0) > 0 {
                            NavigationLink(destination: PortalEstimatesView(customer: customer)) {
                                QuickActionRow(title: "Review Pending Estimates", icon: "doc.plaintext.fill", color: .orange)
                            }
                        }
                        
                        if (stats?.unpaidInvoices ?? 0) > 0 {
                            NavigationLink(destination: PortalInvoicesView(customer: customer)) {
                                QuickActionRow(title: "View Unpaid Invoices", icon: "doc.text.fill", color: .red)
                            }
                        }
                        
                        NavigationLink(destination: PortalPaymentsView(customer: customer)) {
                            QuickActionRow(title: "Payment History", icon: "creditcard.fill", color: .green)
                        }
                    }
                } label: {
                    Label("Quick Actions", systemImage: "bolt.fill")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .navigationTitle("Overview")
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

struct QuickActionRow: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
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

// MARK: - Notification Extension

extension Notification.Name {
    static let customerPortalLogout = Notification.Name("customerPortalLogout")
}
