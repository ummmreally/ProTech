import Foundation
import CoreData

class EstimateService {
    static let shared = EstimateService()
    
    private let coreDataManager = CoreDataManager.shared
    private let invoiceService = InvoiceService.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Estimate Creation
    
    /// Create a new estimate
    func createEstimate(
        customerId: UUID,
        ticketId: UUID? = nil,
        validUntil: Date? = nil,
        notes: String? = nil,
        terms: String? = nil
    ) -> Estimate {
        let estimate = Estimate(context: context)
        estimate.id = UUID()
        estimate.estimateNumber = generateEstimateNumber()
        estimate.customerId = customerId
        estimate.ticketId = ticketId
        estimate.issueDate = Date()
        estimate.validUntil = validUntil ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())
        estimate.status = "pending"
        estimate.notes = notes
        estimate.terms = terms ?? defaultTerms()
        estimate.subtotal = 0
        estimate.taxRate = 0
        estimate.taxAmount = 0
        estimate.total = 0
        estimate.createdAt = Date()
        estimate.updatedAt = Date()
        
        coreDataManager.save()
        return estimate
    }
    
    /// Create estimate from a ticket
    func createEstimateFromTicket(_ ticket: Ticket) -> Estimate? {
        guard let customerId = ticket.customerId else { return nil }
        
        let estimate = createEstimate(
            customerId: customerId,
            ticketId: ticket.id,
            notes: "Estimate for \(ticket.deviceType ?? "device") repair - \(ticket.deviceModel ?? "")"
        )
        
        // Add a default line item based on ticket
        if let issueDescription = ticket.issueDescription {
            addLineItem(
                to: estimate,
                type: "service",
                description: issueDescription,
                quantity: 1,
                unitPrice: 0
            )
        }
        
        return estimate
    }
    
    // MARK: - Line Items
    
    /// Add a line item to an estimate
    @discardableResult
    func addLineItem(
        to estimate: Estimate,
        type: String,
        description: String,
        quantity: Decimal,
        unitPrice: Decimal
    ) -> EstimateLineItem {
        let lineItem = EstimateLineItem(context: context)
        lineItem.id = UUID()
        lineItem.estimateId = estimate.id
        lineItem.itemType = type
        lineItem.itemDescription = description
        lineItem.quantity = quantity
        lineItem.unitPrice = unitPrice
        lineItem.total = quantity * unitPrice
        lineItem.order = Int16(estimate.lineItemsArray.count)
        lineItem.createdAt = Date()
        lineItem.estimate = estimate
        
        estimate.addToLineItems(lineItem)
        recalculateEstimate(estimate)
        
        coreDataManager.save()
        return lineItem
    }
    
    /// Update a line item
    func updateLineItem(
        _ lineItem: EstimateLineItem,
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
        
        if let estimate = lineItem.estimate {
            recalculateEstimate(estimate)
        }
        
        coreDataManager.save()
    }
    
    /// Delete a line item
    func deleteLineItem(_ lineItem: EstimateLineItem) {
        guard let estimate = lineItem.estimate else { return }
        
        estimate.removeFromLineItems(lineItem)
        context.delete(lineItem)
        
        recalculateEstimate(estimate)
        coreDataManager.save()
    }
    
    // MARK: - Estimate Calculations
    
    /// Recalculate estimate totals
    func recalculateEstimate(_ estimate: Estimate) {
        let lineItems = estimate.lineItemsArray
        
        // Calculate subtotal
        let subtotal = lineItems.reduce(Decimal(0)) { $0 + $1.total }
        estimate.subtotal = subtotal
        
        // Calculate tax
        let taxAmount = subtotal * estimate.taxRate / 100
        estimate.taxAmount = taxAmount
        
        // Calculate total
        let total = subtotal + taxAmount
        estimate.total = total
        
        estimate.updatedAt = Date()
    }
    
    /// Update tax rate
    func updateTaxRate(_ estimate: Estimate, taxRate: Decimal) {
        estimate.taxRate = taxRate
        recalculateEstimate(estimate)
        coreDataManager.save()
    }
    
    // MARK: - Estimate Status
    
    /// Approve estimate
    func approveEstimate(_ estimate: Estimate) {
        estimate.status = "approved"
        estimate.approvedAt = Date()
        estimate.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Decline estimate
    func declineEstimate(_ estimate: Estimate) {
        estimate.status = "declined"
        estimate.declinedAt = Date()
        estimate.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Mark estimate as expired
    func markAsExpired(_ estimate: Estimate) {
        estimate.status = "expired"
        estimate.updatedAt = Date()
        coreDataManager.save()
    }
    
    /// Convert estimate to invoice
    func convertToInvoice(_ estimate: Estimate) -> Invoice? {
        guard estimate.status == "approved" || estimate.status == "pending" else {
            return nil
        }
        
        // Create invoice
        let invoice = invoiceService.createInvoice(
            customerId: estimate.customerId ?? UUID(),
            ticketId: estimate.ticketId,
            notes: estimate.notes,
            terms: estimate.terms
        )
        
        // Copy line items
        for (index, estimateItem) in estimate.lineItemsArray.enumerated() {
            let invoiceItem = invoiceService.addLineItem(
                to: invoice,
                type: estimateItem.itemType ?? "service",
                description: estimateItem.itemDescription ?? "",
                quantity: estimateItem.quantity,
                unitPrice: estimateItem.unitPrice
            )
            invoiceItem.order = Int16(index)
        }
        
        // Copy tax rate
        invoiceService.updateTaxRate(invoice, taxRate: estimate.taxRate)
        
        // Mark estimate as converted
        estimate.status = "converted"
        estimate.convertedToInvoiceId = invoice.id
        estimate.updatedAt = Date()
        coreDataManager.save()
        
        return invoice
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all estimates
    func fetchEstimates(sortBy: EstimateSortOption = .dateDesc) -> [Estimate] {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.sortDescriptors = sortBy.sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching estimates: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch estimates for a customer
    func fetchEstimates(for customerId: UUID) -> [Estimate] {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.issueDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching customer estimates: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch estimate by ID
    func fetchEstimate(id: UUID) -> Estimate? {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Fetch pending estimates
    func fetchPendingEstimates() -> [Estimate] {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.validUntil, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching pending estimates: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch expired estimates
    func fetchExpiredEstimates() -> [Estimate] {
        let now = Date()
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(
            format: "validUntil < %@ AND status == %@",
            now as NSDate, "pending"
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.validUntil, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching expired estimates: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch approved estimates
    func fetchApprovedEstimates() -> [Estimate] {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "approved")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.approvedAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching approved estimates: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete an estimate
    func deleteEstimate(_ estimate: Estimate) {
        context.delete(estimate)
        coreDataManager.save()
    }
    
    // MARK: - Helper Methods
    
    /// Generate unique estimate number
    private func generateEstimateNumber() -> String {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Estimate.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        let lastEstimate = try? context.fetch(request).first
        
        if let lastNumber = lastEstimate?.estimateNumber,
           let numberPart = lastNumber.split(separator: "-").last,
           let number = Int(numberPart) {
            return String(format: "EST-%04d", number + 1)
        }
        
        return "EST-0001"
    }
    
    /// Get default terms
    private func defaultTerms() -> String {
        return "This estimate is valid for 30 days. Prices are subject to change after expiration."
    }
    
    // MARK: - Statistics
    
    /// Get total value of pending estimates
    func getPendingEstimatesValue() -> Decimal {
        let estimates = fetchPendingEstimates()
        return estimates.reduce(Decimal(0)) { $0 + $1.total }
    }
    
    /// Get total value of approved estimates
    func getApprovedEstimatesValue() -> Decimal {
        let estimates = fetchApprovedEstimates()
        return estimates.reduce(Decimal(0)) { $0 + $1.total }
    }
    
    /// Get conversion rate (approved / total)
    func getConversionRate() -> Double {
        let allEstimates = fetchEstimates()
        guard !allEstimates.isEmpty else { return 0 }
        
        let approved = allEstimates.filter { $0.status == "approved" || $0.status == "converted" }.count
        return Double(approved) / Double(allEstimates.count) * 100
    }
}

// MARK: - Sort Options

enum EstimateSortOption: String, CaseIterable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case numberDesc = "Estimate # (High to Low)"
    case numberAsc = "Estimate # (Low to High)"
    case amountDesc = "Amount (High to Low)"
    case amountAsc = "Amount (Low to High)"
    case statusAsc = "Status"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .dateDesc:
            return [NSSortDescriptor(keyPath: \Estimate.issueDate, ascending: false)]
        case .dateAsc:
            return [NSSortDescriptor(keyPath: \Estimate.issueDate, ascending: true)]
        case .numberDesc:
            return [NSSortDescriptor(keyPath: \Estimate.estimateNumber, ascending: false)]
        case .numberAsc:
            return [NSSortDescriptor(keyPath: \Estimate.estimateNumber, ascending: true)]
        case .amountDesc:
            return [NSSortDescriptor(keyPath: \Estimate.total, ascending: false)]
        case .amountAsc:
            return [NSSortDescriptor(keyPath: \Estimate.total, ascending: true)]
        case .statusAsc:
            return [NSSortDescriptor(keyPath: \Estimate.status, ascending: true)]
        }
    }
}
