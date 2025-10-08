//
//  EmployeeSchedule.swift
//  ProTech
//
//  Model for employee work schedules
//

import Foundation
import CoreData
import SwiftUI

@objc(EmployeeSchedule)
public class EmployeeSchedule: NSManagedObject {}

extension EmployeeSchedule: Identifiable {}

extension EmployeeSchedule {
    @NSManaged public var id: UUID?
    @NSManaged public var employeeId: UUID?
    @NSManaged public var dayOfWeek: Int16
    @NSManaged public var scheduledStartTime: Date?
    @NSManaged public var scheduledEndTime: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    convenience init(context: NSManagedObjectContext,
                    employeeId: UUID,
                    dayOfWeek: Int,
                    startTime: Date,
                    endTime: Date) {
        self.init(context: context)
        self.id = UUID()
        self.employeeId = employeeId
        self.dayOfWeek = Int16(dayOfWeek)
        self.scheduledStartTime = startTime
        self.scheduledEndTime = endTime
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

extension EmployeeSchedule {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "EmployeeSchedule"
        entity.managedObjectClassName = NSStringFromClass(EmployeeSchedule.self)
        
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
            makeAttribute("dayOfWeek", type: .integer16AttributeType, optional: false),
            makeAttribute("scheduledStartTime", type: .dateAttributeType, optional: false),
            makeAttribute("scheduledEndTime", type: .dateAttributeType, optional: false),
            makeAttribute("isActive", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        return entity
    }
}

extension EmployeeSchedule {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<EmployeeSchedule> {
        return NSFetchRequest<EmployeeSchedule>(entityName: "EmployeeSchedule")
    }
    
    static func fetchScheduleForEmployee(_ employeeId: UUID, context: NSManagedObjectContext) -> [EmployeeSchedule] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@ AND isActive == true", employeeId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "dayOfWeek", ascending: true)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchScheduleForDay(_ employeeId: UUID, dayOfWeek: Int, context: NSManagedObjectContext) -> EmployeeSchedule? {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@ AND dayOfWeek == %d AND isActive == true", employeeId as CVarArg, dayOfWeek)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    var dayName: String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let index = Int(dayOfWeek) % 7
        return days[index]
    }
    
    var formattedStartTime: String {
        guard let time = scheduledStartTime else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var formattedEndTime: String {
        guard let time = scheduledEndTime else { return "N/A" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var scheduledHours: Double {
        guard let start = scheduledStartTime, let end = scheduledEndTime else { return 0 }
        return end.timeIntervalSince(start) / 3600.0
    }
}
