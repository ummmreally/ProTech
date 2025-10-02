import CoreData

@objc(SMSMessage)
public class SMSMessage: NSManagedObject {
}

extension SMSMessage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SMSMessage> {
        NSFetchRequest<SMSMessage>(entityName: "SMSMessage")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var body: String?
    @NSManaged public var status: String?
    @NSManaged public var direction: String?
    @NSManaged public var sentAt: Date?
    @NSManaged public var twilioSid: String?
}

extension SMSMessage: Identifiable {}


extension SMSMessage {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SMSMessage"
        entity.managedObjectClassName = NSStringFromClass(SMSMessage.self)

        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false

        let customerIdAttribute = NSAttributeDescription()
        customerIdAttribute.name = "customerId"
        customerIdAttribute.attributeType = .UUIDAttributeType
        customerIdAttribute.isOptional = true

        let ticketIdAttribute = NSAttributeDescription()
        ticketIdAttribute.name = "ticketId"
        ticketIdAttribute.attributeType = .UUIDAttributeType
        ticketIdAttribute.isOptional = true

        let bodyAttribute = NSAttributeDescription()
        bodyAttribute.name = "body"
        bodyAttribute.attributeType = .stringAttributeType
        bodyAttribute.isOptional = true

        let statusAttribute = NSAttributeDescription()
        statusAttribute.name = "status"
        statusAttribute.attributeType = .stringAttributeType
        statusAttribute.isOptional = true

        let directionAttribute = NSAttributeDescription()
        directionAttribute.name = "direction"
        directionAttribute.attributeType = .stringAttributeType
        directionAttribute.isOptional = true

        let sentAtAttribute = NSAttributeDescription()
        sentAtAttribute.name = "sentAt"
        sentAtAttribute.attributeType = .dateAttributeType
        sentAtAttribute.isOptional = true

        let sidAttribute = NSAttributeDescription()
        sidAttribute.name = "twilioSid"
        sidAttribute.attributeType = .stringAttributeType
        sidAttribute.isOptional = true

        entity.properties = [
            idAttribute,
            customerIdAttribute,
            ticketIdAttribute,
            bodyAttribute,
            statusAttribute,
            directionAttribute,
            sentAtAttribute,
            sidAttribute
        ]

        let idIndex = NSFetchIndexDescription(name: "sms_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "sms_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        let ticketIndex = NSFetchIndexDescription(name: "sms_ticket_index", elements: [NSFetchIndexElementDescription(property: ticketIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, customerIndex, ticketIndex]

        return entity
    }
}
