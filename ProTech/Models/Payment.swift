import CoreData
import Foundation

@objc(Payment)
public class Payment: NSManagedObject {}

extension Payment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Payment> {
        NSFetchRequest<Payment>(entityName: "Payment")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var paymentNumber: String?
    @NSManaged public var invoiceId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var amount: Decimal
    @NSManaged public var paymentMethod: String? // "cash", "card", "check", "transfer", "other"
    @NSManaged public var paymentDate: Date?
    @NSManaged public var referenceNumber: String? // Check number, transaction ID, etc.
    @NSManaged public var notes: String?
    @NSManaged public var receiptGenerated: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension Payment: Identifiable {}

// MARK: - Computed Properties
extension Payment {
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedPaymentNumber: String {
        return paymentNumber ?? "PAY-0000"
    }
    
    var paymentMethodDisplayName: String {
        switch paymentMethod {
        case "cash":
            return "Cash"
        case "card":
            return "Credit/Debit Card"
        case "check":
            return "Check"
        case "transfer":
            return "Bank Transfer"
        case "other":
            return "Other"
        default:
            return "Unknown"
        }
    }
    
    var paymentMethodIcon: String {
        switch paymentMethod {
        case "cash":
            return "dollarsign.circle.fill"
        case "card":
            return "creditcard.fill"
        case "check":
            return "doc.text.fill"
        case "transfer":
            return "arrow.left.arrow.right.circle.fill"
        case "other":
            return "questionmark.circle.fill"
        default:
            return "dollarsign.circle"
        }
    }
}

// MARK: - Entity Description
extension Payment {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Payment"
        entity.managedObjectClassName = NSStringFromClass(Payment.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let paymentNumberAttribute = makeAttribute("paymentNumber", type: .stringAttributeType, optional: false)
        let invoiceIdAttribute = makeAttribute("invoiceId", type: .UUIDAttributeType)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let amountAttribute = makeAttribute("amount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let paymentMethodAttribute = makeAttribute("paymentMethod", type: .stringAttributeType, optional: false, defaultValue: "cash")
        let paymentDateAttribute = makeAttribute("paymentDate", type: .dateAttributeType, optional: false)
        let referenceNumberAttribute = makeAttribute("referenceNumber", type: .stringAttributeType)
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let receiptGeneratedAttribute = makeAttribute("receiptGenerated", type: .booleanAttributeType, optional: false, defaultValue: false)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        
        entity.properties = [
            idAttribute,
            paymentNumberAttribute,
            invoiceIdAttribute,
            customerIdAttribute,
            amountAttribute,
            paymentMethodAttribute,
            paymentDateAttribute,
            referenceNumberAttribute,
            notesAttribute,
            receiptGeneratedAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]
        
        // Indexes
        let idIndex = NSFetchIndexDescription(name: "payment_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let invoiceIndex = NSFetchIndexDescription(name: "payment_invoice_index", elements: [NSFetchIndexElementDescription(property: invoiceIdAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "payment_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, invoiceIndex, customerIndex]
        
        return entity
    }
}
