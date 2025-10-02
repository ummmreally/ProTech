import CoreData
import Foundation

@objc(EstimateLineItem)
public class EstimateLineItem: NSManagedObject {}

extension EstimateLineItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EstimateLineItem> {
        NSFetchRequest<EstimateLineItem>(entityName: "EstimateLineItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var estimateId: UUID?
    @NSManaged public var itemType: String? // "labor", "part", "service", "other"
    @NSManaged public var itemDescription: String?
    @NSManaged public var quantity: Decimal
    @NSManaged public var unitPrice: Decimal
    @NSManaged public var total: Decimal
    @NSManaged public var order: Int16
    @NSManaged public var createdAt: Date?
    
    // Relationship
    @NSManaged public var estimate: Estimate?
}

extension EstimateLineItem: Identifiable {}

// MARK: - Computed Properties
extension EstimateLineItem {
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
extension EstimateLineItem {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EstimateLineItem"
        entity.managedObjectClassName = NSStringFromClass(EstimateLineItem.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let estimateIdAttribute = makeAttribute("estimateId", type: .UUIDAttributeType, optional: false)
        let itemTypeAttribute = makeAttribute("itemType", type: .stringAttributeType, optional: false, defaultValue: "service")
        let itemDescriptionAttribute = makeAttribute("itemDescription", type: .stringAttributeType, optional: false)
        let quantityAttribute = makeAttribute("quantity", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber(value: 1))
        let unitPriceAttribute = makeAttribute("unitPrice", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let totalAttribute = makeAttribute("total", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber.zero)
        let orderAttribute = makeAttribute("order", type: .integer16AttributeType, optional: false, defaultValue: 0)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        
        // Relationship to Estimate
        let estimateRelationship = NSRelationshipDescription()
        estimateRelationship.name = "estimate"
        estimateRelationship.minCount = 0
        estimateRelationship.maxCount = 1 // to-one
        estimateRelationship.deleteRule = .nullifyDeleteRule
        estimateRelationship.isOptional = true
        
        entity.properties = [
            idAttribute,
            estimateIdAttribute,
            itemTypeAttribute,
            itemDescriptionAttribute,
            quantityAttribute,
            unitPriceAttribute,
            totalAttribute,
            orderAttribute,
            createdAtAttribute,
            estimateRelationship
        ]
        
        // Indexes
        let idIndex = NSFetchIndexDescription(name: "estimate_line_item_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let estimateIndex = NSFetchIndexDescription(name: "estimate_line_item_estimate_index", elements: [NSFetchIndexElementDescription(property: estimateIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, estimateIndex]
        
        return entity
    }
}
