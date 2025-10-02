//
//  RecurringInvoiceService.swift
//  ProTech
//
//  Manage recurring invoices and automatic generation
//

import Foundation
import CoreData

class RecurringInvoiceService {
    static let shared = RecurringInvoiceService()
    
    private let coreDataManager = CoreDataManager.shared
    private let invoiceService = InvoiceService.shared
    private let stripeService = StripeService.shared
    
    private init() {}
    
    // MARK: - CRUD Operations
    
    func createRecurringInvoice(customerId: UUID, name: String, frequency: String, interval: Int = 1, startDate: Date = Date(), lineItems: [LineItemData], taxRate: Decimal = 0, autoSend: Bool = true, autoCharge: Bool = false, paymentMethodId: UUID? = nil) -> RecurringInvoice {
        let context = coreDataManager.viewContext
        
        let subtotal = lineItems.reduce(Decimal.zero) { $0 + $1.total }
        
        let recurring = RecurringInvoice(
            context: context,
            customerId: customerId,
            name: name,
            frequency: frequency,
            interval: interval,
            startDate: startDate,
            subtotal: subtotal,
            taxRate: taxRate,
            autoSend: autoSend
        )
        
        recurring.autoCharge = autoCharge
        recurring.paymentMethodId = paymentMethodId
        recurring.setLineItems(lineItems)
        
        try? context.save()
        
        return recurring
    }
    
