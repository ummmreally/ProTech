import Foundation
import CoreData

class PaymentService {
    static let shared = PaymentService()
    
    private let coreDataManager = CoreDataManager.shared
    private let invoiceService = InvoiceService.shared
    private var context: NSManagedObjectContext {
        coreDataManager.viewContext
    }
    
    private init() {}
    
    // MARK: - Payment Recording
    
    /// Record a new payment
    func recordPayment(
        invoiceId: UUID? = nil,
        customerId: UUID,
        amount: Decimal,
        paymentMethod: String,
        paymentDate: Date = Date(),
        referenceNumber: String? = nil,
        notes: String? = nil
    ) -> Payment {
        let payment = Payment(context: context)
        payment.id = UUID()
        payment.paymentNumber = generatePaymentNumber()
        payment.invoiceId = invoiceId
        payment.customerId = customerId
        payment.amount = amount
        payment.paymentMethod = paymentMethod
        payment.paymentDate = paymentDate
        payment.referenceNumber = referenceNumber
        payment.notes = notes
        payment.receiptGenerated = false
        payment.createdAt = Date()
        payment.updatedAt = Date()
        
        // Update invoice if linked
        if let invoiceId = invoiceId,
           let invoice = invoiceService.fetchInvoice(id: invoiceId) {
            invoiceService.recordPayment(invoice, amount: amount, date: paymentDate)
        }
        
        coreDataManager.save()
        return payment
    }
    
    /// Record payment for an invoice
    func recordPaymentForInvoice(
        _ invoice: Invoice,
        amount: Decimal,
        paymentMethod: String,
        paymentDate: Date = Date(),
        referenceNumber: String? = nil,
        notes: String? = nil
    ) -> Payment {
        return recordPayment(
            invoiceId: invoice.id,
            customerId: invoice.customerId ?? UUID(),
            amount: amount,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            referenceNumber: referenceNumber,
            notes: notes
        )
    }
    
    /// Record partial payment
    func recordPartialPayment(
        for invoice: Invoice,
        amount: Decimal,
        paymentMethod: String,
        paymentDate: Date = Date(),
        referenceNumber: String? = nil,
        notes: String? = nil
    ) -> Payment {
        let payment = recordPaymentForInvoice(
            invoice,
            amount: amount,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            referenceNumber: referenceNumber,
            notes: notes
        )
        
        return payment
    }
    
    // MARK: - Payment Updates
    
    /// Update payment details
    func updatePayment(
        _ payment: Payment,
        amount: Decimal? = nil,
        paymentMethod: String? = nil,
        paymentDate: Date? = nil,
        referenceNumber: String? = nil,
        notes: String? = nil
    ) {
        let oldAmount = payment.amount
        
        if let amount = amount {
            payment.amount = amount
        }
        if let paymentMethod = paymentMethod {
            payment.paymentMethod = paymentMethod
        }
        if let paymentDate = paymentDate {
            payment.paymentDate = paymentDate
        }
        if let referenceNumber = referenceNumber {
            payment.referenceNumber = referenceNumber
        }
        if let notes = notes {
            payment.notes = notes
        }
        
        payment.updatedAt = Date()
        
        // Update invoice if amount changed
        if let amount = amount, amount != oldAmount,
           let invoiceId = payment.invoiceId,
           let invoice = invoiceService.fetchInvoice(id: invoiceId) {
            let difference = amount - oldAmount
            invoiceService.recordPayment(invoice, amount: difference)
        }
        
        coreDataManager.save()
    }
    
    /// Mark receipt as generated
    func markReceiptGenerated(_ payment: Payment) {
        payment.receiptGenerated = true
        payment.updatedAt = Date()
        coreDataManager.save()
    }
    
    // MARK: - Fetch Operations
    
