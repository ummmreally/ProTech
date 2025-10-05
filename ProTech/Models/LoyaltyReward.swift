//
//  LoyaltyReward.swift
//  ProTech
//
//  Rewards that customers can redeem with points
//

import CoreData

@objc(LoyaltyReward)
public class LoyaltyReward: NSManagedObject {}

extension LoyaltyReward {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoyaltyReward> {
        NSFetchRequest<LoyaltyReward>(entityName: "LoyaltyReward")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var programId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var description_: String?
    @NSManaged public var pointsCost: Int32
    @NSManaged public var rewardType: String? // "discount_percent", "discount_amount", "free_item", "custom"
    @NSManaged public var rewardValue: Double // Percentage or dollar amount
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension LoyaltyReward: Identifiable {}

extension LoyaltyReward {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LoyaltyReward"
        entity.managedObjectClassName = NSStringFromClass(LoyaltyReward.self)
        
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
            makeAttribute("description_", type: .stringAttributeType),
            makeAttribute("pointsCost", type: .integer32AttributeType, optional: false),
            makeAttribute("rewardType", type: .stringAttributeType, optional: false),
            makeAttribute("rewardValue", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("sortOrder", type: .integer16AttributeType, optional: false, defaultValue: 0),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        let programIndex = NSFetchIndexDescription(name: "loyalty_reward_program_index", elements: [NSFetchIndexElementDescription(property: entity.properties[1], collationType: .binary)])
        entity.indexes = [programIndex]
        
        return entity
    }
}
