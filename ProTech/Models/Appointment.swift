import CoreData
import Foundation
import SwiftUI

@objc(Appointment)
public class Appointment: NSManagedObject {}

extension Appointment {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Appointment> {
        NSFetchRequest<Appointment>(entityName: "Appointment")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var customerId: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var appointmentType: String? // "dropoff", "pickup", "consultation", "repair"
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var duration: Int16 // in minutes
    @NSManaged public var status: String? // "scheduled", "confirmed", "completed", "cancelled", "no_show"
    @NSManaged public var notes: String?
    @NSManaged public var reminderSent: Bool
    @NSManaged public var confirmationSent: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var completedAt: Date?
    @NSManaged public var cancelledAt: Date?
    @NSManaged public var cancellationReason: String?
    @NSManaged public var cloudSyncStatus: String?
    
    // Scheduling & Sync
    @NSManaged public var recurrenceRule: String? // e.g., "FREQ=WEEKLY;INTERVAL=1"
    @NSManaged public var technicianId: UUID? // Assigned employee
    @NSManaged public var googleCalendarEventId: String?
}

extension Appointment: Identifiable {}

// MARK: - Computed Properties
extension Appointment {
    var endDate: Date? {
        guard let scheduledDate = scheduledDate else { return nil }
        return Calendar.current.date(byAdding: .minute, value: Int(duration), to: scheduledDate)
    }
    
    var isUpcoming: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate > Date() && status == "scheduled"
    }
    
    var isPast: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate < Date()
    }
    
    var isToday: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return Calendar.current.isDateInToday(scheduledDate)
    }
    
    var statusColor: String {
        switch status {
        case "confirmed":
            return "green"
        case "scheduled":
            return "blue"
        case "completed":
            return "gray"
        case "cancelled":
            return "red"
        case "no_show":
            return "orange"
        default:
            return "gray"
        }
    }
    
    var typeDisplayName: String {
        switch appointmentType {
        case "dropoff":
            return "Drop-off"
        case "pickup":
            return "Pickup"
        case "consultation":
            return "Consultation"
        case "repair":
            return "Repair"
        default:
            return "Appointment"
        }
    }
    
    var formattedDuration: String {
        let hours = duration / 60
        let minutes = duration % 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    var typeDisplayIcon: String {
        switch appointmentType {
        case "dropoff":
            return "arrow.down.circle.fill"
        case "pickup":
            return "arrow.up.circle.fill"
        case "consultation":
            return "person.2.fill"
        case "repair":
            return "wrench.and.screwdriver.fill"
        default:
            return "calendar.circle.fill"
        }
    }
    
    var typeDisplayColor: Color {
        switch appointmentType {
        case "dropoff":
            return .blue
        case "pickup":
            return .green
        case "consultation":
            return .purple
        case "repair":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Entity Description
extension Appointment {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "Appointment"
        entity.managedObjectClassName = NSStringFromClass(Appointment.self)
        
        func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = true, defaultValue: Any? = nil) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            attribute.defaultValue = defaultValue
            return attribute
        }
        
        let idAttribute = makeAttribute("id", type: .UUIDAttributeType, optional: false)
        let customerIdAttribute = makeAttribute("customerId", type: .UUIDAttributeType, optional: false)
        let ticketIdAttribute = makeAttribute("ticketId", type: .UUIDAttributeType)
        let appointmentTypeAttribute = makeAttribute("appointmentType", type: .stringAttributeType, optional: false, defaultValue: "dropoff")
        let scheduledDateAttribute = makeAttribute("scheduledDate", type: .dateAttributeType, optional: false)
        let durationAttribute = makeAttribute("duration", type: .integer16AttributeType, optional: false, defaultValue: 30)
        let statusAttribute = makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "scheduled")
        let notesAttribute = makeAttribute("notes", type: .stringAttributeType)
        let reminderSentAttribute = makeAttribute("reminderSent", type: .booleanAttributeType, optional: false, defaultValue: false)
        let confirmationSentAttribute = makeAttribute("confirmationSent", type: .booleanAttributeType, optional: false, defaultValue: false)
        let createdAtAttribute = makeAttribute("createdAt", type: .dateAttributeType, optional: false)
        let updatedAtAttribute = makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        let completedAtAttribute = makeAttribute("completedAt", type: .dateAttributeType)
        let cancelledAtAttribute = makeAttribute("cancelledAt", type: .dateAttributeType)
        let cancellationReasonAttribute = makeAttribute("cancellationReason", type: .stringAttributeType)
        
        entity.properties = [
            idAttribute,
            customerIdAttribute,
            ticketIdAttribute,
            appointmentTypeAttribute,
            scheduledDateAttribute,
            durationAttribute,
            statusAttribute,
            notesAttribute,
            reminderSentAttribute,
            confirmationSentAttribute,
            createdAtAttribute,
            updatedAtAttribute,
            completedAtAttribute,
            cancelledAtAttribute,
            cancellationReasonAttribute,
            cancelledAtAttribute,
            cancellationReasonAttribute,
            makeAttribute("cloudSyncStatus", type: .stringAttributeType),
            makeAttribute("recurrenceRule", type: .stringAttributeType),
            makeAttribute("technicianId", type: .UUIDAttributeType),
            makeAttribute("googleCalendarEventId", type: .stringAttributeType)
        ]
        
        let idIndex = NSFetchIndexDescription(name: "appointment_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
        let customerIndex = NSFetchIndexDescription(name: "appointment_customer_index", elements: [NSFetchIndexElementDescription(property: customerIdAttribute, collationType: .binary)])
        let dateIndex = NSFetchIndexDescription(name: "appointment_date_index", elements: [NSFetchIndexElementDescription(property: scheduledDateAttribute, collationType: .binary)])
        entity.indexes = [idIndex, customerIndex, dateIndex]
        
        return entity
    }
}
