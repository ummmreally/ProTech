import SwiftUI

struct InvoiceListView: View {
    @State private var invoices: [Invoice] = []
    @State private var searchText = ""
    @State private var sortOption: InvoiceSortOption = .dateDesc
    @State private var filterStatus: InvoiceStatusFilter = .all
    @State private var showingNewInvoice = false
    @State private var selectedInvoice: Invoice?
    
    private let invoiceService = InvoiceService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var filteredInvoices: [Invoice] {
        var filtered = invoices
        
        // Filter by status
        switch filterStatus {
        case .all:
            break
        case .draft:
            filtered = filtered.filter { $0.status == "draft" }
        case .sent:
            filtered = filtered.filter { $0.status == "sent" }
        case .paid:
            filtered = filtered.filter { $0.status == "paid" }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        case .unpaid:
            filtered = filtered.filter { $0.status != "paid" && $0.status != "cancelled" }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { invoice in
                invoice.invoiceNumber?.localizedCaseInsensitiveContains(searchText) ?? false ||
                invoice.notes?.localizedCaseInsensitiveContains(searchText) ?? false
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
                
                // Filters and search
                filterBar
                
                Divider()
                
                // Invoice list
                if filteredInvoices.isEmpty {
                    emptyStateView
                } else {
                    invoiceListContent
                }
            }
            .onAppear {
                loadInvoices()
            }
            .sheet(isPresented: $showingNewInvoice) {
                InvoiceGeneratorView(invoice: nil)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        loadInvoices()
                    }
            }
            .navigationDestination(item: $selectedInvoice) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Invoices")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("\(filteredInvoices.count) invoice\(filteredInvoices.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            Button(action: { showingNewInvoice = true }) {
                Label("New Invoice", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var statisticsView: some View {
        HStack(spacing: 20) {
            InvoiceStatCard(
                title: "Total Revenue",
                value: formatCurrency(invoiceService.getTotalRevenue()),
                color: .green
            )
            
            InvoiceStatCard(
                title: "Outstanding",
                value: formatCurrency(invoiceService.getOutstandingBalance()),
                color: .orange
            )
            
            InvoiceStatCard(
                title: "Overdue",
                value: "\(invoiceService.fetchOverdueInvoices().count)",
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
                TextField("Search invoices...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Status filter
            Picker("Status", selection: $filterStatus) {
                ForEach(InvoiceStatusFilter.allCases, id: \.self) { status in
                    Text(status.rawValue).tag(status)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            // Sort
            Picker("Sort", selection: $sortOption) {
                ForEach(InvoiceSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            .onChange(of: sortOption, initial: false) { _, _ in
                loadInvoices()
            }
        }
        .padding()
    }
    
    // MARK: - Invoice List
    
    private var invoiceListContent: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredInvoices) { invoice in
                    InvoiceRowView(invoice: invoice)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedInvoice = invoice
                        }
                        .contextMenu {
                            invoiceContextMenu(for: invoice)
                        }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Invoices")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first invoice to get started")
                .foregroundColor(.secondary)
            
            Button(action: { showingNewInvoice = true }) {
                Label("Create Invoice", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    private func invoiceContextMenu(for invoice: Invoice) -> some View {
        Group {
            Button(action: { selectedInvoice = invoice }) {
                Label("View Details", systemImage: "eye")
            }
            
            Button(action: { exportPDF(invoice) }) {
                Label("Export PDF", systemImage: "arrow.down.doc")
            }
            
            if invoice.status == "draft" {
                Button(action: { markAsSent(invoice) }) {
                    Label("Mark as Sent", systemImage: "paperplane")
                }
            }
            
            if invoice.status != "paid" && invoice.status != "cancelled" {
                Button(action: { markAsPaid(invoice) }) {
                    Label("Mark as Paid", systemImage: "checkmark.circle")
                }
            }
            
            Divider()
            
            Button(role: .destructive, action: { deleteInvoice(invoice) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadInvoices() {
        invoices = invoiceService.fetchInvoices(sortBy: sortOption)
    }
    
    private func exportPDF(_ invoice: Invoice) {
        guard let customer = coreDataManager.fetchCustomer(id: invoice.customerId ?? UUID()) else {
            return
        }
        
        let pdfGenerator = PDFGenerator.shared
        guard let pdfDocument = pdfGenerator.generateInvoicePDF(
            invoice: invoice,
            customer: customer,
            companyInfo: .default
        ) else {
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Invoice_\(invoice.formattedInvoiceNumber).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = pdfGenerator.savePDF(pdfDocument, to: url)
            }
        }
    }
    
    private func markAsSent(_ invoice: Invoice) {
        invoiceService.markAsSent(invoice)
        loadInvoices()
    }
    
    private func markAsPaid(_ invoice: Invoice) {
        invoiceService.markAsPaid(invoice)
        loadInvoices()
    }
    
    private func deleteInvoice(_ invoice: Invoice) {
        invoiceService.deleteInvoice(invoice)
        loadInvoices()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Invoice Row View

struct InvoiceRowView: View {
    let invoice: Invoice
    private let coreDataManager = CoreDataManager.shared
    
    var customer: Customer? {
        guard let customerId = invoice.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            // Invoice number
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.formattedInvoiceNumber)
                    .font(.headline)
                
                if let customer = customer {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, alignment: .leading)
            
            // Date
            VStack(alignment: .leading, spacing: 4) {
                if let issueDate = invoice.issueDate {
                    Text("Issued: \(issueDate, style: .date)")
                        .font(.caption)
                }
                if let dueDate = invoice.dueDate {
                    Text("Due: \(dueDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(invoice.isOverdue ? .red : .secondary)
                }
            }
            .frame(width: 150, alignment: .leading)
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(invoice.total))
                    .font(.headline)
                
                if invoice.balance > 0 {
                    Text("Balance: \(formatCurrency(invoice.balance))")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            // Status badge
            Text(invoice.status?.capitalized ?? "Draft")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
                .frame(width: 80)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case "paid":
            return .green
        case "sent":
            return .blue
        case "draft":
            return .gray
        case "cancelled":
            return .red
        default:
            if invoice.isOverdue {
                return .red
            }
            return .orange
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Stat Card

struct InvoiceStatCard: View {
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

// MARK: - Supporting Types

enum InvoiceStatusFilter: String, CaseIterable {
    case all = "All"
    case draft = "Draft"
    case sent = "Sent"
    case paid = "Paid"
    case unpaid = "Unpaid"
    case overdue = "Overdue"
}

// MARK: - Preview

struct InvoiceListView_Previews: PreviewProvider {
    static var previews: some View {
        InvoiceListView()
    }
}
