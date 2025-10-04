//
//  TicketNote.swift
//  ProTech
//
//  Model for ticket note history
//

import CoreData

@objc(TicketNote)
public class TicketNote: NSManagedObject {}

extension TicketNote {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TicketNote> {
        NSFetchRequest<TicketNote>(entityName: "TicketNote")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var content: String?
    @NSManaged public var technicianName: String?
    @NSManaged public var createdAt: Date?
}

extension TicketNote: Identifiable {}

extension TicketNote {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TicketNote"
        entity.managedObjectClassName = NSStringFromClass(TicketNote.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType, optional: false)
        let contentAttribute = makeAttribute("content", type: .stringAttributeType, optional: false)
        let technicianNameAttribute = makeAttribute("technicianName", type: .stringAttributeType)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        
        entity.properties = [
            idAttribute,
            ticketIdAttribute,
            contentAttribute,
            technicianNameAttribute,
            createdAtAttribute
        ]
        
        let ticketIndex = NSFetchIndexDescription(name: "ticketnote_ticket_index", elements: [NSFetchIndexElementDescription(property: ticketIdAttribute, collationType: .binary)])
        entity.indexes = [ticketIndex]
        
        return entity
    }
}
