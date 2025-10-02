import CoreData
import Foundation

@objc(NotificationLog)
public class NotificationLog: NSManagedObject {}

extension NotificationLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationLog> {
        NSFetchRequest<NotificationLog>(entityName: "NotificationLog")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ruleId: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var notificationType: String? // "email", "sms"
    @NSManaged public var recipient: String? // Email address or phone number
    @NSManaged public var subject: String?
    @NSManaged public var body: String?
    @NSManaged public var status: String? // "pending", "sent", "failed", "cancelled"
    @NSManaged public var sentAt: Date?
    @NSManaged public var failureReason: String?
    @NSManaged public var createdAt: Date?
}

extension NotificationLog: Identifiable {}

// MARK: - Computed Properties
extension NotificationLog {
    var isSent: Bool {
        return status == "sent"
    }
    
    var isFailed: Bool {
        return status == "failed"
    }
    
    var isPending: Bool {
        return status == "pending"
    }
    
    var statusColor: String {
        switch status {
        case "sent":
            return "green"
        case "failed":
            return "red"
        case "pending":
            return "orange"
        case "cancelled":
            return "gray"
        default:
            return "gray"
        }
    }
    
    var displayRecipient: String {
        return recipient ?? "Unknown"
    }
}

// MARK: - Entity Description
extension NotificationLog {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "NotificationLog"
        entity.managedObjectClassName = NSStringFromClass(NotificationLog.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let ruleIdAttribute = makeAttribute("ruleId", type: .UUIDAttributeType)
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let notificationTypeAttribute = makeAttribute("notificationType", type: .stringAttributeType, optional: false)
        let recipientAttribute = makeAttribute("recipient", type: .stringAttributeType, optional: false)
        let subjectAttribute = makeAttribute("subject", type: .stringAttributeType)
        let bodyAttribute = makeAttribute("body", type: .stringAttributeType, optional: false)
        let statusAttribute = makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "pending")
        let sentAtAttribute = makeAttribute("sentAt", type: .dateAttributeType)
        let failureReasonAttribute = makeAttribute("failureReason", type: .stringAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        
        entity.properties = [
            idAttribute,
            ruleIdAttribute,
            ticketIdAttribute,
            customerIdAttribute,
            notificationTypeAttribute,
            recipientAttribute,
            subjectAttribute,
            bodyAttribute,
            statusAttribute,
            sentAtAttribute,
            failureReasonAttribute,
            createdAtAttribute
        ]
        
        let idIndex = NSFetchIndexDescription(name: "notification_log_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let ticketIndex = NSFetchIndexDescription(name: "notification_log_ticket_index", elements: [NSFetchIndexElementDescription(property: ticketIdAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "notification_log_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, ticketIndex, customerIndex]
        
        return entity
    }
}
