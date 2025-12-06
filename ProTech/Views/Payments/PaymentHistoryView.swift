import SwiftUI
import PDFKit
import PDFKit

struct PaymentHistoryView: View {
    @State private var payments: [Payment] = []
    @State private var searchText = ""
    @State private var sortOption: PaymentSortOption = .dateDesc
    @State private var filterMethod: String = "all"
    @State private var showingNewPayment = false
    @State private var selectedPayment: Payment?
    @State private var dateRange: DateRangeFilter = .all
    
    private let paymentService = PaymentService.shared
    private let coreDataManager = CoreDataManager.shared
    
    var filteredPayments: [Payment] {
        var filtered = payments
        
        // Filter by payment method
        if filterMethod != "all" {
            filtered = filtered.filter { $0.paymentMethod == filterMethod }
        }
        
        // Filter by date range
        switch dateRange {
        case .all:
            break
        case .today:
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            filtered = filtered.filter { payment in
                guard let date = payment.paymentDate else { return false }
                return date >= startOfDay
            }
        case .thisWeek:
            let calendar = Calendar.current
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
            filtered = filtered.filter { payment in
                guard let date = payment.paymentDate else { return false }
                return date >= startOfWeek
            }
        case .thisMonth:
            let calendar = Calendar.current
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
            filtered = filtered.filter { payment in
                guard let date = payment.paymentDate else { return false }
                return date >= startOfMonth
            }
        }
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { payment in
                payment.paymentNumber?.localizedCaseInsensitiveContains(searchText) ?? false ||
                payment.referenceNumber?.localizedCaseInsensitiveContains(searchText) ?? false ||
                payment.notes?.localizedCaseInsensitiveContains(searchText) ?? false
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
                
                // Payment list
                if filteredPayments.isEmpty {
                    emptyStateView
                } else {
                    paymentListContent
                }
            }
            .onAppear {
                loadPayments()
            }
            .sheet(isPresented: $showingNewPayment) {
                QuickPaymentView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .onDisappear {
                        loadPayments()
                    }
            }
            .navigationDestination(item: $selectedPayment) { payment in
                PaymentDetailView(payment: payment)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Payment History")
                    .font(AppTheme.Typography.title)
                    .fontWeight(.bold)
                
                Text("\(filteredPayments.count) payment\(filteredPayments.count == 1 ? "" : "s")")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Statistics
            statisticsView
            
            Spacer()
            
            Button(action: { showingNewPayment = true }) {
                Label("Record Payment", systemImage: "plus.circle.fill")
                    .font(AppTheme.Typography.headline)
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .padding(AppTheme.Spacing.xl)
    }
    
    private var statisticsView: some View {
        HStack(spacing: 20) {
            PaymentStatCard(
                title: "Today's Revenue",
                value: formatCurrency(paymentService.getTodaysRevenue()),
                color: .green
            )
            
            PaymentStatCard(
                title: "This Month",
                value: formatCurrency(paymentService.getMonthlyRevenue()),
                color: .blue
            )
            
            PaymentStatCard(
                title: "Total Received",
                value: formatCurrency(paymentService.getTotalPaymentsReceived()),
                color: .purple
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
                TextField("Search payments...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppTheme.Spacing.sm)
            .background(AppTheme.Colors.cardBackground.opacity(0.5))
            .cornerRadius(AppTheme.cardCornerRadius)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Date range filter
            Picker("Period", selection: $dateRange) {
                ForEach(DateRangeFilter.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            // Payment method filter
            Picker("Method", selection: $filterMethod) {
                Text("All Methods").tag("all")
                Text("Cash").tag("cash")
                Text("Card").tag("card")
                Text("Check").tag("check")
                Text("Transfer").tag("transfer")
                Text("Other").tag("other")
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            // Sort
            Picker("Sort", selection: $sortOption) {
                ForEach(PaymentSortOption.allCases, id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            .onChange(of: sortOption, initial: false) { _, _ in
                loadPayments()
            }
        }
        .padding()
    }
    
    // MARK: - Payment List
    
    private var paymentListContent: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(filteredPayments) { payment in
                    PaymentRowView(payment: payment)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPayment = payment
                        }
                        .contextMenu {
                            paymentContextMenu(for: payment)
                        }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "dollarsign.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Payments")
                .font(AppTheme.Typography.title2)
                .fontWeight(.semibold)
            
            Text("Record your first payment to get started")
                .foregroundColor(.secondary)
            
            Button(action: { showingNewPayment = true }) {
                Label("Record Payment", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PremiumButtonStyle(variant: .primary))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    private func paymentContextMenu(for payment: Payment) -> some View {
        Group {
            Button(action: { selectedPayment = payment }) {
                Label("View Details", systemImage: "eye")
            }
            
            Button(action: { printReceipt(payment) }) {
                Label("Print Receipt", systemImage: "printer")
            }
            
            Button(action: { exportReceipt(payment) }) {
                Label("Export Receipt", systemImage: "arrow.down.doc")
            }
            
            Divider()
            
            Button(role: .destructive, action: { deletePayment(payment) }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadPayments() {
        payments = paymentService.fetchPayments(sortBy: sortOption)
    }
    
    private func printReceipt(_ payment: Payment) {
        guard let customer = coreDataManager.fetchCustomer(id: payment.customerId ?? UUID()) else {
            return
        }
        
        let invoice = payment.invoiceId != nil ? InvoiceService.shared.fetchInvoice(id: payment.invoiceId!) : nil
        
        let receiptGenerator = ReceiptGenerator.shared
        guard let pdfDocument = receiptGenerator.generateReceiptPDF(
            payment: payment,
            customer: customer,
            invoice: invoice,
            companyInfo: .default
        ) else {
            return
        }

        let printInfo = NSPrintInfo.shared
        let printView = PDFView(frame: .zero)
        printView.document = pdfDocument
        printView.autoScales = true

        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()

        paymentService.markReceiptGenerated(payment)
    }
    
    private func exportReceipt(_ payment: Payment) {
        guard let customer = coreDataManager.fetchCustomer(id: payment.customerId ?? UUID()) else {
            return
        }
        
        let invoice = payment.invoiceId != nil ? InvoiceService.shared.fetchInvoice(id: payment.invoiceId!) : nil
        
        let receiptGenerator = ReceiptGenerator.shared
        guard let pdfDocument = receiptGenerator.generateReceiptPDF(
            payment: payment,
            customer: customer,
            invoice: invoice,
            companyInfo: .default
        ) else {
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Receipt_\(payment.formattedPaymentNumber).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = receiptGenerator.saveReceipt(pdfDocument, to: url)
                paymentService.markReceiptGenerated(payment)
            }
        }
    }
    
    private func deletePayment(_ payment: Payment) {
        paymentService.deletePayment(payment)
        loadPayments()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Payment Row View

struct PaymentRowView: View {
    let payment: Payment
    private let coreDataManager = CoreDataManager.shared
    
    var customer: Customer? {
        guard let customerId = payment.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Payment method icon
            Image(systemName: payment.paymentMethodIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            // Payment info
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.formattedPaymentNumber)
                    .font(.headline)
                
                if let customer = customer {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, alignment: .leading)
            
            // Payment method
            Text(payment.paymentMethodDisplayName)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            // Date
            if let paymentDate = payment.paymentDate {
                Text(paymentDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
            }
            
            Spacer()
            
            // Amount
            Text(payment.formattedAmount)
                .font(.headline)
                .foregroundColor(.green)
            
            // Receipt indicator
            if payment.receiptGenerated {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .help("Receipt generated")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Quick Payment View

struct QuickPaymentView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedCustomer: Customer?
    @State private var selectedInvoice: Invoice?
    @State private var amount: String = ""
    @State private var paymentMethod = "cash"
    @State private var paymentDate = Date()
    @State private var referenceNumber = ""
    @State private var notes = ""
    @State private var showingCustomerPicker = false
    @State private var showingInvoicePicker = false
    
    private let paymentService = PaymentService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    if let customer = selectedCustomer {
                        HStack {
                            Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            Spacer()
                            Button("Change") {
                                showingCustomerPicker = true
                            }
                        }
                    } else {
                        Button("Select Customer") {
                            showingCustomerPicker = true
                        }
                    }
                }
                
                Section("Invoice (Optional)") {
                    if let invoice = selectedInvoice {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(invoice.formattedInvoiceNumber)
                                Text("Balance: \(formatCurrency(invoice.balance))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Change") {
                                showingInvoicePicker = true
                            }
                            Button("Remove") {
                                selectedInvoice = nil
                            }
                        }
                    } else {
                        Button("Link to Invoice") {
                            showingInvoicePicker = true
                        }
                        .disabled(selectedCustomer == nil)
                    }
                }
                
                Section("Payment Details") {
                    TextField("Amount", text: $amount)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("Cash").tag("cash")
                        Text("Credit/Debit Card").tag("card")
                        Text("Check").tag("check")
                        Text("Bank Transfer").tag("transfer")
                        Text("Other").tag("other")
                    }
                    
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Reference Number (Optional)", text: $referenceNumber)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Record Payment")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePayment()
                    }
                    .disabled(selectedCustomer == nil || amount.isEmpty)
                }
            }
        }
        .frame(width: 650, height: 650)
        .sheet(isPresented: $showingCustomerPicker) {
            CustomerPickerView(selectedCustomer: $selectedCustomer)
        }
        .sheet(isPresented: $showingInvoicePicker) {
            InvoicePickerView(customerId: selectedCustomer?.id, selectedInvoice: $selectedInvoice)
        }
        .onAppear {
            if let invoice = selectedInvoice {
                amount = String(describing: invoice.balance)
            }
        }
    }
    
    private func savePayment() {
        guard let customer = selectedCustomer,
              let amountValue = Decimal(string: amount) else {
            return
        }
        
        _ = paymentService.recordPayment(
            invoiceId: selectedInvoice?.id,
            customerId: customer.id ?? UUID(),
            amount: amountValue,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            referenceNumber: referenceNumber.isEmpty ? nil : referenceNumber,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Payment Detail View

struct PaymentDetailView: View {
    @Environment(\.dismiss) var dismiss
    let payment: Payment
    
    private let coreDataManager = CoreDataManager.shared
    private let paymentService = PaymentService.shared
    
    var customer: Customer? {
        guard let customerId = payment.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var invoice: Invoice? {
        guard let invoiceId = payment.invoiceId else { return nil }
        return InvoiceService.shared.fetchInvoice(id: invoiceId)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Payment amount (large)
                VStack(spacing: 8) {
                    Text("Payment Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(payment.formattedAmount)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                // Details
                Form {
                    Section("Payment Information") {
                        LabeledContent("Receipt #", value: payment.formattedPaymentNumber)
                        LabeledContent("Payment Method", value: payment.paymentMethodDisplayName)
                        
                        if let date = payment.paymentDate {
                            LabeledContent("Date", value: date.formatted(date: .long, time: .shortened))
                        }
                        
                        if let refNumber = payment.referenceNumber, !refNumber.isEmpty {
                            LabeledContent("Reference", value: refNumber)
                        }
                    }
                    
                    if let customer = customer {
                        Section("Customer") {
                            LabeledContent("Name", value: "\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            if let email = customer.email {
                                LabeledContent("Email", value: email)
                            }
                        }
                    }
                    
                    if let invoice = invoice {
                        Section("Invoice") {
                            LabeledContent("Invoice #", value: invoice.formattedInvoiceNumber)
                            LabeledContent("Total", value: formatCurrency(invoice.total))
                            LabeledContent("Balance", value: formatCurrency(invoice.balance))
                        }
                    }
                    
                    if let notes = payment.notes, !notes.isEmpty {
                        Section("Notes") {
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: printReceipt) {
                        Label("Print Receipt", systemImage: "printer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: exportReceipt) {
                        Label("Export Receipt", systemImage: "arrow.down.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("Payment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 700, height: 700)
    }
    
    private func printReceipt() {
        guard let customer = customer else { return }
        
        let receiptGenerator = ReceiptGenerator.shared
        guard let pdfDocument = receiptGenerator.generateReceiptPDF(
            payment: payment,
            customer: customer,
            invoice: invoice,
            companyInfo: .default
        ) else {
            return
        }

        let printInfo = NSPrintInfo.shared
        let printView = PDFView(frame: .zero)
        printView.document = pdfDocument
        printView.autoScales = true

        let printOperation = NSPrintOperation(view: printView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()

        paymentService.markReceiptGenerated(payment)
    }
    
    private func exportReceipt() {
        guard let customer = customer else { return }
        
        let receiptGenerator = ReceiptGenerator.shared
        guard let pdfDocument = receiptGenerator.generateReceiptPDF(
            payment: payment,
            customer: customer,
            invoice: invoice,
            companyInfo: .default
        ) else {
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Receipt_\(payment.formattedPaymentNumber).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = receiptGenerator.saveReceipt(pdfDocument, to: url)
                paymentService.markReceiptGenerated(payment)
            }
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

struct PaymentStatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(AppTheme.Typography.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(AppTheme.Spacing.md)
        .background(color.opacity(0.1))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
}

// MARK: - Invoice Picker View

struct InvoicePickerView: View {
    @Environment(\.dismiss) var dismiss
    let customerId: UUID?
    @Binding var selectedInvoice: Invoice?
    
    @State private var invoices: [Invoice] = []
    
    private let invoiceService = InvoiceService.shared
    
    var unpaidInvoices: [Invoice] {
        invoices.filter { $0.balance > 0 }
    }
    
    var body: some View {
        NavigationStack {
            List(unpaidInvoices) { invoice in
                Button(action: {
                    selectedInvoice = invoice
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(invoice.formattedInvoiceNumber)
                            .font(.headline)
                        
                        HStack {
                            Text("Total: \(formatCurrency(invoice.total))")
                            Text("•")
                            Text("Balance: \(formatCurrency(invoice.balance))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadInvoices()
        }
    }
    
    private func loadInvoices() {
        guard let customerId = customerId else { return }
        invoices = invoiceService.fetchInvoices(for: customerId)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Types

enum DateRangeFilter: String, CaseIterable {
    case all = "All Time"
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
}

// MARK: - Preview

struct PaymentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentHistoryView()
    }
}
