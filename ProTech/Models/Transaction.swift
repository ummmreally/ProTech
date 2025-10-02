//
//  Transaction.swift
//  ProTech
//
//  Payment transaction model for Stripe/PayPal processing
//

import Foundation
import CoreData

@objc(Transaction)
public class Transaction: NSManagedObject {}

extension Transaction: Identifiable {}

extension Transaction {
    @NSManaged public var id: UUID?
    @NSManaged public var transactionId: String? // Stripe/PayPal transaction ID
    @NSManaged public var invoiceId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var amount: Decimal
    @NSManaged public var currency: String?
    @NSManaged public var status: String? // pending, succeeded, failed, refunded
    @NSManaged public var paymentMethod: String? // card, paypal, etc.
    @NSManaged public var processor: String? // stripe, paypal
    @NSManaged public var cardLast4: String?
    @NSManaged public var cardBrand: String? // visa, mastercard, etc.
    @NSManaged public var refundAmount: Decimal
    @NSManaged public var failureMessage: String?
    @NSManaged public var receiptUrl: String?
    @NSManaged public var metadata: String? // JSON for additional data
    @NSManaged public var createdAt: Date?
    @NSManaged public var processedAt: Date?
    @NSManaged public var refundedAt: Date?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    transactionId: String,
                    invoiceId: UUID?,
                    customerId: UUID,
                    amount: Decimal,
                    currency: String = "USD",
                    processor: String,
                    paymentMethod: String) {
        self.init(context: context)
        self.id = UUID()
        self.transactionId = transactionId
        self.invoiceId = invoiceId
        self.customerId = customerId
        self.amount = amount
        self.currency = currency
        self.processor = processor
        self.paymentMethod = paymentMethod
        self.status = "pending"
        self.refundAmount = 0
        self.createdAt = Date()
    }
}

extension Transaction {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Transaction"
        entity.managedObjectClassName = NSStringFromClass(Transaction.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("transactionId", type: .stringAttributeType),
            makeAttribute("invoiceId", type: .UUIDAttributeType),
            makeAttribute("customerId", type: .UUIDAttributeType),
            makeAttribute("amount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("currency", type: .stringAttributeType, optional: false, defaultValue: "USD"),
            makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "pending"),
            makeAttribute("paymentMethod", type: .stringAttributeType),
            makeAttribute("processor", type: .stringAttributeType),
            makeAttribute("cardLast4", type: .stringAttributeType),
            makeAttribute("cardBrand", type: .stringAttributeType),
            makeAttribute("refundAmount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero),
            makeAttribute("failureMessage", type: .stringAttributeType),
            makeAttribute("receiptUrl", type: .stringAttributeType),
            makeAttribute("metadata", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("processedAt", type: .dateAttributeType),
            makeAttribute("refundedAt", type: .dateAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "transaction_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            entity.indexes = [idIndex]
        }
        
        return entity
    }
}

// MARK: - Fetch Request

extension Transaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Transaction> {
        return NSFetchRequest<Transaction>(entityName: "Transaction")
    }
    
    static func fetchTransactionsForInvoice(_ invoiceId: UUID, context: NSManagedObjectContext) -> [Transaction] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "invoiceId == %@", invoiceId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchTransactionsForCustomer(_ customerId: UUID, context: NSManagedObjectContext) -> [Transaction] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "customerId == %@", customerId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchTransaction(byId id: String, context: NSManagedObjectContext) -> Transaction? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "transactionId == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
}

// MARK: - Computed Properties

extension Transaction {
    var isSuccessful: Bool {
        return status == "succeeded"
    }
    
    var isFailed: Bool {
        return status == "failed"
    }
    
    var isRefunded: Bool {
        return status == "refunded" || refundAmount > 0
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedRefundAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency ?? "USD"
        return formatter.string(from: refundAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var paymentMethodDisplay: String {
        if let brand = cardBrand, let last4 = cardLast4 {
            return "\(brand.capitalized) •••• \(last4)"
        }
        return paymentMethod?.capitalized ?? "Unknown"
    }
    
    var statusDisplay: String {
        switch status {
        case "succeeded":
            return "Paid"
        case "pending":
            return "Processing"
        case "failed":
            return "Failed"
        case "refunded":
            return "Refunded"
        default:
            return status?.capitalized ?? "Unknown"
        }
    }
}
