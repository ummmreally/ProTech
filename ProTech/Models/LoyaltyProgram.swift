//
//  LoyaltyProgram.swift
//  ProTech
//
//  Loyalty program configuration
//

import CoreData

@objc(LoyaltyProgram)
public class LoyaltyProgram: NSManagedObject {}

extension LoyaltyProgram {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoyaltyProgram> {
        NSFetchRequest<LoyaltyProgram>(entityName: "LoyaltyProgram")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var pointsPerDollar: Double // Points earned per dollar spent
    @NSManaged public var pointsPerVisit: Int32 // Fixed points per visit
    @NSManaged public var enableTiers: Bool
    @NSManaged public var enableAutoNotifications: Bool
    @NSManaged public var pointsExpirationDays: Int32 // 0 = never expire
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension LoyaltyProgram: Identifiable {}

extension LoyaltyProgram {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LoyaltyProgram"
        entity.managedObjectClassName = NSStringFromClass(LoyaltyProgram.self)
        
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
            makeAttribute("name", type: .stringAttributeType),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("pointsPerDollar", type: .doubleAttributeType, optional: false, defaultValue: 1.0),
            makeAttribute("pointsPerVisit", type: .integer32AttributeType, optional: false, defaultValue: 10),
            makeAttribute("enableTiers", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("enableAutoNotifications", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("pointsExpirationDays", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        return entity
    }
}
