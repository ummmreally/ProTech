//
//  TransactionHistoryView.swift
//  ProTech
//
//  Created for ProTech POS Overhaul
//

import SwiftUI

struct POSTransactionHistoryView: View {
    @StateObject private var viewModel = POSTransactionHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Filter Bar
                filterBar

                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.transactions.isEmpty {
                    emptyStateView
                } else {
                    transactionList
                }
            }
            .navigationTitle("Transaction History")

            .background(AppTheme.Colors.groupedBackground)
            .task {
                await viewModel.fetchTransactions()
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Recent Transactions")
                .font(.title2)
                .fontWeight(.bold)
            Spacer()
            Button {
                Task { await viewModel.fetchTransactions() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                POSFilterChip(title: "All", isSelected: viewModel.filter == .all) {
                    viewModel.filter = .all
                }
                POSFilterChip(title: "Completed", isSelected: viewModel.filter == .completed) {
                    viewModel.filter = .completed
                }
                POSFilterChip(title: "Refunded", isSelected: viewModel.filter == .refunded) {
                    viewModel.filter = .refunded
                }
            }
            .padding()
        }
        .background(AppTheme.Colors.cardBackground)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
    }

    private var transactionList: some View {
        List {
            ForEach(viewModel.filteredTransactions) { transaction in
                POSTransactionRow(transaction: transaction)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No transactions found")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct POSTransactionRow: View {
    let transaction: SquareTransactionModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(transaction.createdAtStr)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if !transaction.subtitle.isEmpty {
                    Text(transaction.subtitle)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(transaction.totalMoney)
                    .fontWeight(.bold)
                Text(transaction.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppTheme.Colors.cardBackground)
        .cornerRadius(12)
        .padding(.vertical, 4)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    var statusColor: Color {
        switch transaction.status.uppercased() {
        case "COMPLETED": return .green
        case "REFUNDED": return .orange
        case "FAILED": return .red
        default: return .gray
        }
    }
}

struct POSFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .cornerRadius(20)
        }
    }
}

enum TransactionFilter {
    case all, completed, refunded
}

// Temporary Model until we hook up to real API
struct SquareTransactionModel: Identifiable {
    let id: String
    let totalMoney: String
    let status: String
    let createdAt: Date
    let title: String
    let subtitle: String
    
    var createdAtStr: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

@MainActor
class POSTransactionHistoryViewModel: ObservableObject {
    @Published var transactions: [SquareTransactionModel] = []
    @Published var isLoading = false
    @Published var filter: TransactionFilter = .all

    var filteredTransactions: [SquareTransactionModel] {
        switch filter {
        case .all: return transactions
        case .completed: return transactions.filter { $0.status == "COMPLETED" }
        case .refunded: return transactions.filter { $0.status == "REFUNDED" }
        }
    }

    func fetchTransactions() async {
        isLoading = true
        do {
            let orders = try await SquareAPIService.shared.fetchRecentTransactions()
            self.transactions = orders.map { order in
                let totalAmount = Double(order.totalMoney?.amount ?? 0) / 100.0
                let totalStr = NumberFormatter.currency.string(from: NSNumber(value: totalAmount)) ?? "$0.00"
                
                // Parse date with robust fallback
                let date = self.parseDate(order.createdAt)
                
                // Determine Title (Product Names)
                let productNames = order.lineItems?.compactMap { $0.name }.joined(separator: ", ") ?? ""
                let title = productNames.isEmpty ? "Transaction \(order.id.prefix(4))..." : productNames
                
                // Determine Subtitle (Customer or expanded ID)
                var subtitle = order.id
                if let customerId = order.customerId ?? order.tenders?.first?.customerId {
                    subtitle = "Customer ID: \(customerId.prefix(8))..."
                }
                
                return SquareTransactionModel(
                    id: order.id,
                    totalMoney: totalStr,
                    status: order.state,
                    createdAt: date,
                    title: title,
                    subtitle: subtitle
                )
            }
        } catch {
            print("Failed to fetch transactions: \(error)")
            // Optionally handle error state
        }
        isLoading = false
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }
        return Date() // Fallback to now if parsing fails completely
    }
}

extension NumberFormatter {
    static var currency: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter
    }
}
