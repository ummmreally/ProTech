//
//  LoyaltyMember.swift
//  ProTech
//
//  Customer enrollment in loyalty program
//

import CoreData

@objc(LoyaltyMember)
public class LoyaltyMember: NSManagedObject {}

extension LoyaltyMember {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoyaltyMember> {
        NSFetchRequest<LoyaltyMember>(entityName: "LoyaltyMember")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var programId: UUID?
    @NSManaged public var currentTierId: UUID?
    @NSManaged public var totalPoints: Int32
    @NSManaged public var availablePoints: Int32 // Total - redeemed
    @NSManaged public var lifetimePoints: Int32 // All-time points earned
    @NSManaged public var visitCount: Int32
    @NSManaged public var totalSpent: Double
    @NSManaged public var enrolledAt: Date?
    @NSManaged public var lastActivityAt: Date?
    @NSManaged public var isActive: Bool
}

extension LoyaltyMember: Identifiable {}

extension LoyaltyMember {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LoyaltyMember"
        entity.managedObjectClassName = NSStringFromClass(LoyaltyMember.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            if let defaultValue = defaultValue {
                attribute.defaultValue = defaultValue
            }
            return attribute
        }
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("customerId", type: .UUIDAttributeType, optional: false),
            makeAttribute("programId", type: .UUIDAttributeType, optional: false),
            makeAttribute("currentTierId", type: .UUIDAttributeType),
            makeAttribute("totalPoints", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("availablePoints", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("lifetimePoints", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("visitCount", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("totalSpent", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("enrolledAt", type: .dateAttributeType, optional: false),
            makeAttribute("lastActivityAt", type: .dateAttributeType),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true)
        ]
        
        let customerIndex = NSFetchIndexDescription(name: "loyalty_member_customer_index", elements: [NSFetchIndexElementDescription(property: entity.properties[1], collationType: .binary)])
        entity.indexes = [customerIndex]
        
        return entity
    }
}
