import CoreData

@objc(StockAdjustment)
public class StockAdjustment: NSManagedObject {}

extension StockAdjustment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StockAdjustment> {
        NSFetchRequest<StockAdjustment>(entityName: "StockAdjustment")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var itemId: UUID?
    @NSManaged public var itemName: String?
    @NSManaged public var type: String? // add, remove, recount, damaged, return, sale, usage
    @NSManaged public var quantityBefore: Int32
    @NSManaged public var quantityChange: Int32
    @NSManaged public var quantityAfter: Int32
    @NSManaged public var reason: String?
    @NSManaged public var reference: String? // PO#, Ticket#, etc.
    @NSManaged public var notes: String?
    @NSManaged public var performedBy: String?
    @NSManaged public var createdAt: Date?
}

extension StockAdjustment: Identifiable {}

extension StockAdjustment {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "StockAdjustment"
        entity.managedObjectClassName = NSStringFromClass(StockAdjustment.self)
        
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
            makeAttribute("itemId", type: .UUIDAttributeType),
            makeAttribute("itemName", type: .stringAttributeType),
            makeAttribute("type", type: .stringAttributeType),
            makeAttribute("quantityBefore", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("quantityChange", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("quantityAfter", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("reason", type: .stringAttributeType),
            makeAttribute("reference", type: .stringAttributeType),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("performedBy", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType)
        ]
        
        let idAttr = entity.properties.first { $0.name == "id" } as! NSAttributeDescription
        let itemIdAttr = entity.properties.first { $0.name == "itemId" } as! NSAttributeDescription
        
        let idIndex = NSFetchIndexDescription(name: "stock_adjustment_id_index", elements: [NSFetchIndexElementDescription(property: idAttr, collationType: .binary)])
        let itemIndex = NSFetchIndexDescription(name: "stock_adjustment_item_index", elements: [NSFetchIndexElementDescription(property: itemIdAttr, collationType: .binary)])
        
        entity.indexes = [idIndex, itemIndex]
        
        return entity
    }
}
