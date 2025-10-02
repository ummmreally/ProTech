//
//  TransactionHistoryView.swift
//  ProTech
//
//  View all payment transactions
//

import SwiftUI

struct TransactionHistoryView: View {
    @State private var transactions: [Transaction] = []
    @State private var searchText = ""
    @State private var filterStatus: String = "all"
    @State private var selectedTransaction: Transaction?
    @State private var showingRefundDialog = false
    @State private var refundAmount = ""
    
    private let coreDataManager = CoreDataManager.shared
    private let stripeService = StripeService.shared
    
    var filteredTransactions: [Transaction] {
        var filtered = transactions
        
        // Filter by status
        if filterStatus != "all" {
            filtered = filtered.filter { $0.status == filterStatus }
        }
        
        // Search
        if !searchText.isEmpty {
            filtered = filtered.filter { transaction in
                transaction.transactionId?.localizedCaseInsensitiveContains(searchText) ?? false ||
                transaction.cardLast4?.contains(searchText) ?? false
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // Filters
                filterBar
                
                Divider()
                
                // Transactions list
                if filteredTransactions.isEmpty {
                    emptyStateView
                } else {
                    transactionListView
                }
            }
            .onAppear {
                loadTransactions()
            }
            .sheet(item: $selectedTransaction) { transaction in
                TransactionDetailView(transaction: transaction)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Transactions")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(filteredTransactions.count) transaction\(filteredTransactions.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
        }
        .padding()
    }
    
    private var statisticsView: some View {
        let successful = transactions.filter { $0.isSuccessful }.reduce(Decimal.zero) { $0 + $1.amount }
        let refunded = transactions.filter { $0.isRefunded }.reduce(Decimal.zero) { $0 + $1.refundAmount }
        
        return HStack(spacing: 20) {
            TransactionStatCard(
                title: "Processed",
                value: formatCurrency(successful),
                color: .green
            )
            
            TransactionStatCard(
                title: "Refunded",
                value: formatCurrency(refunded),
                color: .red
            )
        }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search transactions...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: 400)
            
            Spacer()
            
            // Status filter
            Picker("Status", selection: $filterStatus) {
                Text("All").tag("all")
                Text("Successful").tag("succeeded")
                Text("Failed").tag("failed")
                Text("Refunded").tag("refunded")
            }
            .pickerStyle(.segmented)
            .frame(width: 400)
        }
        .padding()
    }
    
    // MARK: - Transaction List
    
    private var transactionListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredTransactions, id: \.transactionId) { transaction in
                    TransactionRow(transaction: transaction)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTransaction = transaction
                        }
                        .contextMenu {
                            transactionContextMenu(for: transaction)
                        }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Transactions")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(filterStatus == "all" ? "No payment transactions yet" : "No transactions with this status")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func transactionContextMenu(for transaction: Transaction) -> some View {
        Button {
            selectedTransaction = transaction
        } label: {
            Label("View Details", systemImage: "eye")
        }
        
        if transaction.isSuccessful && !transaction.isRefunded {
            Button {
                selectedTransaction = transaction
                showingRefundDialog = true
            } label: {
                Label("Refund", systemImage: "arrow.uturn.backward")
            }
        }
        
        if let receiptUrl = transaction.receiptUrl {
            Button {
                if let url = URL(string: receiptUrl) {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("View Receipt", systemImage: "doc.text")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadTransactions() {
        let request = Transaction.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        transactions = (try? coreDataManager.viewContext.fetch(request)) ?? []
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Transaction Row

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            // Status icon
            Image(systemName: statusIcon)
                .font(.title2)
                .foregroundColor(statusColor)
                .frame(width: 40)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.formattedAmount)
                        .font(.headline)
                    
                    if transaction.isRefunded {
                        Text("(Refunded: \(transaction.formattedRefundAmount))")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(transaction.paymentMethodDisplay)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let date = transaction.processedAt ?? transaction.createdAt {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let transactionId = transaction.transactionId {
                    Text("ID: \(transactionId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status badge
            Text(transaction.statusDisplay)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(6)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch transaction.status {
        case "succeeded":
            return "checkmark.circle.fill"
        case "pending":
            return "clock.fill"
        case "failed":
            return "xmark.circle.fill"
        case "refunded":
            return "arrow.uturn.backward.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch transaction.status {
        case "succeeded":
            return .green
        case "pending":
            return .orange
        case "failed":
            return .red
        case "refunded":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let transaction: Transaction
    
    @State private var showingRefundDialog = false
    @State private var refundAmount = ""
    @State private var isProcessing = false
    
    private let stripeService = StripeService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction Details") {
                    LabeledContent("Amount", value: transaction.formattedAmount)
                    LabeledContent("Status", value: transaction.statusDisplay)
                    LabeledContent("Payment Method", value: transaction.paymentMethodDisplay)
                    
                    if let transactionId = transaction.transactionId {
                        LabeledContent("Transaction ID", value: transactionId)
                    }
                    
                    if let date = transaction.processedAt ?? transaction.createdAt {
                        LabeledContent("Date", value: date.formatted(date: .long, time: .shortened))
                    }
                }
                
                if transaction.isRefunded {
                    Section("Refund Information") {
                        LabeledContent("Refunded Amount", value: transaction.formattedRefundAmount)
                        
                        if let date = transaction.refundedAt {
                            LabeledContent("Refunded At", value: date.formatted(date: .long, time: .shortened))
                        }
                    }
                }
                
                if let failureMessage = transaction.failureMessage {
                    Section("Failure Reason") {
                        Text(failureMessage)
                            .foregroundColor(.red)
                    }
                }
                
                // Actions
                if transaction.isSuccessful && !transaction.isRefunded {
                    Section {
                        Button(role: .destructive) {
                            showingRefundDialog = true
                        } label: {
                            Label("Issue Refund", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}
struct TransactionStatCard: View {
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