    /// Fetch all payments
    func fetchPayments(sortBy: PaymentSortOption = .dateDesc) -> [Payment] {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.sortDescriptors = sortBy.sortDescriptors
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching payments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch payments for a customer
    func fetchPayments(for customerId: UUID) -> [Payment] {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching customer payments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch payments for an invoice
    func fetchPayments(for invoice: Invoice) -> [Payment] {
        guard let invoiceId = invoice.id else { return [] }
        
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "invoiceId == %@", invoiceId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching invoice payments: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch payment by ID
    func fetchPayment(id: UUID) -> Payment? {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? context.fetch(request).first
    }
    
    /// Fetch payments by date range
    func fetchPayments(from startDate: Date, to endDate: Date) -> [Payment] {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(
            format: "paymentDate >= %@ AND paymentDate <= %@",
            startDate as NSDate, endDate as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching payments by date: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetch payments by method
    func fetchPayments(byMethod method: String) -> [Payment] {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "paymentMethod == %@", method)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching payments by method: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    /// Delete a payment
    func deletePayment(_ payment: Payment) {
        // Update invoice if linked
        if let invoiceId = payment.invoiceId,
           let invoice = invoiceService.fetchInvoice(id: invoiceId) {
            // Subtract payment amount from invoice
            let newAmountPaid = invoice.amountPaid - payment.amount
            invoice.amountPaid = max(newAmountPaid, 0)
            invoice.balance = invoice.total - invoice.amountPaid
            
            // Update status if needed
            if invoice.balance > 0 && invoice.status == "paid" {
                invoice.status = "sent"
            }
        }
        
        context.delete(payment)
        coreDataManager.save()
    }
    
    // MARK: - Helper Methods
    
    /// Generate unique payment number
    private func generatePaymentNumber() -> String {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Payment.createdAt, ascending: false)]
        request.fetchLimit = 1
        
        let lastPayment = try? context.fetch(request).first
        
        if let lastNumber = lastPayment?.paymentNumber,
           let numberPart = lastNumber.split(separator: "-").last,
           let number = Int(numberPart) {
            return String(format: "PAY-%04d", number + 1)
        }
        
        return "PAY-0001"
    }
    
    /// Calculate change for cash payment
    func calculateChange(amountDue: Decimal, amountReceived: Decimal) -> Decimal {
        return max(amountReceived - amountDue, 0)
    }
    
    // MARK: - Statistics
    
    /// Get total payments received
    func getTotalPaymentsReceived() -> Decimal {
        let payments = fetchPayments()
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Get total payments for date range
    func getTotalPayments(from startDate: Date, to endDate: Date) -> Decimal {
        let payments = fetchPayments(from: startDate, to: endDate)
        return payments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Get payments breakdown by method
    func getPaymentsByMethod() -> [String: Decimal] {
        let payments = fetchPayments()
        var breakdown: [String: Decimal] = [:]
        
        for payment in payments {
            let method = payment.paymentMethod ?? "unknown"
            breakdown[method, default: 0] += payment.amount
        }
        
        return breakdown
    }
    
    /// Get today's payments
    func getTodaysPayments() -> [Payment] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return fetchPayments(from: startOfDay, to: endOfDay)
    }
    
    /// Get today's revenue
    func getTodaysRevenue() -> Decimal {
        let todaysPayments = getTodaysPayments()
        return todaysPayments.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    /// Get this month's revenue
    func getMonthlyRevenue() -> Decimal {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        
        return getTotalPayments(from: startOfMonth, to: endOfMonth)
    }
}

// MARK: - Sort Options

enum PaymentSortOption: String, CaseIterable {
    case dateDesc = "Newest First"
    case dateAsc = "Oldest First"
    case amountDesc = "Amount (High to Low)"
    case amountAsc = "Amount (Low to High)"
    case methodAsc = "Payment Method"
    
    var sortDescriptors: [NSSortDescriptor] {
        switch self {
        case .dateDesc:
            return [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: false)]
        case .dateAsc:
            return [NSSortDescriptor(keyPath: \Payment.paymentDate, ascending: true)]
        case .amountDesc:
            return [NSSortDescriptor(keyPath: \Payment.amount, ascending: false)]
        case .amountAsc:
            return [NSSortDescriptor(keyPath: \Payment.amount, ascending: true)]
        case .methodAsc:
            return [NSSortDescriptor(keyPath: \Payment.paymentMethod, ascending: true)]
        }
    }
}
