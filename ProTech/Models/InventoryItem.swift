import CoreData

@objc(InventoryItem)
public class InventoryItem: NSManagedObject {}

extension InventoryItem {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<InventoryItem> {
        NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var partNumber: String?
    @NSManaged public var sku: String?
    @NSManaged public var category: String?
    @NSManaged public var manufacturer: String?
    @NSManaged public var model: String?
    @NSManaged public var itemDescription: String?
    
    // Stock
    @NSManaged public var quantity: Int32
    @NSManaged public var minQuantity: Int32
    @NSManaged public var maxQuantity: Int32
    @NSManaged public var reorderPoint: Int32
    @NSManaged public var location: String?
    @NSManaged public var binLocation: String?
    
    // Pricing
    @NSManaged public var costPrice: Double
    @NSManaged public var sellingPrice: Double
    @NSManaged public var msrp: Double
    @NSManaged public var taxable: Bool
    
    // Supplier
    @NSManaged public var supplierId: UUID?
    @NSManaged public var supplierPartNumber: String?
    @NSManaged public var preferredSupplier: String?
    
    // Tracking
    @NSManaged public var trackSerial: Bool
    @NSManaged public var trackWarranty: Bool
    @NSManaged public var warrantyPeriodDays: Int32
    
    // Status
    @NSManaged public var isActive: Bool
    @NSManaged public var isDiscontinued: Bool
    @NSManaged public var lastRestocked: Date?
    @NSManaged public var lastSold: Date?
    
    // Metadata
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Computed properties
    var totalValue: Double {
        Double(quantity) * costPrice
    }
    
    var isLowStock: Bool {
        quantity <= minQuantity
    }
    
    var isOutOfStock: Bool {
        quantity <= 0
    }
    
    var stockPercentage: Double {
        guard maxQuantity > 0 else { return 0 }
        return Double(quantity) / Double(maxQuantity) * 100
    }
}

extension InventoryItem: Identifiable {}

extension InventoryItem {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "InventoryItem"
        entity.managedObjectClassName = NSStringFromClass(InventoryItem.self)
        
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
            makeAttribute("name", type: .stringAttributeType),
            makeAttribute("partNumber", type: .stringAttributeType),
            makeAttribute("sku", type: .stringAttributeType),
            makeAttribute("category", type: .stringAttributeType),
            makeAttribute("manufacturer", type: .stringAttributeType),
            makeAttribute("model", type: .stringAttributeType),
            makeAttribute("itemDescription", type: .stringAttributeType),
            makeAttribute("quantity", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("minQuantity", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("maxQuantity", type: .integer32AttributeType, optional: false, defaultValue: 100),
            makeAttribute("reorderPoint", type: .integer32AttributeType, optional: false, defaultValue: 5),
            makeAttribute("location", type: .stringAttributeType),
            makeAttribute("binLocation", type: .stringAttributeType),
            makeAttribute("costPrice", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("sellingPrice", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("msrp", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("taxable", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("supplierId", type: .UUIDAttributeType),
            makeAttribute("supplierPartNumber", type: .stringAttributeType),
            makeAttribute("preferredSupplier", type: .stringAttributeType),
            makeAttribute("trackSerial", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("trackWarranty", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("warrantyPeriodDays", type: .integer32AttributeType, optional: false, defaultValue: 90),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("isDiscontinued", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("lastRestocked", type: .dateAttributeType),
            makeAttribute("lastSold", type: .dateAttributeType),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        let idAttr = entity.properties.first { $0.name == "id" } as! NSAttributeDescription
        let idIndex = NSFetchIndexDescription(name: "inventory_item_id_index", elements: [NSFetchIndexElementDescription(property: idAttr, collationType: .binary)])
        entity.indexes = [idIndex]
        
        return entity
    }
}
