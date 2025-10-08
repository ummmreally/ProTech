//
//  TimeClockEntry.swift
//  ProTech
//
//  Employee clock in/out tracking (separate from ticket time tracking)
//

import Foundation
import CoreData

@objc(TimeClockEntry)
public class TimeClockEntry: NSManagedObject {}

extension TimeClockEntry: Identifiable {}

extension TimeClockEntry {
    @NSManaged public var id: UUID?
    @NSManaged public var employeeId: UUID?
    @NSManaged public var clockInTime: Date?
    @NSManaged public var clockOutTime: Date?
    @NSManaged public var breakStartTime: Date?
    @NSManaged public var breakEndTime: Date?
    @NSManaged public var totalBreakDuration: TimeInterval // in seconds
    @NSManaged public var totalHours: TimeInterval // in seconds
    @NSManaged public var notes: String?
    @NSManaged public var isActive: Bool // true if currently clocked in
    @NSManaged public var wasEdited: Bool // true if admin edited this entry
    @NSManaged public var editedBy: String? // name of admin who edited
    @NSManaged public var editedAt: Date? // when it was edited
    @NSManaged public var editNotes: String? // reason for edit
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Convenience initializer
    convenience init(context: NSManagedObjectContext, employeeId: UUID) {
        self.init(context: context)
        self.id = UUID()
        self.employeeId = employeeId
        self.clockInTime = Date()
        self.isActive = true
        self.totalBreakDuration = 0
        self.totalHours = 0
        self.wasEdited = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Core Data Entity Description
extension TimeClockEntry {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TimeClockEntry"
        entity.managedObjectClassName = NSStringFromClass(TimeClockEntry.self)
        
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
            makeAttribute("employeeId", type: .UUIDAttributeType, optional: false),
            makeAttribute("clockInTime", type: .dateAttributeType, optional: false),
            makeAttribute("clockOutTime", type: .dateAttributeType),
            makeAttribute("breakStartTime", type: .dateAttributeType),
            makeAttribute("breakEndTime", type: .dateAttributeType),
            makeAttribute("totalBreakDuration", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("totalHours", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("notes", type: .stringAttributeType),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("wasEdited", type: .booleanAttributeType, optional: false, defaultValue: false),
            makeAttribute("editedBy", type: .stringAttributeType),
            makeAttribute("editedAt", type: .dateAttributeType),
            makeAttribute("editNotes", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        if let idAttribute = entity.properties.first(where: { $0.name == "id" }) as? NSAttributeDescription,
           let employeeIdAttribute = entity.properties.first(where: { $0.name == "employeeId" }) as? NSAttributeDescription {
            let idIndex = NSFetchIndexDescription(name: "timeclock_id_index", elements: [NSFetchIndexElementDescription(property: idAttribute, collationType: .binary)])
            let employeeIndex = NSFetchIndexDescription(name: "timeclock_employee_index", elements: [NSFetchIndexElementDescription(property: employeeIdAttribute, collationType: .binary)])
            entity.indexes = [idIndex, employeeIndex]
        }
        
        return entity
    }
}

// MARK: - Fetch Requests
extension TimeClockEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeClockEntry> {
        return NSFetchRequest<TimeClockEntry>(entityName: "TimeClockEntry")
    }
    
    static func fetchActiveEntry(for employeeId: UUID, context: NSManagedObjectContext) -> TimeClockEntry? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@ AND isActive == true", employeeId as CVarArg)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    static func fetchEntriesForEmployee(_ employeeId: UUID, context: NSManagedObjectContext) -> [TimeClockEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@", employeeId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "clockInTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchEntriesInDateRange(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [TimeClockEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "clockInTime >= %@ AND clockInTime <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "clockInTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchEntriesForEmployeeInDateRange(employeeId: UUID, from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [TimeClockEntry] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@ AND clockInTime >= %@ AND clockInTime <= %@", 
                                       employeeId as CVarArg, startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "clockInTime", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
}

// MARK: - Computed Properties
extension TimeClockEntry {
    var currentDuration: TimeInterval {
        guard let clockIn = clockInTime else { return totalHours }
        
        if isActive {
            let elapsed = Date().timeIntervalSince(clockIn)
            return elapsed - totalBreakDuration
        }
        
        return totalHours
    }
    
    var formattedDuration: String {
        let duration = currentDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        return String(format: "%d:%02d", hours, minutes)
    }
    
    var durationInHours: Decimal {
        return Decimal(currentDuration / 3600.0)
    }
    
    var statusDisplay: String {
        if isActive {
            if breakStartTime != nil && breakEndTime == nil {
                return "On Break"
            }
            return "Clocked In"
        } else {
            return "Clocked Out"
        }
    }
    
    var shiftDate: Date {
        return clockInTime ?? createdAt ?? Date()
    }
    
    var formattedShiftDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: shiftDate)
    }
    
    var formattedClockIn: String {
        guard let clockIn = clockInTime else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: clockIn)
    }
    
    var formattedClockOut: String {
        guard let clockOut = clockOutTime else { return "In Progress" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: clockOut)
    }
    
    var onBreak: Bool {
        return breakStartTime != nil && breakEndTime == nil
    }
    
    var employeeName: String? {
        guard let employeeId = employeeId else { return nil }
        let context = CoreDataManager.shared.viewContext
        let request = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", employeeId as CVarArg)
        request.fetchLimit = 1
        let employee = try? context.fetch(request).first
        return employee?.fullName
    }
}