    func updateRecurringInvoice(_ recurring: RecurringInvoice, name: String? = nil, lineItems: [LineItemData]? = nil, taxRate: Decimal? = nil, autoSend: Bool? = nil, autoCharge: Bool? = nil) {
        if let name = name {
            recurring.name = name
        }
        
        if let lineItems = lineItems {
            recurring.setLineItems(lineItems)
            let subtotal = lineItems.reduce(Decimal.zero) { $0 + $1.total }
            recurring.subtotal = subtotal
        }
        
        if let taxRate = taxRate {
            recurring.taxRate = taxRate
        }
        
        // Recalculate tax and total
        recurring.taxAmount = recurring.subtotal * (recurring.taxRate / 100)
        recurring.total = recurring.subtotal + recurring.taxAmount
        
        if let autoSend = autoSend {
            recurring.autoSend = autoSend
        }
        
        if let autoCharge = autoCharge {
            recurring.autoCharge = autoCharge
        }
        
        recurring.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func activateRecurringInvoice(_ recurring: RecurringInvoice) {
        recurring.isActive = true
        recurring.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func pauseRecurringInvoice(_ recurring: RecurringInvoice) {
        recurring.isActive = false
        recurring.updatedAt = Date()
        try? coreDataManager.viewContext.save()
    }
    
    func deleteRecurringInvoice(_ recurring: RecurringInvoice) {
        coreDataManager.viewContext.delete(recurring)
        try? coreDataManager.viewContext.save()
    }
    
    // MARK: - Invoice Generation
    
    func processScheduledInvoices() {
        let dueInvoices = RecurringInvoice.fetchDueRecurringInvoices(context: coreDataManager.viewContext)
        
        for recurring in dueInvoices {
            _ = generateInvoice(from: recurring)
        }
    }
    
    func generateInvoice(from recurring: RecurringInvoice) -> Invoice? {
        guard let customerId = recurring.customerId else {
            recordFailure(for: recurring, error: "No customer ID")
            return nil
        }
        
        let context = coreDataManager.viewContext
        
        // Create invoice
        let invoice = Invoice(context: context)
        invoice.id = UUID()
        invoice.customerId = customerId
        invoice.invoiceNumber = generateInvoiceNumber()
        invoice.issueDate = Date()
        invoice.dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "sent"
        invoice.subtotal = recurring.subtotal
        invoice.taxRate = recurring.taxRate
        invoice.taxAmount = recurring.taxAmount
        invoice.total = recurring.total
        invoice.notes = recurring.notes
        invoice.terms = recurring.terms
        invoice.amountPaid = 0
        invoice.balance = recurring.total
        invoice.createdAt = Date()
        invoice.notes = recurring.notes
        invoice.terms = recurring.terms
        invoice.amountPaid = 0
        invoice.balance = recurring.total
        invoice.createdAt = Date()
        
        // Add line items
        var order: Int16 = 0
        for item in recurring.lineItems {
            let lineItem = InvoiceLineItem(context: context)
            lineItem.id = UUID()
            lineItem.invoiceId = invoice.id
            lineItem.itemDescription = item.description
            lineItem.itemType = item.itemType
            lineItem.quantity = item.quantity
            lineItem.unitPrice = item.unitPrice
            lineItem.total = item.total
            lineItem.order = order
            order += 1
        }
        
        try? context.save()
        
        // Send email if auto-send is enabled
        if recurring.autoSend {
            sendInvoiceEmail(invoice: invoice, customerId: customerId)
        }
        
        // Auto-charge if enabled
        if recurring.autoCharge, let paymentMethodId = recurring.paymentMethodId {
            Task {
                do {
                    _ = try await stripeService.processPayment(
                        amount: recurring.total,
                        currency: recurring.currency ?? "USD",
                        customerId: customerId,
                        invoiceId: invoice.id,
                        paymentMethodId: paymentMethodId.uuidString
                    )
                    recordSuccess(for: recurring)
                } catch {
                    recordFailure(for: recurring, error: error.localizedDescription)
                }
            }
        } else {
            recordSuccess(for: recurring)
        }
        
        // Update recurring invoice
        recurring.lastInvoiceDate = Date()
        recurring.calculateNextInvoiceDate()
        recurring.invoiceCount += 1
        recurring.totalRevenue += recurring.total
        
        try? context.save()
        
        return invoice
    }
    
    func generateInvoiceManually(from recurring: RecurringInvoice) -> Invoice? {
        return generateInvoice(from: recurring)
    }
    
    // MARK: - Statistics
    
    func getRecurringInvoiceStats() -> RecurringInvoiceStats {
        let request = RecurringInvoice.fetchRequest()
        let allRecurring = (try? coreDataManager.viewContext.fetch(request)) ?? []
        
        let active = allRecurring.filter { $0.isActive }.count
        let totalRevenue = allRecurring.reduce(Decimal.zero) { $0 + $1.totalRevenue }
        let monthlyRecurringRevenue = calculateMRR(from: allRecurring)
        let totalInvoices = allRecurring.reduce(0) { $0 + Int($1.invoiceCount) }
        
        return RecurringInvoiceStats(
            activeRecurring: active,
            totalRecurring: allRecurring.count,
            totalRevenue: totalRevenue,
            monthlyRecurringRevenue: monthlyRecurringRevenue,
            totalInvoicesGenerated: totalInvoices
        )
    }
    
    private func calculateMRR(from recurring: [RecurringInvoice]) -> Decimal {
        return recurring.filter { $0.isActive }.reduce(Decimal.zero) { total, recurring in
            let monthlyValue: Decimal
            switch recurring.frequency {
            case "daily":
                monthlyValue = recurring.total * 30 / Decimal(recurring.interval)
            case "weekly":
                monthlyValue = recurring.total * 4 / Decimal(recurring.interval)
            case "monthly":
                monthlyValue = recurring.total / Decimal(recurring.interval)
            case "quarterly":
                monthlyValue = recurring.total / Decimal(recurring.interval * 3)
            case "yearly":
                monthlyValue = recurring.total / Decimal(recurring.interval * 12)
            default:
                monthlyValue = 0
            }
            return total + monthlyValue
        }
    }
    
    // MARK: - Helpers
    
    private func generateInvoiceNumber() -> String {
        let request = Invoice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "invoiceNumber", ascending: false)]
        request.fetchLimit = 1
        
        if let lastInvoice = try? coreDataManager.viewContext.fetch(request).first,
           let lastNumber = lastInvoice.invoiceNumber,
           let number = Int(lastNumber.replacingOccurrences(of: "INV-", with: "")) {
            return String(format: "INV-%04d", number + 1)
        }
        
        return "INV-0001"
    }
    
    private func sendInvoiceEmail(invoice: Invoice, customerId: UUID) {
        guard let customer = coreDataManager.fetchCustomer(id: customerId),
              let email = customer.email else { return }
        
        // In production, send via email service
        print("📧 Sending recurring invoice \(invoice.invoiceNumber ?? "") to \(email)")
        
        // TODO: Integrate with actual email service
    }
    
    private func recordSuccess(for recurring: RecurringInvoice) {
        recurring.successfulCount += 1
        try? coreDataManager.viewContext.save()
    }
    
    private func recordFailure(for recurring: RecurringInvoice, error: String) {
        recurring.failedCount += 1
        try? coreDataManager.viewContext.save()
        
        print("❌ Failed to generate invoice: \(error)")
        
        // TODO: Send failure notification to admin
    }
}

// MARK: - Statistics

struct RecurringInvoiceStats {
    let activeRecurring: Int
    let totalRecurring: Int
    let totalRevenue: Decimal
    let monthlyRecurringRevenue: Decimal
    let totalInvoicesGenerated: Int
    
    var formattedRevenue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: totalRevenue as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedMRR: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: monthlyRecurringRevenue as NSDecimalNumber) ?? "$0.00"
    }
}
