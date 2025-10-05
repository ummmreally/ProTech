//
//  LoyaltyTransaction.swift
//  ProTech
//
//  Points earned or redeemed transactions
//

import CoreData

@objc(LoyaltyTransaction)
public class LoyaltyTransaction: NSManagedObject {}

extension LoyaltyTransaction {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LoyaltyTransaction> {
        NSFetchRequest<LoyaltyTransaction>(entityName: "LoyaltyTransaction")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var memberId: UUID?
    @NSManaged public var type: String? // "earned" or "redeemed"
    @NSManaged public var points: Int32
    @NSManaged public var description_: String? // Reason for points
    @NSManaged public var relatedInvoiceId: UUID?
    @NSManaged public var relatedRewardId: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var expiresAt: Date?
}

extension LoyaltyTransaction: Identifiable {}

extension LoyaltyTransaction {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "LoyaltyTransaction"
        entity.managedObjectClassName = NSStringFromClass(LoyaltyTransaction.self)
        
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
            makeAttribute("memberId", type: .UUIDAttributeType, optional: false),
            makeAttribute("type", type: .stringAttributeType, optional: false),
            makeAttribute("points", type: .integer32AttributeType, optional: false),
            makeAttribute("description_", type: .stringAttributeType),
            makeAttribute("relatedInvoiceId", type: .UUIDAttributeType),
            makeAttribute("relatedRewardId", type: .UUIDAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("expiresAt", type: .dateAttributeType)
        ]
        
        let memberIndex = NSFetchIndexDescription(name: "loyalty_transaction_member_index", elements: [NSFetchIndexElementDescription(property: entity.properties[1], collationType: .binary)])
        entity.indexes = [memberIndex]
        
        return entity
    }
}
