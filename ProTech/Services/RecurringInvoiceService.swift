//
//  RecurringInvoiceService.swift
//  ProTech
//
//  Manage recurring invoices and automatic generation
//

import Foundation
import CoreData
import PDFKit

// MARK: - Retry Configuration

struct RetryConfiguration {
    let maxAttempts: Int
    let initialDelay: TimeInterval
    let maxDelay: TimeInterval
    let backoffMultiplier: Double
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        initialDelay: 60, // 1 minute
        maxDelay: 3600, // 1 hour
        backoffMultiplier: 2.0
    )
    
    func delayForAttempt(_ attempt: Int) -> TimeInterval {
        let delay = initialDelay * pow(backoffMultiplier, Double(attempt - 1))
        return min(delay, maxDelay)
    }
}

// MARK: - Failed Invoice Tracking

struct FailedInvoiceAttempt: Codable {
    let invoiceId: UUID
    let recurringInvoiceId: UUID
    let customerId: UUID
    var attemptCount: Int
    var nextRetryTime: Date
    var lastError: String?
    let firstFailedAt: Date
    var lastAttemptAt: Date
    
    init(invoiceId: UUID, recurringInvoiceId: UUID, customerId: UUID, error: String) {
        self.invoiceId = invoiceId
        self.recurringInvoiceId = recurringInvoiceId
        self.customerId = customerId
        self.attemptCount = 1
        self.lastError = error
        self.firstFailedAt = Date()
        self.lastAttemptAt = Date()
        
        // Calculate next retry time with initial delay
        self.nextRetryTime = Date().addingTimeInterval(RetryConfiguration.default.initialDelay)
    }
}

class RecurringInvoiceService {
    static let shared = RecurringInvoiceService()
    
    private let coreDataManager = CoreDataManager.shared
    private let invoiceService = InvoiceService.shared
    private let stripeService = StripeService.shared
    private let retryConfig = RetryConfiguration.default
    
    // In-memory tracking of failed invoice attempts
    private var failedAttempts: [UUID: FailedInvoiceAttempt] = [:]
    private var retryTimer: Timer?
    
    private init() {
        startRetryTimer()
    }
    
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
              let email = customer.email,
              let invoiceId = invoice.id else { 
            print("❌ No customer email found for recurring invoice")
            return
        }
        
        // Generate PDF for the invoice
        guard let pdfDocument = PDFGenerator.shared.generateInvoicePDF(
            invoice: invoice,
            customer: customer,
            companyInfo: CompanyInfo.default
        ) else {
            print("❌ Failed to generate PDF for recurring invoice \(invoice.invoiceNumber ?? "")")
            trackFailedAttempt(invoiceId: invoiceId, customerId: customerId, error: "Failed to generate PDF")
            return
        }
        
