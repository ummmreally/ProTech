import CoreData

@objc(RepairPartUsage)
public class RepairPartUsage: NSManagedObject {}

extension RepairPartUsage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairPartUsage> {
        NSFetchRequest<RepairPartUsage>(entityName: "RepairPartUsage")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var progressId: UUID?
    @NSManaged public var stageKey: String?
    @NSManaged public var name: String?
    @NSManaged public var partNumber: String?
    @NSManaged public var unitCost: Double
    @NSManaged public var quantity: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension RepairPartUsage: Identifiable {}

extension RepairPartUsage {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RepairPartUsage"
        entity.managedObjectClassName = NSStringFromClass(RepairPartUsage.self)

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

        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let progressIdAttribute = makeAttribute("progressId", type: .UUIDAttributeType)
        let stageKeyAttribute = makeAttribute("stageKey", type: .stringAttributeType)
        let nameAttribute = makeAttribute("name", type: .stringAttributeType)
        let partNumberAttribute = makeAttribute("partNumber", type: .stringAttributeType)
        let unitCostAttribute = makeAttribute("unitCost", type: .doubleAttributeType, optional: false, defaultValue: 0.0)
        let quantityAttribute = makeAttribute("quantity", type: .integer32AttributeType, optional: false, defaultValue: 1)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType)

        entity.properties = [
            idAttribute,
            progressIdAttribute,
            stageKeyAttribute,
            nameAttribute,
            partNumberAttribute,
            unitCostAttribute,
            quantityAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "repair_part_usage_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let progressIndex = NSFetchIndexDescription(name: "repair_part_usage_progress_index", elements: [NSFetchIndexElementDescription(property: progressIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, progressIndex]

        return entity
    }
}

