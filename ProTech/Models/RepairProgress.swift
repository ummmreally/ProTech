import CoreData

@objc(RepairProgress)
public class RepairProgress: NSManagedObject {}

extension RepairProgress {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairProgress> {
        NSFetchRequest<RepairProgress>(entityName: "RepairProgress")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var currentStage: String?
    @NSManaged public var laborHours: Double
    @NSManaged public var laborRate: Double
    @NSManaged public var notes: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension RepairProgress: Identifiable {}

extension RepairProgress {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RepairProgress"
        entity.managedObjectClassName = NSStringFromClass(RepairProgress.self)

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
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType)
        let currentStageAttribute = makeAttribute("currentStage", type: .stringAttributeType)
        let laborHoursAttribute = makeAttribute("laborHours", type: .doubleAttributeType, optional: false, defaultValue: 0.0)
        let laborRateAttribute = makeAttribute("laborRate", type: .doubleAttributeType, optional: false, defaultValue: 75.0)
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType)

        entity.properties = [
            idAttribute,
            ticketIdAttribute,
            currentStageAttribute,
            laborHoursAttribute,
            laborRateAttribute,
            notesAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "repair_progress_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let ticketIndex = NSFetchIndexDescription(name: "repair_progress_ticket_index", elements: [NSFetchIndexElementDescription(property: ticketIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, ticketIndex]

        return entity
    }
}

