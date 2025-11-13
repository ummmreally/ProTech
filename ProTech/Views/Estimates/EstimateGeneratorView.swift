//
//  EstimateGeneratorView.swift
//  ProTech
//
//  Create and edit estimates
//

import SwiftUI
import PDFKit

struct EstimateGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.lastName, ascending: true)]
    ) var customers: FetchedResults<Customer>
    
    var estimate: Estimate? = nil
    
    @State private var selectedCustomerId: UUID?
    @State private var selectedTicketId: UUID?
    @State private var lineItems: [EstimateLineItemData] = []
    @State private var validUntilDays = 30
    @State private var notes = ""
    @State private var taxRate: Double = 8.0
    @State private var savedEstimate: Estimate?
    @State private var showingEmailAlert = false
    @State private var emailAlertMessage = ""
    
    private let estimateService = EstimateService.shared
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Selection
                Section("Customer") {
                    Picker("Select Customer", selection: $selectedCustomerId) {
                        Text("Select a customer").tag(UUID?.none)
                        ForEach(customers) { customer in
                            if let id = customer.id {
                                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                    .tag(UUID?.some(id))
                            }
                        }
                    }
                }
                
                // Valid Until
                Section("Validity") {
                    Stepper("Valid for \(validUntilDays) days", value: $validUntilDays, in: 1...90)
                    if validUntilDays > 0 {
                        Text("Expires: \(expirationDate.formatted(date: .long, time: .omitted))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Line Items
                Section("Line Items") {
                    ForEach($lineItems) { $item in
                        LineItemEditor(item: $item, onDelete: {
                            lineItems.removeAll { $0.id == item.id }
                        })
                    }
                    
                    Button {
                        addLineItem()
                    } label: {
                        Label("Add Line Item", systemImage: "plus.circle.fill")
                    }
                }
                
                // Tax
                Section("Tax") {
                    HStack {
                        TextField("Tax Rate", value: $taxRate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("%")
                    }
                }
                
                // Totals
                Section("Summary") {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(subtotal))
                    }
                    
                    HStack {
                        Text("Tax (\(String(format: "%.1f", taxRate))%)")
                        Spacer()
                        Text(formatCurrency(taxAmount))
                    }
                    
                    HStack {
                        Text("Total")
                            .bold()
                        Spacer()
                        Text(formatCurrency(total))
                            .bold()
                    }
                }
                
                // Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(estimate == nil ? "New Estimate" : "Edit Estimate")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Menu {
                        Button("Save as Draft") {
                            saveEstimate(status: "pending")
                        }
                        
                        Button("Save & Send to Customer") {
                            saveEstimateAndEmail()
                        }
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            loadEstimate()
            if lineItems.isEmpty {
                addLineItem()
            }
        }
        .alert("Email Status", isPresented: $showingEmailAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(emailAlertMessage)
        }
    }
    
    private var subtotal: Decimal {
        lineItems.reduce(Decimal.zero) { $0 + (Decimal($1.quantity) * $1.unitPrice) }
    }
    
    private var taxAmount: Decimal {
        subtotal * Decimal(taxRate) / 100
    }
    
    private var total: Decimal {
        subtotal + taxAmount
    }
    
    private var expirationDate: Date {
        Calendar.current.date(byAdding: .day, value: validUntilDays, to: Date()) ?? Date()
    }
    
    private var isValid: Bool {
        selectedCustomerId != nil && !lineItems.isEmpty && lineItems.allSatisfy { !$0.itemDescription.isEmpty }
    }
    
    private func loadEstimate() {
        guard let estimate = estimate else { return }
        
        selectedCustomerId = estimate.customerId
        selectedTicketId = estimate.ticketId
        notes = estimate.notes ?? ""
        taxRate = NSDecimalNumber(decimal: estimate.taxRate).doubleValue
        
        if let validUntil = estimate.validUntil {
            validUntilDays = Calendar.current.dateComponents([.day], from: Date(), to: validUntil).day ?? 30
        }
        
        // Load line items from relationship
        lineItems = estimate.lineItemsArray.map { item in
            EstimateLineItemData(
                id: item.id ?? UUID(),
                itemType: item.itemType ?? "service",
                itemDescription: item.itemDescription ?? "",
                quantity: NSDecimalNumber(decimal: item.quantity).intValue,
                unitPrice: item.unitPrice
            )
        }
    }
    
    private func addLineItem() {
        lineItems.append(EstimateLineItemData(
            itemType: "service",
            itemDescription: "",
            quantity: 1,
            unitPrice: Decimal(0)
        ))
    }
    
    private func saveEstimateAndEmail() {
        guard let customerId = selectedCustomerId else { return }
        
        // First save the estimate
        let validUntilDate = Calendar.current.date(byAdding: .day, value: validUntilDays, to: Date()) ?? Date()
        let taxDecimal = Decimal(taxRate)
        
        let estimateToEmail: Estimate
        
        if let existingEstimate = estimate {
            existingEstimate.customerId = customerId
            existingEstimate.ticketId = selectedTicketId
            existingEstimate.validUntil = validUntilDate
            existingEstimate.notes = notes.isEmpty ? nil : notes
            existingEstimate.status = "pending"
            existingEstimate.taxRate = taxDecimal
            existingEstimate.updatedAt = Date()
            
            // Remove existing line items
            for item in existingEstimate.lineItemsArray {
                estimateService.deleteLineItem(item)
            }
            
            // Add updated line items
            for (index, itemData) in lineItems.enumerated() {
                let lineItem = estimateService.addLineItem(
                    to: existingEstimate,
                    type: itemData.itemType,
                    description: itemData.itemDescription,
                    quantity: Decimal(itemData.quantity),
                    unitPrice: itemData.unitPrice
                )
                lineItem.order = Int16(index)
            }
            
            estimateService.recalculateEstimate(existingEstimate)
            estimateToEmail = existingEstimate
        } else {
            // Create new
            let newEstimate = estimateService.createEstimate(
                customerId: customerId,
                ticketId: selectedTicketId,
                validUntil: validUntilDate,
                notes: notes.isEmpty ? nil : notes
            )
            newEstimate.status = "pending"
            newEstimate.taxRate = taxDecimal
            
            for (index, itemData) in lineItems.enumerated() {
                let lineItem = estimateService.addLineItem(
                    to: newEstimate,
                    type: itemData.itemType,
                    description: itemData.itemDescription,
                    quantity: Decimal(itemData.quantity),
                    unitPrice: itemData.unitPrice
                )
                lineItem.order = Int16(index)
            }
            
            estimateService.recalculateEstimate(newEstimate)
            estimateToEmail = newEstimate
        }
        
        try? viewContext.save()
        
        // Now send the email
        guard let customer = fetchCustomer(id: customerId) else {
            emailAlertMessage = "Could not find customer information"
            showingEmailAlert = true
            dismiss()
            return
        }
        
        // Generate PDF
        guard let pdfDocument = PDFGenerator.shared.generateEstimatePDF(
            estimate: estimateToEmail,
            customer: customer,
            companyInfo: CompanyInfo.default
        ) else {
            emailAlertMessage = "Failed to generate PDF"
            showingEmailAlert = true
            dismiss()
            return
        }
        
        // Send email
        let success = EmailService.shared.sendEstimate(
            estimate: estimateToEmail,
            customer: customer,
            pdfDocument: pdfDocument
        )
        
        if success {
            emailAlertMessage = "Estimate saved and email opened. Complete sending in Mail app."
            showingEmailAlert = true
        } else {
            emailAlertMessage = "Estimate saved but failed to send email. Check customer email address."
            showingEmailAlert = true
        }
        
        dismiss()
    }
    
    private func saveEstimate(status: String) {
        guard let customerId = selectedCustomerId else { return }
        let validUntilDate = Calendar.current.date(byAdding: .day, value: validUntilDays, to: Date()) ?? Date()
        let taxDecimal = Decimal(taxRate)
        
        if let existingEstimate = estimate {
            existingEstimate.customerId = customerId
            existingEstimate.ticketId = selectedTicketId
            existingEstimate.validUntil = validUntilDate
            existingEstimate.notes = notes.isEmpty ? nil : notes
            existingEstimate.status = status
            existingEstimate.taxRate = taxDecimal
            existingEstimate.updatedAt = Date()

            // Remove existing line items
            for item in existingEstimate.lineItemsArray {
                estimateService.deleteLineItem(item)
            }

            // Add updated line items
            for (index, itemData) in lineItems.enumerated() {
                let lineItem = estimateService.addLineItem(
                    to: existingEstimate,
                    type: itemData.itemType,
                    description: itemData.itemDescription,
                    quantity: Decimal(itemData.quantity),
                    unitPrice: itemData.unitPrice
                )
                lineItem.order = Int16(index)
            }
            
            estimateService.recalculateEstimate(existingEstimate)
            try? viewContext.save()
        } else {
            // Create new
            let newEstimate = estimateService.createEstimate(
                customerId: customerId,
                ticketId: selectedTicketId,
                validUntil: validUntilDate,
                notes: notes.isEmpty ? nil : notes
            )
            newEstimate.status = status
            newEstimate.taxRate = taxDecimal
            
            for (index, itemData) in lineItems.enumerated() {
                let lineItem = estimateService.addLineItem(
                    to: newEstimate,
                    type: itemData.itemType,
                    description: itemData.itemDescription,
                    quantity: Decimal(itemData.quantity),
                    unitPrice: itemData.unitPrice
                )
                lineItem.order = Int16(index)
            }
            
            estimateService.recalculateEstimate(newEstimate)
            try? viewContext.save()
        }
        
        dismiss()
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
    
    private func fetchCustomer(id: UUID) -> Customer? {
        let request = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
}

// MARK: - Line Item Editor

struct LineItemEditor: View {
    @Binding var item: EstimateLineItemData
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Type", selection: $item.itemType) {
                    Text("Service").tag("service")
                    Text("Part").tag("part")
                    Text("Labor").tag("labor")
                    Text("Other").tag("other")
                }
                .frame(width: 120)
                
                Spacer()
                
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            
            TextField("Description", text: $item.itemDescription)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Stepper("Qty: \(item.quantity)", value: $item.quantity, in: 1...100)
                    .frame(width: 150)
                
                Spacer()
                
                TextField("Price", value: $item.unitPrice, format: .currency(code: "USD"))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
                
                Text("=")
                    .foregroundColor(.secondary)
                
                Text(formatCurrency(Decimal(item.quantity) * item.unitPrice))
                    .frame(width: 100, alignment: .trailing)
                    .bold()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatCurrency(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: value as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Estimate Line Item Data

struct EstimateLineItemData: Identifiable, Codable {
    var id = UUID()
    var itemType: String
    var itemDescription: String
    var quantity: Int
    var unitPrice: Decimal
}
