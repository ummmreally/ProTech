//
//  TimeEntry.swift
//  ProTech
//
//  Time tracking entry model
//

import Foundation
import CoreData

@objc(TimeEntry)
public class TimeEntry: NSManagedObject {}

extension TimeEntry: Identifiable {}

extension TimeEntry {
    @NSManaged public var id: UUID?
    @NSManaged public var ticketId: UUID?
    @NSManaged public var technicianId: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var endTime: Date?
    @NSManaged public var pausedAt: Date?
    @NSManaged public var totalPausedDuration: TimeInterval
    @NSManaged public var duration: TimeInterval // in seconds
    @NSManaged public var notes: String?
    @NSManaged public var isBillable: Bool
    @NSManaged public var hourlyRate: Decimal
    @NSManaged public var isRunning: Bool
    @NSManaged public var isPaused: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext,
                    ticketId: UUID,
                    technicianId: UUID?,
                    startTime: Date = Date(),
                    isBillable: Bool = true,
                    hourlyRate: Decimal = 75.00) {
        self.init(context: context)
        self.id = UUID()
        self.ticketId = ticketId
        self.technicianId = technicianId
        self.startTime = startTime
        self.isBillable = isBillable
        self.hourlyRate = hourlyRate
        self.isRunning = true
        self.isPaused = false
        self.totalPausedDuration = 0
        self.duration = 0
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension TimeEntry {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TimeEntry"
        entity.managedObjectClassName = NSStringFromClass(TimeEntry.self)
        
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
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("ticketId", type: .UUIDAttributeType),
            makeAttribute("technicianId", type: .UUIDAttributeType),
            makeAttribute("startTime", type: .dateAttributeType),
            makeAttribute("endTime", type: .dateAttributeType),
            makeAttribute("pausedAt", type: .dateAttributeType),
            makeAttribute("totalPausedDuration", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("duration", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("isBillable", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("hourlyRate", type: .decimalAttributeType, optional: false, defaultValue: NSDecimalNumber(value: 75.0)),
            makeAttribute("isRunning", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("isPaused", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "time_entry_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            entity.indexes = [idIndex]
        }
        
        return entity
    }
}

// MARK: - Fetch Request
extension TimeEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeEntry> {
        return NSFetchRequest<TimeEntry>(entityName: "TimeEntry")
    }
    
    static func fetchTimeEntriesForTicket(_ ticketId: UUID, context: NSManagedObjectContext) -> [TimeEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "ticketId == %@", ticketId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchRunningTimer(context: NSManagedObjectContext) -> TimeEntry? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "isRunning == true")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    static func fetchRunningEntry(context: NSManagedObjectContext) -> TimeEntry? {
        fetchRunningTimer(context: context)
    }
    
    static func fetchTimeEntriesForTechnician(_ technicianId: UUID, context: NSManagedObjectContext) -> [TimeEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "technicianId == %@", technicianId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchTimeEntriesInDateRange(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [TimeEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Computed Properties

extension TimeEntry {
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var formattedDurationHoursMinutes: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var durationInHours: Decimal {
        return Decimal(duration / 3600.0)
    }
    
    var billableAmount: Decimal {
        guard isBillable else { return 0 }
        return durationInHours * hourlyRate
    }
    
    var formattedBillableAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: billableAmount as NSDecimalNumber) ?? "$0.00"
    }
    
    var currentDuration: TimeInterval {
        guard let start = startTime else { return duration }
        
        if isRunning && !isPaused {
            let elapsed = Date().timeIntervalSince(start)
            return elapsed - totalPausedDuration
        }
        
        return duration
    }
    
    var statusDisplay: String {
        if isRunning && !isPaused {
            return "Running"
        } else if isRunning && isPaused {
            return "Paused"
        } else {
            return "Stopped"
        }
    }
}
