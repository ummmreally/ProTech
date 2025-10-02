import CoreData
import Foundation

@objc(Invoice)
public class Invoice: NSManagedObject {}

extension Invoice {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Invoice> {
        NSFetchRequest<Invoice>(entityName: "Invoice")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var invoiceNumber: String?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var issueDate: Date?
    @NSManaged public var dueDate: Date?
    @NSManaged public var subtotal: Decimal
    @NSManaged public var taxRate: Decimal
    @NSManaged public var taxAmount: Decimal
    @NSManaged public var total: Decimal
    @NSManaged public var amountPaid: Decimal
    @NSManaged public var balance: Decimal
    @NSManaged public var status: String? // "draft", "sent", "paid", "overdue", "cancelled"
    @NSManaged public var notes: String?
    @NSManaged public var terms: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var sentAt: Date?
    @NSManaged public var paidAt: Date?
    
    // Relationship
    @NSManaged public var lineItems: NSSet?
}

// MARK: - Line Items Relationship
extension Invoice {
    @objc(addLineItemsObject:)
    @NSManaged public func addToLineItems(_ value: InvoiceLineItem)
    
    @objc(removeLineItemsObject:)
    @NSManaged public func removeFromLineItems(_ value: InvoiceLineItem)
    
    @objc(addLineItems:)
    @NSManaged public func addToLineItems(_ values: NSSet)
    
    @objc(removeLineItems:)
    @NSManaged public func removeFromLineItems(_ values: NSSet)
}

extension Invoice: Identifiable {}

// MARK: - Computed Properties
extension Invoice {
    var lineItemsArray: [InvoiceLineItem] {
        let set = lineItems as? Set<InvoiceLineItem> ?? []
        return set.sorted { ($0.order) < ($1.order) }
    }
    
    var isOverdue: Bool {
        guard let dueDate = dueDate, status != "paid", status != "cancelled" else {
            return false
        }
        return dueDate < Date()
    }
    
    var isPaid: Bool {
        return status == "paid"
    }
    
    var formattedInvoiceNumber: String {
        return invoiceNumber ?? "INV-0000"
    }
}

// MARK: - Entity Description
extension Invoice {
    private static var cachedEntity: NSEntityDescription?

    static func entityDescription() -> NSEntityDescription {
        if let cached = cachedEntity {
            return cached
        }

        let entity = NSEntityDescription()
        cachedEntity = entity
        entity.name = "Invoice"
        entity.managedObjectClassName = NSStringFromClass(Invoice.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let invoiceNumberAttribute = makeAttribute("invoiceNumber", type: .stringAttributeType, optional: false)
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let issueDateAttribute = makeAttribute("issueDate", type: .dateAttributeType, optional: false)
        let dueDateAttribute = makeAttribute("dueDate", type: .dateAttributeType)
        let subtotalAttribute = makeAttribute("subtotal", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let taxRateAttribute = makeAttribute("taxRate", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let taxAmountAttribute = makeAttribute("taxAmount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let totalAttribute = makeAttribute("total", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let amountPaidAttribute = makeAttribute("amountPaid", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let balanceAttribute = makeAttribute("balance", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let statusAttribute = makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "draft")
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let termsAttribute = makeAttribute("terms", type: .stringAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        let sentAtAttribute = makeAttribute("sentAt", type: .dateAttributeType)
        let paidAtAttribute = makeAttribute("paidAt", type: .dateAttributeType)
        
        // Relationship to InvoiceLineItem
        let lineItemsRelationship = NSRelationshipDescription()
        lineItemsRelationship.name = "lineItems"
        lineItemsRelationship.minCount = 0
        lineItemsRelationship.maxCount = 0 // to-many
        lineItemsRelationship.deleteRule = .cascadeDeleteRule
        lineItemsRelationship.isOptional = true
        
        entity.properties = [
            idAttribute,
            invoiceNumberAttribute,
            ticketIdAttribute,
            customerIdAttribute,
            issueDateAttribute,
            dueDateAttribute,
            subtotalAttribute,
            taxRateAttribute,
            taxAmountAttribute,
            totalAttribute,
            amountPaidAttribute,
            balanceAttribute,
            statusAttribute,
            notesAttribute,
            termsAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            sentAtAttribute,
            paidAtAttribute,
            lineItemsRelationship
        ]
        
        // Indexes
        let idIndex = NSFetchIndexDescription(name: "invoice_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let invoiceNumberIndex = NSFetchIndexDescription(name: "invoice_number_index", elements: [NSFetchIndexElementDescription(property: invoiceNumberAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "invoice_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, invoiceNumberIndex, customerIndex]

        return entity
    }
}