        // Send via email service with retry support
        Task {
            do {
                try await EmailService.shared.sendRecurringInvoice(
                    invoice: invoice,
                    customer: customer,
                    pdfDocument: pdfDocument
                )
                print("✅ Sent recurring invoice \(invoice.invoiceNumber ?? "") to \(email)")
                
                // Remove from failed attempts if it was previously failing
                await MainActor.run {
                    clearFailedAttempt(invoiceId: invoiceId)
                }
            } catch {
                print("❌ Failed to send recurring invoice email: \(error.localizedDescription)")
                await MainActor.run {
                    trackFailedAttempt(invoiceId: invoiceId, customerId: customerId, error: error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Retry Logic
    
    private func startRetryTimer() {
        // Check for retries every minute
        retryTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.processRetries()
        }
    }
    
    private func processRetries() {
        let now = Date()
        
        for (invoiceId, var attempt) in failedAttempts {
            // Check if it's time to retry
            guard now >= attempt.nextRetryTime else {
                continue
            }
            
            // Check if we've exceeded max attempts
            if attempt.attemptCount >= retryConfig.maxAttempts {
                handleMaxRetriesExceeded(attempt: attempt)
                failedAttempts.removeValue(forKey: invoiceId)
                continue
            }
            
            // Attempt retry
            print("🔄 Retrying failed invoice \(invoiceId) (attempt \(attempt.attemptCount + 1)/\(retryConfig.maxAttempts))")
            
            // Fetch the invoice and retry sending
            if let invoice = fetchInvoice(id: invoiceId) {
                attempt.attemptCount += 1
                attempt.lastAttemptAt = Date()
                
                // Calculate next retry time using exponential backoff
                let delay = retryConfig.delayForAttempt(attempt.attemptCount)
                attempt.nextRetryTime = Date().addingTimeInterval(delay)
                
                // Update the attempt in our tracking
                failedAttempts[invoiceId] = attempt
                
                // Retry the send
                sendInvoiceEmail(invoice: invoice, customerId: attempt.customerId)
            } else {
                // Invoice no longer exists, remove from tracking
                failedAttempts.removeValue(forKey: invoiceId)
            }
        }
    }
    
    private func trackFailedAttempt(invoiceId: UUID, customerId: UUID, error: String) {
        if var existing = failedAttempts[invoiceId] {
            // Update existing attempt
            existing.attemptCount += 1
            existing.lastError = error
            existing.lastAttemptAt = Date()
            
            // Calculate next retry time
            let delay = retryConfig.delayForAttempt(existing.attemptCount)
            existing.nextRetryTime = Date().addingTimeInterval(delay)
            
            failedAttempts[invoiceId] = existing
            
            print("⚠️ Invoice \(invoiceId) failed again (attempt \(existing.attemptCount)/\(retryConfig.maxAttempts))")
            print("   Next retry at: \(existing.nextRetryTime)")
        } else {
            // Create new failed attempt tracking
            // We need the recurring invoice ID - try to find it
            if fetchInvoice(id: invoiceId) != nil {
                let attempt = FailedInvoiceAttempt(
                    invoiceId: invoiceId,
                    recurringInvoiceId: UUID(), // Would need to link this properly
                    customerId: customerId,
                    error: error
                )
                failedAttempts[invoiceId] = attempt
                
                print("⚠️ Invoice \(invoiceId) failed to send. Will retry in \(retryConfig.initialDelay) seconds")
            }
        }
    }
    
    private func clearFailedAttempt(invoiceId: UUID) {
        if let attempt = failedAttempts.removeValue(forKey: invoiceId) {
            print("✅ Cleared failed attempt for invoice \(invoiceId) after \(attempt.attemptCount) attempts")
        }
    }
    
    private func handleMaxRetriesExceeded(attempt: FailedInvoiceAttempt) {
        print("❌ Max retries exceeded for invoice \(attempt.invoiceId)")
        print("   First failed: \(attempt.firstFailedAt)")
        print("   Total attempts: \(attempt.attemptCount)")
        print("   Last error: \(attempt.lastError ?? "Unknown")")
        
        // Notify admin
        if let customer = coreDataManager.fetchCustomer(id: attempt.customerId),
           let _ = fetchInvoice(id: attempt.invoiceId) {
            
            let error = NSError(
                domain: "RecurringInvoice",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Max retry attempts (\(attempt.attemptCount)) exceeded. Last error: \(attempt.lastError ?? "Unknown")"
                ]
            )
            
            // Get recurring invoice if available
            let request = RecurringInvoice.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", attempt.recurringInvoiceId as CVarArg)
            request.fetchLimit = 1
            
            if let recurring = try? coreDataManager.viewContext.fetch(request).first {
                EmailService.shared.notifyAdminOfFailure(
                    recurringInvoice: recurring,
                    customer: customer,
                    error: error
                )
            }
        }
    }
    
    private func fetchInvoice(id: UUID) -> Invoice? {
        let request = Invoice.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try? coreDataManager.viewContext.fetch(request).first
    }
    
    // MARK: - Public Retry Management
    
    func getFailedInvoiceCount() -> Int {
        return failedAttempts.count
    }
    
    func getFailedInvoices() -> [FailedInvoiceAttempt] {
        return Array(failedAttempts.values).sorted { $0.nextRetryTime < $1.nextRetryTime }
    }
    
    func manualRetry(invoiceId: UUID) {
        guard let attempt = failedAttempts[invoiceId],
              let invoice = fetchInvoice(id: invoiceId) else {
            return
        }
        
        print("🔄 Manual retry requested for invoice \(invoiceId)")
        sendInvoiceEmail(invoice: invoice, customerId: attempt.customerId)
    }
    
    func clearFailedInvoice(invoiceId: UUID) {
        failedAttempts.removeValue(forKey: invoiceId)
        print("🗑️ Manually cleared failed invoice \(invoiceId)")
    }
    
    private func recordSuccess(for recurring: RecurringInvoice) {
        recurring.successfulCount += 1
        try? coreDataManager.viewContext.save()
    }
    
    private func recordFailure(for recurring: RecurringInvoice, error: String) {
        recurring.failedCount += 1
        try? coreDataManager.viewContext.save()
        
        print("❌ Failed to generate invoice: \(error)")
        
        // Notify admin of failure
        if let customer = coreDataManager.fetchCustomer(id: recurring.customerId ?? UUID()) {
            EmailService.shared.notifyAdminOfFailure(
                recurringInvoice: recurring,
                customer: customer,
                error: NSError(domain: "RecurringInvoice", code: -1, userInfo: [NSLocalizedDescriptionKey: error])
            )
        }
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
