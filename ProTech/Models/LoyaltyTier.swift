//
//  LoyaltyTier.swift
//  ProTech
//
//  VIP tier levels for loyalty program
//

import CoreData

@objc(LoyaltyTier)
public class LoyaltyTier: NSManagedObject {}

extension LoyaltyTier {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoyaltyTier> {
        NSFetchRequest<LoyaltyTier>(entityName: "LoyaltyTier")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var programId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var pointsRequired: Int32 // Minimum points to reach this tier
    @NSManaged public var pointsMultiplier: Double // 1.0 = standard, 1.5 = 50% bonus, 2.0 = double, etc.
    @NSManaged public var color: String? // Hex color for UI
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
}

extension LoyaltyTier: Identifiable {}

extension LoyaltyTier {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LoyaltyTier"
        entity.managedObjectClassName = NSStringFromClass(LoyaltyTier.self)
        
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
            makeAttribute("programId", type: .UUIDAttributeType, optional: false),
            makeAttribute("name", type: .stringAttributeType, optional: false),
            makeAttribute("pointsRequired", type: .integer32AttributeType, optional: false, defaultValue: 0),
            makeAttribute("pointsMultiplier", type: .doubleAttributeType, optional: false, defaultValue: 1.0),
            makeAttribute("color", type: .stringAttributeType),
            makeAttribute("sortOrder", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        ]
        
        let programIndex = NSFetchIndexDescription(name: "loyalty_tier_program_index", elements: [NSFetchIndexElementDescription(property: entity.properties[1], collationType: .binary)])
        entity.indexes = [programIndex]
        
        return entity
    }
}
