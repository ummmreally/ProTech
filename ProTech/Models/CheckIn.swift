//
//  CheckIn.swift
//  ProTech
//
//  Model for tracking customer portal check-ins
//

import CoreData

@objc(CheckIn)
public class CheckIn: NSManagedObject {}

extension CheckIn {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CheckIn> {
        NSFetchRequest<CheckIn>(entityName: "CheckIn")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var checkedInAt: Date?
    @NSManaged public var deviceType: String?
    @NSManaged public var deviceModel: String?
    @NSManaged public var issueDescription: String?
    @NSManaged public var status: String? // "waiting", "started", "completed"
    @NSManaged public var ticketId: UUID? // Set when ticket is created
    @NSManaged public var createdAt: Date?
}

extension CheckIn: Identifiable {}

extension CheckIn {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "CheckIn"
        entity.managedObjectClassName = NSStringFromClass(CheckIn.self)
        
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        
        let customerIdAttribute = NSAttributeDescription()
        customerIdAttribute.name = "customerId"
        customerIdAttribute.attributeType = .UUIDAttributeType
        customerIdAttribute.isOptional = false
        
        let checkedInAtAttribute = NSAttributeDescription()
        checkedInAtAttribute.name = "checkedInAt"
        checkedInAtAttribute.attributeType = .dateAttributeType
        checkedInAtAttribute.isOptional = false
        
        let deviceTypeAttribute = NSAttributeDescription()
        deviceTypeAttribute.name = "deviceType"
        deviceTypeAttribute.attributeType = .stringAttributeType
        deviceTypeAttribute.isOptional = true
        
        let deviceModelAttribute = NSAttributeDescription()
        deviceModelAttribute.name = "deviceModel"
        deviceModelAttribute.attributeType = .stringAttributeType
        deviceModelAttribute.isOptional = true
        
        let issueDescriptionAttribute = NSAttributeDescription()
        issueDescriptionAttribute.name = "issueDescription"
        issueDescriptionAttribute.attributeType = .stringAttributeType
        issueDescriptionAttribute.isOptional = true
        
        let statusAttribute = NSAttributeDescription()
        statusAttribute.name = "status"
        statusAttribute.attributeType = .stringAttributeType
        statusAttribute.isOptional = false
        statusAttribute.defaultValue = "waiting"
        
        let ticketIdAttribute = NSAttributeDescription()
        ticketIdAttribute.name = "ticketId"
        ticketIdAttribute.attributeType = .UUIDAttributeType
        ticketIdAttribute.isOptional = true
        
        let createdAtAttribute = NSAttributeDescription()
        createdAtAttribute.name = "createdAt"
        createdAtAttribute.attributeType = .dateAttributeType
        createdAtAttribute.isOptional = false
        
        entity.properties = [
            idAttribute,
            customerIdAttribute,
            checkedInAtAttribute,
            deviceTypeAttribute,
            deviceModelAttribute,
            issueDescriptionAttribute,
            statusAttribute,
            ticketIdAttribute,
            createdAtAttribute
        ]
        
        let idIndex = NSFetchIndexDescription(name: "checkin_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let customerIdIndex = NSFetchIndexDescription(name: "checkin_customer_id_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        entity.indexes = [idIndex, customerIdIndex]
        
        return entity
    }
}
