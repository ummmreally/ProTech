import CoreData
import Foundation

@objc(Estimate)
public class Estimate: NSManagedObject {}

extension Estimate {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Estimate> {
        NSFetchRequest<Estimate>(entityName: "Estimate")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var estimateNumber: String?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var issueDate: Date?
    @NSManaged public var validUntil: Date?
    @NSManaged public var subtotal: Decimal
    @NSManaged public var taxRate: Decimal
    @NSManaged public var taxAmount: Decimal
    @NSManaged public var discountAmount: Decimal
    @NSManaged public var discountRuleId: UUID?
    @NSManaged public var total: Decimal
    @NSManaged public var status: String? // "pending", "approved", "declined", "expired", "converted"
    @NSManaged public var notes: String?
    @NSManaged public var terms: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var approvedAt: Date?
    @NSManaged public var declinedAt: Date?
    @NSManaged public var convertedToInvoiceId: UUID?
    
    // Relationship
    @NSManaged public var lineItems: NSSet?
}

// MARK: - Line Items Relationship
extension Estimate {
    @objc(addLineItemsObject:)
    @NSManaged public func addToLineItems(_ value: EstimateLineItem)
    
    @objc(removeLineItemsObject:)
    @NSManaged public func removeFromLineItems(_ value: EstimateLineItem)
    
    @objc(addLineItems:)
    @NSManaged public func addToLineItems(_ values: NSSet)
    
    @objc(removeLineItems:)
    @NSManaged public func removeFromLineItems(_ values: NSSet)
}

extension Estimate: Identifiable {}

// MARK: - Computed Properties
extension Estimate {
    var lineItemsArray: [EstimateLineItem] {
        let set = lineItems as? Set<EstimateLineItem> ?? []
        return set.sorted { ($0.order) < ($1.order) }
    }
    
    var isExpired: Bool {
        guard let validUntil = validUntil, status == "pending" else {
            return false
        }
        return validUntil < Date()
    }
    
    var isApproved: Bool {
        return status == "approved"
    }
    
    var isDeclined: Bool {
        return status == "declined"
    }
    
    var isConverted: Bool {
        return status == "converted"
    }
    
    var formattedEstimateNumber: String {
        return estimateNumber ?? "EST-0000"
    }
    
    var statusColor: String {
        switch status {
        case "approved":
            return "green"
        case "declined":
            return "red"
        case "pending":
            return isExpired ? "orange" : "blue"
        case "converted":
            return "purple"
        case "expired":
            return "gray"
        default:
            return "gray"
        }
    }
}

// MARK: - Entity Description
extension Estimate {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Estimate"
        entity.managedObjectClassName = NSStringFromClass(Estimate.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let estimateNumberAttribute = makeAttribute("estimateNumber", type: .stringAttributeType, optional: false)
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let issueDateAttribute = makeAttribute("issueDate", type: .dateAttributeType, optional: false)
        let validUntilAttribute = makeAttribute("validUntil", type: .dateAttributeType)
        let subtotalAttribute = makeAttribute("subtotal", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let taxRateAttribute = makeAttribute("taxRate", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let taxAmountAttribute = makeAttribute("taxAmount", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let totalAttribute = makeAttribute("total", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let statusAttribute = makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "pending")
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let termsAttribute = makeAttribute("terms", type: .stringAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        let approvedAtAttribute = makeAttribute("approvedAt", type: .dateAttributeType)
        let declinedAtAttribute = makeAttribute("declinedAt", type: .dateAttributeType)
        let convertedToInvoiceIdAttribute = makeAttribute("convertedToInvoiceId", type: .UUIDAttributeType)
        
        // Relationship to EstimateLineItem
        let lineItemsRelationship = NSRelationshipDescription()
        lineItemsRelationship.name = "lineItems"
        lineItemsRelationship.minCount = 0
        lineItemsRelationship.maxCount = 0 // to-many
        lineItemsRelationship.deleteRule = .cascadeDeleteRule
        lineItemsRelationship.isOptional = true
        
        entity.properties = [
            idAttribute,
            estimateNumberAttribute,
            ticketIdAttribute,
            customerIdAttribute,
            issueDateAttribute,
            validUntilAttribute,
            subtotalAttribute,
            taxRateAttribute,
            taxAmountAttribute,
            totalAttribute,
            statusAttribute,
            notesAttribute,
            termsAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            approvedAtAttribute,
            declinedAtAttribute,
            convertedToInvoiceIdAttribute,
            lineItemsRelationship
        ]
        
        // Indexes
        let idIndex = NSFetchIndexDescription(name: "estimate_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let estimateNumberIndex = NSFetchIndexDescription(name: "estimate_number_index", elements: [NSFetchIndexElementDescription(property: estimateNumberAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "estimate_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, estimateNumberIndex, customerIndex]
        
        return entity
    }
}
