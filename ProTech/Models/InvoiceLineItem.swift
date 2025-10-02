import CoreData
import Foundation

@objc(InvoiceLineItem)
public class InvoiceLineItem: NSManagedObject {}

extension InvoiceLineItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InvoiceLineItem> {
        NSFetchRequest<InvoiceLineItem>(entityName: "InvoiceLineItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var invoiceId: UUID?
    @NSManaged public var itemType: String? // "labor", "part", "service", "other"
    @NSManaged public var itemDescription: String?
    @NSManaged public var quantity: Decimal
    @NSManaged public var unitPrice: Decimal
    @NSManaged public var total: Decimal
    @NSManaged public var order: Int16
    @NSManaged public var createdAt: Date?
    
    // Relationship
    @NSManaged public var invoice: Invoice?
}

extension InvoiceLineItem: Identifiable {}

// MARK: - Computed Properties
extension InvoiceLineItem {
    var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: total as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedUnitPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: unitPrice as NSDecimalNumber) ?? "$0.00"
    }
    
    var formattedQuantity: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: quantity as NSDecimalNumber) ?? "0"
    }
}

// MARK: - Entity Description
extension InvoiceLineItem {
    private static var cachedEntity: NSEntityDescription?

    static func entityDescription() -> NSEntityDescription {
        if let cached = cachedEntity {
            return cached
        }

        let entity = NSEntityDescription()
        cachedEntity = entity
        entity.name = "InvoiceLineItem"
        entity.managedObjectClassName = NSStringFromClass(InvoiceLineItem.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let invoiceIdAttribute = makeAttribute("invoiceId", type: .UUIDAttributeType, optional: false)
        let itemTypeAttribute = makeAttribute("itemType", type: .stringAttributeType, optional: false, defaultValue: "service")
        let itemDescriptionAttribute = makeAttribute("itemDescription", type: .stringAttributeType, optional: false)
        let quantityAttribute = makeAttribute("quantity", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber(value: 1))
        let unitPriceAttribute = makeAttribute("unitPrice", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let totalAttribute = makeAttribute("total", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let orderAttribute = makeAttribute("order", type: .integer16AttributeType, optional: false, defaultValue: 0)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        
        // Relationship to Invoice
        let invoiceRelationship = NSRelationshipDescription()
        invoiceRelationship.name = "invoice"
        invoiceRelationship.minCount = 0
        invoiceRelationship.maxCount = 1 // to-one
        invoiceRelationship.deleteRule = .nullifyDeleteRule
        invoiceRelationship.isOptional = true

        entity.properties = [
            idAttribute,
            invoiceIdAttribute,
            itemTypeAttribute,
            itemDescriptionAttribute,
            quantityAttribute,
            unitPriceAttribute,
            totalAttribute,
            orderAttribute,
            createdAtAttribute,
            invoiceRelationship
        ]
        
        // Indexes
        let idIndex = NSFetchIndexDescription(name: "line_item_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let invoiceIndex = NSFetchIndexDescription(name: "line_item_invoice_index", elements: [NSFetchIndexElementDescription(property: invoiceIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, invoiceIndex]

        return entity
    }
}
