//
//  EstimateDetailView.swift
//  ProTech
//
//  Detailed view of estimate with approval actions
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers
import CoreData

struct EstimateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var estimate: Estimate
    
    @State private var showingEditView = false
    @State private var showingEmailSheet = false
    @State private var showingApprovalConfirm = false
    @State private var showingDeclineConfirm = false
    @State private var pdfDocument: PDFDocument?
    
    private let estimateService = EstimateService.shared
    
    var customer: Customer? {
        guard let customerId = estimate.customerId else { return nil }
        let request = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        return try? viewContext.fetch(request).first
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Customer
                    customerSection
                    
                    Divider()
                    
                    // Line Items
                    lineItemsSection
                    
                    Divider()
                    
                    // Totals
                    totalsSection
                    
                    if let notes = estimate.notes, !notes.isEmpty {
                        Divider()
                        notesSection
                    }
                    
                    Divider()
                    
                    // Actions
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Estimate Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingEditView = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .disabled(estimate.status != "pending")
                        
                        Button {
                            exportPDF()
                        } label: {
                            Label("Export PDF", systemImage: "arrow.down.doc")
                        }
                        
                        Button {
                            printEstimate()
                        } label: {
                            Label("Print", systemImage: "printer")
                        }
                        
                        Button {
                            showingEmailSheet = true
                        } label: {
                            Label("Email to Customer", systemImage: "envelope")
                        }
                        
                        Divider()
                        
                        if estimate.status == "pending" {
                            Button {
                                showingApprovalConfirm = true
                            } label: {
                                Label("Approve", systemImage: "checkmark.circle")
                            }
                            
                            Button {
                                showingDeclineConfirm = true
                            } label: {
                                Label("Decline", systemImage: "xmark.circle")
                            }
                        }
                        
                        if estimate.status == "approved" {
                            Button {
                                convertToInvoice()
                            } label: {
                                Label("Convert to Invoice", systemImage: "doc.text.fill")
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
            EstimateGeneratorView(estimate: estimate)
        }
        .sheet(isPresented: $showingEmailSheet) {
            EmailEstimateView(estimate: estimate, customer: customer, pdfDocument: pdfDocument)
        }
        .alert("Approve Estimate", isPresented: $showingApprovalConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Approve") {
                estimateService.approveEstimate(estimate)
            }
        } message: {
            Text("Are you sure you want to approve this estimate?")
        }
        .alert("Decline Estimate", isPresented: $showingDeclineConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Decline", role: .destructive) {
                estimateService.declineEstimate(estimate)
            }
        } message: {
            Text("Are you sure you want to decline this estimate?")
        }
        .onAppear {
            generatePDF()
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(estimate.formattedEstimateNumber)
                        .font(.system(size: 32, weight: .bold))
                    
                    HStack(spacing: 16) {
                        if let created = estimate.createdAt {
                            Label(created.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.subheadline)
                        }
                        
                        if let validUntil = estimate.validUntil {
                            Label("Valid until: \(validUntil.formatted(date: .abbreviated, time: .omitted))", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(estimate.isExpired ? .red : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                statusBadge
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(estimate.total))
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    private var statusBadge: some View {
        Text(statusText)
            .font(.headline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(8)
    }
    
    private var statusText: String {
        if estimate.isExpired {
            return "Expired"
        }
        return estimate.status?.capitalized ?? "Pending"
    }
    
    private var statusColor: Color {
        if estimate.isExpired {
            return .orange
        }
        switch estimate.status {
        case "approved": return .green
        case "declined": return .red
        default: return .blue
        }
    }
    
    // MARK: - Customer Section
    
    private var customerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Customer")
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
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Line Items
    
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
                
                // Items
                ForEach(estimate.lineItemsArray) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.itemDescription ?? "Line Item")
                                .font(.body)
                            Text((item.itemType ?? "service").capitalized)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.formattedQuantity)
                            .frame(width: 60, alignment: .trailing)
                        
                        Text(formatCurrency(item.unitPrice))
                            .frame(width: 100, alignment: .trailing)
                        
                        Text(formatCurrency(item.total))
                            .fontWeight(.semibold)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                    
                    if item.id != estimate.lineItemsArray.last?.id {
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
    
    // MARK: - Totals
    
    private var totalsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Subtotal")
                Spacer()
                Text(formatCurrency(estimate.subtotal))
            }
            
            if estimate.taxRate > 0 {
                HStack {
                    let taxRateValue = NSDecimalNumber(decimal: estimate.taxRate).doubleValue
                    Text("Tax (\(String(format: "%.2f", taxRateValue))%)")
                    Spacer()
                    Text(formatCurrency(estimate.taxAmount))
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Text(formatCurrency(estimate.total))
                    .font(.title3)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Notes
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
            Text(estimate.notes ?? "")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            Button {
                exportPDF()
            } label: {
                Label("Export PDF", systemImage: "arrow.down.doc")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                printEstimate()
            } label: {
                Label("Print", systemImage: "printer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            if estimate.status == "pending" {
                Button {
                    showingApprovalConfirm = true
                } label: {
                    Label("Approve", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            
            if estimate.status == "approved" {
                Button {
                    convertToInvoice()
                } label: {
                    Label("Convert to Invoice", systemImage: "doc.text.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Actions
    
    private func generatePDF() {
        guard let customer = customer else { return }
        pdfDocument = PDFGenerator.shared.generateEstimatePDF(
            estimate: estimate,
            customer: customer,
            companyInfo: CompanyInfo.default
        )
    }
    
    private func exportPDF() {
        guard let pdfDocument = pdfDocument else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "Estimate_\(estimate.formattedEstimateNumber).pdf"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                _ = PDFGenerator.shared.savePDF(pdfDocument, to: url)
            }
        }
    }
    
    private func printEstimate() {
        guard let pdfDocument = pdfDocument else { return }
        
        let printInfo = NSPrintInfo.shared
        let pdfView = PDFView(frame: .zero)
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        
        let printOperation = NSPrintOperation(view: pdfView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()
    }
    
    private func convertToInvoice() {
        if estimateService.convertToInvoice(estimate) != nil {
            dismiss()
        }
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Email Estimate View

struct EmailEstimateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let estimate: Estimate
    let customer: Customer?
    let pdfDocument: PDFDocument?
    
    @State private var recipientEmail = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    TextField("Email Address", text: $recipientEmail)
                }
                
                Section("Message") {
                    TextField("Subject", text: $subject)
                    TextEditor(text: $message)
                        .frame(height: 200)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Email Estimate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendEmail()
                    }
                    .disabled(recipientEmail.isEmpty)
                }
            }
        }
        .frame(width: 600, height: 500)
        .onAppear {
            // Pre-fill customer email
            if let customerEmail = customer?.email {
                recipientEmail = customerEmail
            }
            subject = "Estimate \(estimate.formattedEstimateNumber)"
            message = "Please find attached estimate for your review."
        }
        .alert("Email Status", isPresented: $showingAlert) {
            Button("OK") { 
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendEmail() {
        guard let pdfDocument = pdfDocument else {
            alertMessage = "Failed to generate PDF document"
            showingAlert = true
            return
        }
        
        guard let customer = customer else {
            alertMessage = "Customer information not available"
            showingAlert = true
            return
        }
        
        let success = EmailService.shared.sendEstimate(
            estimate: estimate,
            customer: customer,
            pdfDocument: pdfDocument
        )
        
        if success {
            alertMessage = "Email sent successfully! Check your Mail app to complete sending."
            showingAlert = true
        } else {
            alertMessage = "Failed to send email. Please check the customer's email address."
            showingAlert = true
        }
    }
}
