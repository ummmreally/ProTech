import CoreData

@objc(Supplier)
public class Supplier: NSManagedObject {}

extension Supplier {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Supplier> {
        NSFetchRequest<Supplier>(entityName: "Supplier")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var companyName: String?
    @NSManaged public var contactPerson: String?
    @NSManaged public var email: String?
    @NSManaged public var phone: String?
    @NSManaged public var website: String?
    
    // Address
    @NSManaged public var address: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var country: String?
    
    // Business terms
    @NSManaged public var paymentTerms: String?
    @NSManaged public var shippingMethod: String?
    @NSManaged public var leadTimeDays: Int32
    @NSManaged public var minimumOrder: Double
    @NSManaged public var accountNumber: String?
    
    // Status
    @NSManaged public var isActive: Bool
    @NSManaged public var rating: Int16
    @NSManaged public var notes: String?
    
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension Supplier: Identifiable {}

extension Supplier {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Supplier"
        entity.managedObjectClassName = NSStringFromClass(Supplier.self)
        
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
            makeAttribute("companyName", type: .stringAttributeType),
            makeAttribute("contactPerson", type: .stringAttributeType),
            makeAttribute("email", type: .stringAttributeType),
            makeAttribute("phone", type: .stringAttributeType),
            makeAttribute("website", type: .stringAttributeType),
            makeAttribute("address", type: .stringAttributeType),
            makeAttribute("city", type: .stringAttributeType),
            makeAttribute("state", type: .stringAttributeType),
            makeAttribute("zipCode", type: .stringAttributeType),
            makeAttribute("country", type: .stringAttributeType),
            makeAttribute("paymentTerms", type: .stringAttributeType),
            makeAttribute("shippingMethod", type: .stringAttributeType),
            makeAttribute("leadTimeDays", type: .integer32AttributeType, optional: false, defaultValue: 7),
            makeAttribute("minimumOrder", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("accountNumber", type: .stringAttributeType),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("rating", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        let idAttr = entity.properties.first { $0.name == "id" } as! NSAttributeDescription
        let idIndex = NSFetchIndexDescription(name: "supplier_id_index", elements: [NSFetchIndexElementDescription(property: idAttr, collationType: .binary)])
        entity.indexes = [idIndex]
        
        return entity
    }
}
