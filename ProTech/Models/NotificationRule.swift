import CoreData
import Foundation

@objc(NotificationRule)
public class NotificationRule: NSManagedObject {}

extension NotificationRule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationRule> {
        NSFetchRequest<NotificationRule>(entityName: "NotificationRule")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var triggerEvent: String? // "status_change", "time_based", "manual"
    @NSManaged public var statusTrigger: String? // Specific status that triggers (e.g., "completed", "ready_for_pickup")
    @NSManaged public var notificationType: String? // "email", "sms", "both"
    @NSManaged public var isEnabled: Bool
    @NSManaged public var emailSubject: String?
    @NSManaged public var emailBody: String?
    @NSManaged public var smsBody: String?
    @NSManaged public var delayMinutes: Int16 // Delay before sending (0 = immediate)
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension NotificationRule: Identifiable {}

// MARK: - Computed Properties
extension NotificationRule {
    var isEmailEnabled: Bool {
        return notificationType == "email" || notificationType == "both"
    }
    
    var isSMSEnabled: Bool {
        return notificationType == "sms" || notificationType == "both"
    }
    
    var displayName: String {
        return name ?? "Unnamed Rule"
    }
    
    var triggerDescription: String {
        switch triggerEvent {
        case "status_change":
            return "When status changes to: \(statusTrigger ?? "any")"
        case "time_based":
            return "Time-based trigger"
        case "manual":
            return "Manual trigger only"
        default:
            return "Unknown trigger"
        }
    }
}

// MARK: - Entity Description
extension NotificationRule {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "NotificationRule"
        entity.managedObjectClassName = NSStringFromClass(NotificationRule.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let nameAttribute = makeAttribute("name", type: .stringAttributeType, optional: false)
        let triggerEventAttribute = makeAttribute("triggerEvent", type: .stringAttributeType, optional: false, defaultValue: "status_change")
        let statusTriggerAttribute = makeAttribute("statusTrigger", type: .stringAttributeType)
        let notificationTypeAttribute = makeAttribute("notificationType", type: .stringAttributeType, optional: false, defaultValue: "email")
        let isEnabledAttribute = makeAttribute("isEnabled", type: .booleanAttributeType, optional: false, defaultValue: true)
        let emailSubjectAttribute = makeAttribute("emailSubject", type: .stringAttributeType)
        let emailBodyAttribute = makeAttribute("emailBody", type: .stringAttributeType)
        let smsBodyAttribute = makeAttribute("smsBody", type: .stringAttributeType)
        let delayMinutesAttribute = makeAttribute("delayMinutes", type: .integer16AttributeType, optional: false, defaultValue: 0)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        
        entity.properties = [
            idAttribute,
            nameAttribute,
            triggerEventAttribute,
            statusTriggerAttribute,
            notificationTypeAttribute,
            isEnabledAttribute,
            emailSubjectAttribute,
            emailBodyAttribute,
            smsBodyAttribute,
            delayMinutesAttribute,
            createdAtAttribute,
            updatedAtAttribute
        ]
        
        let idIndex = NSFetchIndexDescription(name: "notification_rule_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        entity.indexes = [idIndex]
        
        return entity
    }
}
