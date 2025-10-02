import SwiftUI
import PDFKit
import PDFKit

struct InvoiceDetailView: View {
    @Environment(\.dismiss) var dismiss
    
    let invoice: Invoice
    
    @State private var showingEditView = false
    @State private var showingPaymentView = false
    @State private var showingEmailSheet = false
    @State private var pdfDocument: PDFDocument?
    
    private let invoiceService = InvoiceService.shared
    private let coreDataManager = CoreDataManager.shared
    private let pdfGenerator = PDFGenerator.shared
    
    var customer: Customer? {
        guard let customerId = invoice.customerId else { return nil }
        return coreDataManager.fetchCustomer(id: customerId)
    }
    
    var ticket: Ticket? {
        guard let ticketId = invoice.ticketId else { return nil }
        let request = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", ticketId as CVarArg)
        return try? coreDataManager.viewContext.fetch(request).first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with status
                    headerSection
                    
                    Divider()
                    
                    // Customer info
                    customerSection
                    
                    if ticket != nil {
                        Divider()
                        ticketSection
                    }
                    
                    Divider()
                    
                    // Line items
                    lineItemsSection
                    
                    Divider()
                    
                    // Totals
                    totalsSection
                    
                    if let notes = invoice.notes, !notes.isEmpty {
                        Divider()
                        notesSection
                    }
                    
                    if let terms = invoice.terms, !terms.isEmpty {
                        Divider()
                        termsSection
                    }
                    
                    Divider()
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Invoice Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { showingEditView = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: exportPDF) {
                            Label("Export PDF", systemImage: "arrow.down.doc")
                        }
                        
                        Button(action: printInvoice) {
                            Label("Print", systemImage: "printer")
                        }
                        
                        Button(action: { showingEmailSheet = true }) {
                            Label("Email", systemImage: "envelope")
                        }
                        
                        Divider()
                        
                        if invoice.status == "draft" {
                            Button(action: markAsSent) {
                                Label("Mark as Sent", systemImage: "paperplane")
                            }
                        }
                        
                        if invoice.status != "paid" && invoice.status != "cancelled" {
                            Button(action: { showingPaymentView = true }) {
                                Label("Record Payment", systemImage: "dollarsign.circle")
                            }
                        }
                        
                        if invoice.status != "cancelled" {
                            Button(role: .destructive, action: cancelInvoice) {
                                Label("Cancel Invoice", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Label("Actions", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
        .frame(width: 900, height: 800)
        .sheet(isPresented: $showingEditView) {
            InvoiceGeneratorView(invoice: invoice)
        }
        .sheet(isPresented: $showingPaymentView) {
            PaymentRecordView(invoice: invoice)
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailInvoiceView(invoice: invoice, pdfDocument: pdfDocument)
        }
        .onAppear {
            generatePDF()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(invoice.formattedInvoiceNumber)
                        .font(.system(size: 32, weight: .bold))
                    
                    HStack(spacing: 16) {
                        if let issueDate = invoice.issueDate {
                            Label(issueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.subheadline)
                        }
                        
                        if let dueDate = invoice.dueDate {
                            Label("Due: \(dueDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(invoice.isOverdue ? .red : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status badge
                statusBadge
            }
            
            // Amount summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(invoice.total))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                if invoice.amountPaid > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Amount Paid")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(invoice.amountPaid))
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                }
                
                if invoice.balance > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Balance Due")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatCurrency(invoice.balance))
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var statusBadge: some View {
        Text(invoice.status?.capitalized ?? "Draft")
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
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
            return invoice.isOverdue ? .red : .orange
        }
    }
    
    // MARK: - Customer Section
    
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill To")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let customer = customer {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let email = customer.email {
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.secondary)
                            Text(email)
                        }
                        .font(.subheadline)
                    }
                    
                    if let phone = customer.phone {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.secondary)
                            Text(phone)
                        }
                        .font(.subheadline)
                    }
                    
                    if let address = customer.address {
                        HStack(alignment: .top) {
                            Image(systemName: "location")
                                .foregroundColor(.secondary)
                            Text(address)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Ticket Section
    
    private var ticketSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Ticket")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let ticket = ticket {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Ticket #\(ticket.ticketNumber)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        if let device = ticket.deviceType {
                            Text("\(device) - \(ticket.deviceModel ?? "")")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let status = ticket.status {
                            Text("Status: \(status)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Line Items Section
    
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Line Items")
                .font(.headline)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Description")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Qty")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 60, alignment: .trailing)
                    
                    Text("Unit Price")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 100, alignment: .trailing)
                    
                    Text("Total")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(width: 100, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                
                // Line items
                ForEach(invoice.lineItemsArray) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemDescription ?? "")
                                .font(.body)
                            
                            Text(item.itemType?.capitalized ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.formattedQuantity)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(item.formattedUnitPrice)
                            .frame(width: 100, alignment: .trailing)
                        
                        Text(item.formattedTotal)
                            .fontWeight(.semibold)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    
                    if item != invoice.lineItemsArray.last {
                        Divider()
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Totals Section
    
    private var totalsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(formatCurrency(invoice.subtotal))
            }
            
            if invoice.taxRate > 0 {
                HStack {
                    let taxRateValue = NSDecimalNumber(decimal: invoice.taxRate).doubleValue
                    let formattedTaxRate = String(format: "%.2f", taxRateValue)
                    Text("Tax (\(formattedTaxRate)%)")
                    Spacer()
                    Text(formatCurrency(invoice.taxAmount))
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(invoice.total))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            
            Text(invoice.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Terms Section
    
    private var termsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Payment Terms")
                .font(.headline)
            
            Text(invoice.terms ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button(action: exportPDF) {
                Label("Export PDF", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: printInvoice) {
                Label("Print", systemImage: "printer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: { showingEmailSheet = true }) {
                Label("Email", systemImage: "envelope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if invoice.status != "paid" && invoice.status != "cancelled" {
                Button(action: { showingPaymentView = true }) {
                    Label("Record Payment", systemImage: "dollarsign.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func generatePDF() {
        guard let customer = customer else { return }
        pdfDocument = pdfGenerator.generateInvoicePDF(
            invoice: invoice,
            customer: customer,
            companyInfo: .default
        )
    }
    
    private func exportPDF() {
        guard let pdfDocument = pdfDocument else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Invoice_\(invoice.formattedInvoiceNumber).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = pdfGenerator.savePDF(pdfDocument, to: url)
            }
        }
    }
    
    private func printInvoice() {
        guard let pdfDocument = pdfDocument else { return }

        let printInfo = NSPrintInfo.shared
        printInfo.topMargin = 0
        printInfo.bottomMargin = 0
        printInfo.leftMargin = 0
        printInfo.rightMargin = 0

        let pdfView = PDFView(frame: .zero)
        pdfView.document = pdfDocument
        pdfView.autoScales = true

        let printOperation = NSPrintOperation(view: pdfView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()
    }
    
    private func markAsSent() {
        invoiceService.markAsSent(invoice)
    }
    
    private func cancelInvoice() {
        invoiceService.cancelInvoice(invoice)
        dismiss()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Payment Record View

struct PaymentRecordView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let invoice: Invoice
    
    @State private var paymentAmount: String = ""
    @State private var paymentDate = Date()
    @State private var paymentMethod = "cash"
    @State private var notes = ""
    @State private var showingStripePayment = false
    @State private var showingSavedCards = false
    
    private let invoiceService = InvoiceService.shared
    
    var customer: Customer? {
        guard let customerId = invoice.customerId else { return nil }
        let request = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        return try? viewContext.fetch(request).first
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    HStack {
                        Text("Amount Due:")
                        Spacer()
                        Text(formatCurrency(invoice.balance))
                            .fontWeight(.bold)
                    }
                    
                    TextField("Payment Amount", text: $paymentAmount)
                        .textFieldStyle(.roundedBorder)
                    
                    DatePicker("Payment Date", selection: $paymentDate, displayedComponents: .date)
                    
                    Picker("Payment Method", selection: $paymentMethod) {
                        Text("Cash").tag("cash")
                        Text("Credit Card").tag("card")
                        Text("Check").tag("check")
                        Text("Bank Transfer").tag("transfer")
                        Text("Other").tag("other")
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
                
                // Stripe Payment Options
                Section("Card Payment") {
                    Button {
                        showingStripePayment = true
                    } label: {
                        HStack {
                            Image(systemName: "creditcard.fill")
                            Text("Pay with Credit Card")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if customer != nil {
                        Button {
                            showingSavedCards = true
                        } label: {
                            HStack {
                                Image(systemName: "wallet.pass.fill")
                                Text("Use Saved Card")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
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
                        recordPayment()
                    }
                    .disabled(paymentAmount.isEmpty)
                }
            }
        }
        .frame(width: 600, height: 650)
        .onAppear {
            paymentAmount = String(describing: invoice.balance)
        }
        .sheet(isPresented: $showingStripePayment) {
            if let customer = customer {
                StripePaymentView(
                    amount: invoice.balance,
                    currency: "usd",
                    customerId: customer.id,
                    description: "Invoice \(invoice.formattedInvoiceNumber)",
                    onSuccess: { transactionId in
                        handleStripePayment(transactionId: transactionId)
                    }
                )
            }
        }
        .sheet(isPresented: $showingSavedCards) {
            if let customer = customer, let customerId = customer.id {
                SavedCardsPaymentView(
                    customerId: customerId,
                    amount: invoice.balance,
                    description: "Invoice \(invoice.formattedInvoiceNumber)",
                    onSuccess: { transactionId in
                        handleStripePayment(transactionId: transactionId)
                    }
                )
            }
        }
    }
    
    private func handleStripePayment(transactionId: String) {
        // Record payment with Stripe transaction reference
        paymentMethod = "card"
        notes = "Stripe Transaction: \(transactionId)"
        guard let amount = Decimal(string: String(describing: invoice.balance)) else { return }
        invoiceService.recordPayment(invoice, amount: amount, date: Date())
        showingStripePayment = false
        showingSavedCards = false
        dismiss()
    }
    
    private func recordPayment() {
        guard let amount = Decimal(string: paymentAmount) else { return }
        invoiceService.recordPayment(invoice, amount: amount, date: paymentDate)
        dismiss()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Email Invoice View

struct EmailInvoiceView: View {
    @Environment(\.dismiss) var dismiss
    
    let invoice: Invoice
    let pdfDocument: PDFDocument?
    
    @State private var recipientEmail = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let coreDataManager = CoreDataManager.shared
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    TextField("Email Address", text: $recipientEmail)
                        .textFieldStyle(.roundedBorder)
                }
                
                Section("Email Content") {
                    TextField("Subject", text: $subject)
                        .textFieldStyle(.roundedBorder)
                    
                    TextEditor(text: $message)
                        .frame(height: 200)
                }
                
                Section {
                    Text("Invoice PDF will be attached to this email")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Email Invoice")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendEmail()
                    }
                    .disabled(recipientEmail.isEmpty || subject.isEmpty)
                }
            }
        }
        .frame(width: 650, height: 550)
        .onAppear {
            loadEmailDefaults()
        }
        .alert("Email", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadEmailDefaults() {
        if let customer = coreDataManager.fetchCustomer(id: invoice.customerId ?? UUID()) {
            recipientEmail = customer.email ?? ""
        }
        
        subject = "Invoice \(invoice.formattedInvoiceNumber) from ProTech"
        message = """
        Dear Customer,
        
        Please find attached invoice \(invoice.formattedInvoiceNumber) for your recent service.
        
        Amount Due: \(formatCurrency(invoice.balance))
        Due Date: \(invoice.dueDate?.formatted(date: .long, time: .omitted) ?? "")
        
        Thank you for your business!
        
        Best regards,
        ProTech
        """
    }
    
    private func sendEmail() {
        // TODO: Implement actual email sending
        // For now, just open default mail client
        
        guard let pdfDocument = pdfDocument,
              let pdfData = pdfDocument.dataRepresentation() else {
            alertMessage = "Failed to generate PDF"
            showingAlert = true
            return
        }
        
        // Save PDF temporarily
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Invoice_\(invoice.formattedInvoiceNumber).pdf")
        
        do {
            try pdfData.write(to: tempURL)
            
            // Open mail client with attachment
            let mailtoString = "mailto:\(recipientEmail)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
            
            if let url = URL(string: mailtoString) {
                NSWorkspace.shared.open(url)
                alertMessage = "Email client opened. Please attach the PDF manually from: \(tempURL.path)"
                showingAlert = true
            }
        } catch {
            alertMessage = "Failed to prepare email: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Preview

struct InvoiceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = CoreDataManager.shared.viewContext
        let invoice = Invoice(context: context)
        invoice.id = UUID()
        invoice.invoiceNumber = "INV-0001"
        invoice.status = "sent"
        invoice.total = 150.00
        
        return InvoiceDetailView(invoice: invoice)
    }
}
