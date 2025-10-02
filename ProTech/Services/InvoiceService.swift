import Foundation
import CoreData

class InvoiceService {
    static let shared = InvoiceService()
    
    private let coreDataManager = CoreDataManager.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Invoice Creation
    
    /// Create a new invoice
    func createInvoice(
        customerId: UUID,
        ticketId: UUID? = nil,
        dueDate: Date? = nil,
        notes: String? = nil,
        terms: String? = nil
    ) -> Invoice {
        let invoice = Invoice(context: context)
        invoice.id = UUID()
        invoice.invoiceNumber = generateInvoiceNumber()
        invoice.customerId = customerId
        invoice.ticketId = ticketId
        invoice.issueDate = Date()
        invoice.dueDate = dueDate ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())
        invoice.status = "draft"
        invoice.notes = notes
        invoice.terms = terms ?? defaultTerms()
        invoice.subtotal = 0
        invoice.taxRate = 0
        invoice.taxAmount = 0
        invoice.total = 0
        invoice.amountPaid = 0
        invoice.balance = 0
        invoice.createdAt = Date()
        invoice.updatedAt = Date()
        
        coreDataManager.save()
        return invoice
    }
    
    /// Create invoice from a ticket
    func createInvoiceFromTicket(_ ticket: Ticket) -> Invoice? {
        guard let customerId = ticket.customerId else { return nil }
        
        let invoice = createInvoice(
            customerId: customerId,
            ticketId: ticket.id,
            notes: "Repair service for \(ticket.deviceType ?? "device") - \(ticket.deviceModel ?? "")"
        )
        
        // Add a default line item based on ticket
        if let issueDescription = ticket.issueDescription {
            addLineItem(
                to: invoice,
                type: "service",
                description: issueDescription,
                quantity: 1,
                unitPrice: 0
            )
        }
        
        return invoice
    }
    
    // MARK: - Line Items
    
    /// Add a line item to an invoice
    @discardableResult
    func addLineItem(
        to invoice: Invoice,
        type: String,
        description: String,
        quantity: Decimal,
        unitPrice: Decimal
    ) -> InvoiceLineItem {
        let lineItem = InvoiceLineItem(context: context)
        lineItem.id = UUID()
        lineItem.invoiceId = invoice.id
        lineItem.itemType = type
        lineItem.itemDescription = description
        lineItem.quantity = quantity
        lineItem.unitPrice = unitPrice
        lineItem.total = quantity * unitPrice
        lineItem.order = Int16(invoice.lineItemsArray.count)
        lineItem.createdAt = Date()
        lineItem.invoice = invoice
        
        invoice.addToLineItems(lineItem)
        recalculateInvoice(invoice)
        
        coreDataManager.save()
        return lineItem
    }
    
    /// Update a line item
    func updateLineItem(
        _ lineItem: InvoiceLineItem,
        type: String? = nil,
        description: String? = nil,
        quantity: Decimal? = nil,
        unitPrice: Decimal? = nil
    ) {
        if let type = type {
            lineItem.itemType = type
        }
        if let description = description {
            lineItem.itemDescription = description
        }
        if let quantity = quantity {
            lineItem.quantity = quantity
        }
        if let unitPrice = unitPrice {
            lineItem.unitPrice = unitPrice
        }
        
        lineItem.total = lineItem.quantity * lineItem.unitPrice
        
        if let invoice = lineItem.invoice {
            recalculateInvoice(invoice)
        }
        
        coreDataManager.save()
    }
    
    /// Delete a line item
    func deleteLineItem(_ lineItem: InvoiceLineItem) {
        guard let invoice = lineItem.invoice else { return }
        
        invoice.removeFromLineItems(lineItem)
        context.delete(lineItem)
        
        recalculateInvoice(invoice)
        coreDataManager.save()
    }
    
    // MARK: - Invoice Calculations
    
    /// Recalculate invoice totals
    func recalculateInvoice(_ invoice: Invoice) {
        let lineItems = invoice.lineItemsArray
        
        // Calculate subtotal
        let subtotal = lineItems.reduce(Decimal(0)) { $0 + $1.total }
        invoice.subtotal = subtotal
        
        // Calculate tax
        let taxAmount = subtotal * invoice.taxRate / 100
        invoice.taxAmount = taxAmount
        
        // Calculate total
        let total = subtotal + taxAmount
        invoice.total = total
        
        // Calculate balance
        invoice.balance = total - invoice.amountPaid
        
        invoice.updatedAt = Date()
    }
    
    /// Update tax rate
    func updateTaxRate(_ invoice: Invoice, taxRate: Decimal) {
        invoice.taxRate = taxRate
        recalculateInvoice(invoice)
        coreDataManager.save()
    }
    
    // MARK: - Invoice Status
    
    /// Mark invoice as sent
    func markAsSent(_ invoice: Invoice) {
        invoice.status = "sent"
        invoice.sentAt = Date()
        invoice.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Mark invoice as paid
    func markAsPaid(_ invoice: Invoice, paymentAmount: Decimal? = nil, paymentDate: Date? = nil) {
        let amount = paymentAmount ?? invoice.total
        invoice.amountPaid = amount
        invoice.balance = invoice.total - amount
        
        if invoice.balance <= 0 {
            invoice.status = "paid"
            invoice.paidAt = paymentDate ?? Date()
        }
        
        invoice.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Record partial payment
    func recordPayment(_ invoice: Invoice, amount: Decimal, date: Date? = nil) {
        invoice.amountPaid += amount
        invoice.balance = invoice.total - invoice.amountPaid
        
        if invoice.balance <= 0 {
            invoice.status = "paid"
            invoice.paidAt = date ?? Date()
        }
        
        invoice.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Cancel invoice
    func cancelInvoice(_ invoice: Invoice) {
        invoice.status = "cancelled"
        invoice.updatedAt = Date()
        coreDataManager.save()
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all invoices
    func fetchInvoices(sortBy: InvoiceSortOption = .dateDesc) -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.sortDescriptors = sortBy.sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching invoices: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch invoices for a customer
    func fetchInvoices(for customerId: UUID) -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching customer invoices: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch invoice by ID
    func fetchInvoice(id: UUID) -> Invoice? {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Fetch unpaid invoices
    func fetchUnpaidInvoices() -> [Invoice] {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@", "paid", "cancelled")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.dueDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching unpaid invoices: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch overdue invoices
    func fetchOverdueInvoices() -> [Invoice] {
        let now = Date()
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(
            format: "dueDate < %@ AND status != %@ AND status != %@",
            now as NSDate, "paid", "cancelled"
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.dueDate, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching overdue invoices: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete an invoice
    func deleteInvoice(_ invoice: Invoice) {
        context.delete(invoice)
        coreDataManager.save()
    }
    
    // MARK: - Helper Methods
    
    /// Generate unique invoice number
    private func generateInvoiceNumber() -> String {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Invoice.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        let lastInvoice = try? context.fetch(request).first
        
        if let lastNumber = lastInvoice?.invoiceNumber,
           let numberPart = lastNumber.split(separator: "-").last,
           let number = Int(numberPart) {
            return String(format: "INV-%04d", number + 1)
        }
        
        return "INV-0001"
    }
    
    /// Get default payment terms
    private func defaultTerms() -> String {
        return "Payment is due within 30 days of invoice date. Late payments may be subject to fees."
    }
    
    // MARK: - Statistics
    
    /// Get total revenue from paid invoices
    func getTotalRevenue() -> Decimal {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "paid")
        
        do {
            let invoices = try context.fetch(request)
            return invoices.reduce(Decimal(0)) { $0 + $1.total }
        } catch {
            return 0
        }
    }
    
    /// Get outstanding balance
    func getOutstandingBalance() -> Decimal {
        let request: NSFetchRequest<Invoice> = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@ AND status != %@", "paid", "cancelled")
        
        do {
            let invoices = try context.fetch(request)
            return invoices.reduce(Decimal(0)) { $0 + $1.balance }
        } catch {
            return 0
        }
    }
}

// MARK: - Sort Options

enum InvoiceSortOption: String, CaseIterable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case numberDesc = "Invoice # (High to Low)"
    case numberAsc = "Invoice # (Low to High)"
    case amountDesc = "Amount (High to Low)"
    case amountAsc = "Amount (Low to High)"
    case statusAsc = "Status"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .dateDesc:
            return [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: false)]
        case .dateAsc:
            return [NSSortDescriptor(keyPath: \Invoice.issueDate, ascending: true)]
        case .numberDesc:
            return [NSSortDescriptor(keyPath: \Invoice.invoiceNumber, ascending: false)]
        case .numberAsc:
            return [NSSortDescriptor(keyPath: \Invoice.invoiceNumber, ascending: true)]
        case .amountDesc:
            return [NSSortDescriptor(keyPath: \Invoice.total, ascending: false)]
        case .amountAsc:
            return [NSSortDescriptor(keyPath: \Invoice.total, ascending: true)]
        case .statusAsc:
            return [NSSortDescriptor(keyPath: \Invoice.status, ascending: true)]
        }
    }
}
