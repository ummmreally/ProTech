import CoreData

@objc(PurchaseOrder)
public class PurchaseOrder: NSManagedObject {}

extension PurchaseOrder {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PurchaseOrder> {
        NSFetchRequest<PurchaseOrder>(entityName: "PurchaseOrder")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var orderNumber: String?
    @NSManaged public var supplierId: UUID?
    @NSManaged public var supplierName: String?
    
    // Status
    @NSManaged public var status: String? // draft, sent, confirmed, partially_received, received, cancelled
    
    // Dates
    @NSManaged public var orderDate: Date?
    @NSManaged public var expectedDeliveryDate: Date?
    @NSManaged public var actualDeliveryDate: Date?
    
    // Amounts
    @NSManaged public var subtotal: Double
    @NSManaged public var tax: Double
    @NSManaged public var shipping: Double
    @NSManaged public var total: Double
    
    // Details
    @NSManaged public var lineItemsJSON: String?
    @NSManaged public var notes: String?
    @NSManaged public var trackingNumber: String?
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension PurchaseOrder: Identifiable {}

extension PurchaseOrder {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "PurchaseOrder"
        entity.managedObjectClassName = NSStringFromClass(PurchaseOrder.self)
        
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
            makeAttribute("orderNumber", type: .stringAttributeType),
            makeAttribute("supplierId", type: .UUIDAttributeType),
            makeAttribute("supplierName", type: .stringAttributeType),
            makeAttribute("status", type: .stringAttributeType),
            makeAttribute("orderDate", type: .dateAttributeType),
            makeAttribute("expectedDeliveryDate", type: .dateAttributeType),
            makeAttribute("actualDeliveryDate", type: .dateAttributeType),
            makeAttribute("subtotal", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("tax", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("shipping", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("total", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("lineItemsJSON", type: .stringAttributeType),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("trackingNumber", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        let idAttr = entity.properties.first { $0.name == "id" } as! NSAttributeDescription
        let idIndex = NSFetchIndexDescription(name: "purchase_order_id_index", elements: [NSFetchIndexElementDescription(property: idAttr, collationType: .binary)])
        entity.indexes = [idIndex]
        
        return entity
    }
}

// MARK: - Purchase Order Line Item

struct PurchaseOrderLineItem: Codable, Identifiable {
    let id: UUID
    var itemId: UUID
    var itemName: String
    var partNumber: String
    var quantity: Int
    var unitPrice: Double
    var receivedQuantity: Int
    
    var total: Double {
        Double(quantity) * unitPrice
    }
    
    var isFullyReceived: Bool {
        receivedQuantity >= quantity
    }
}
