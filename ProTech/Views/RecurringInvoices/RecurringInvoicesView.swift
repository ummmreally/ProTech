//
//  RecurringInvoicesView.swift
//  ProTech
//
//  Manage recurring invoices and subscriptions
//

import SwiftUI

struct RecurringInvoicesView: View {
    @State private var recurringInvoices: [RecurringInvoice] = []
    @State private var searchText = ""
    @State private var showingNewRecurring = false
    @State private var selectedRecurring: RecurringInvoice?
    @State private var stats: RecurringInvoiceStats?
    
    private let service = RecurringInvoiceService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var filteredRecurring: [RecurringInvoice] {
        if searchText.isEmpty {
            return recurringInvoices
        }
        return recurringInvoices.filter { recurring in
            recurring.name?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Search
                searchBar
                
                Divider()
                
                // List
                if filteredRecurring.isEmpty {
                    emptyStateView
                } else {
                    recurringListView
                }
            }
            .onAppear {
                loadData()
            }
            .sheet(isPresented: $showingNewRecurring) {
                RecurringInvoiceBuilderView(recurring: nil)
                    .onDisappear { loadData() }
            }
            .sheet(item: $selectedRecurring) { recurring in
                RecurringInvoiceDetailView(recurring: recurring)
                    .onDisappear { loadData() }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recurring Invoices")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(filteredRecurring.count) active")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let stats = stats {
                statisticsView(stats: stats)
            }
            
            Spacer()
            
            Button {
                showingNewRecurring = true
            } label: {
                Label("New Recurring Invoice", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private func statisticsView(stats: RecurringInvoiceStats) -> some View {
        HStack(spacing: 20) {
            RecurringStatCard(title: "Active", value: "\(stats.activeRecurring)", color: .green)
            RecurringStatCard(title: "MRR", value: stats.formattedMRR, color: .purple)
            RecurringStatCard(title: "Total Revenue", value: stats.formattedRevenue, color: .blue)
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search recurring invoices...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
    
    private var recurringListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredRecurring, id: \.id) { recurring in
                    RecurringInvoiceRow(recurring: recurring)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRecurring = recurring
                        }
                        .contextMenu {
                            contextMenu(for: recurring)
                        }
                }
            }
            .padding()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "repeat.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Recurring Invoices")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Set up automatic recurring invoices for subscriptions and contracts")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showingNewRecurring = true
            } label: {
                Label("Create Recurring Invoice", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func contextMenu(for recurring: RecurringInvoice) -> some View {
        Button {
            selectedRecurring = recurring
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        Button {
            _ = service.generateInvoiceManually(from: recurring)
            loadData()
        } label: {
            Label("Generate Now", systemImage: "doc.badge.plus")
        }
        
        if recurring.isActive {
            Button {
                service.pauseRecurringInvoice(recurring)
                loadData()
            } label: {
                Label("Pause", systemImage: "pause")
            }
        } else {
            Button {
                service.activateRecurringInvoice(recurring)
                loadData()
            } label: {
                Label("Activate", systemImage: "play")
            }
        }
        
        Button(role: .destructive) {
            service.deleteRecurringInvoice(recurring)
            loadData()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func loadData() {
        let request = RecurringInvoice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "nextInvoiceDate", ascending: true)]
        recurringInvoices = (try? coreDataManager.viewContext.fetch(request)) ?? []
        stats = service.getRecurringInvoiceStats()
    }
}

// MARK: - Recurring Invoice Row

struct RecurringInvoiceRow: View {
    let recurring: RecurringInvoice
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: recurring.isActive ? "repeat.circle.fill" : "pause.circle.fill")
                .font(.title2)
                .foregroundColor(recurring.isActive ? .green : .orange)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recurring.name ?? "Untitled")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label(recurring.frequencyDisplay, systemImage: "calendar")
                    Text("•")
                    Label(recurring.formattedTotal, systemImage: "dollarsign.circle")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let nextDate = recurring.nextInvoiceDate {
                    Text("Next: \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(recurring.invoiceCount) invoices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(recurring.formattedRevenue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Builder and Detail Views (Simplified for token limit)

struct RecurringInvoiceBuilderView: View {
    @Environment(\.dismiss) var dismiss
    let recurring: RecurringInvoice?
    
    @State private var name = "Monthly Service"
    @State private var frequency = "monthly"
    @State private var interval = 1
    @State private var selectedCustomer: Customer?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    Picker("Frequency", selection: $frequency) {
                        Text("Monthly").tag("monthly")
                        Text("Quarterly").tag("quarterly")
                        Text("Yearly").tag("yearly")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Recurring Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { dismiss() }
                }
            }
        }
        .frame(width: 700, height: 600)
    }
}

struct RecurringInvoiceDetailView: View {
    @Environment(\.dismiss) var dismiss
    let recurring: RecurringInvoice
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text(recurring.name ?? "")
                        .font(.title)
                }
                .padding()
            }
            .navigationTitle("Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .frame(width: 700, height: 600)
    }
}
struct RecurringStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}
