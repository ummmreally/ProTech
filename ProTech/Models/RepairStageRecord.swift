import CoreData

@objc(RepairStageRecord)
public class RepairStageRecord: NSManagedObject {}

extension RepairStageRecord {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RepairStageRecord> {
        NSFetchRequest<RepairStageRecord>(entityName: "RepairStageRecord")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var progressId: UUID?
    @NSManaged public var stageKey: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var notes: String?
    @NSManaged public var startedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var lastUpdated: Date?
    @NSManaged public var sortOrder: Int16
}

extension RepairStageRecord: Identifiable {}

extension RepairStageRecord {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "RepairStageRecord"
        entity.managedObjectClassName = NSStringFromClass(RepairStageRecord.self)

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
        let isCompletedAttribute = makeAttribute("isCompleted", type: .booleanAttributeType, optional: false, defaultValue: false)
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let startedAtAttribute = makeAttribute("startedAt", type: .dateAttributeType)
        let completedAtAttribute = makeAttribute("completedAt", type: .dateAttributeType)
        let lastUpdatedAttribute = makeAttribute("lastUpdated", type: .dateAttributeType)
        let sortOrderAttribute = makeAttribute("sortOrder", type: .integer16AttributeType, optional: false, defaultValue: 0)

        entity.properties = [
            idAttribute,
            progressIdAttribute,
            stageKeyAttribute,
            isCompletedAttribute,
            notesAttribute,
            startedAtAttribute,
            completedAtAttribute,
            lastUpdatedAttribute,
            sortOrderAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "repair_stage_record_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let progressIndex = NSFetchIndexDescription(name: "repair_stage_record_progress_index", elements: [NSFetchIndexElementDescription(property: progressIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, progressIndex]

        return entity
    }
}

