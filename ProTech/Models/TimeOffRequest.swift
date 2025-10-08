//
//  TimeOffRequest.swift
//  ProTech
//
//  Model for employee time off requests
//

import Foundation
import CoreData
import SwiftUI

@objc(TimeOffRequest)
public class TimeOffRequest: NSManagedObject {}

extension TimeOffRequest: Identifiable {}

extension TimeOffRequest {
    @NSManaged public var id: UUID?
    @NSManaged public var employeeId: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var requestType: String?
    @NSManaged public var reason: String?
    @NSManaged public var status: String?
    @NSManaged public var requestedAt: Date?
    @NSManaged public var reviewedAt: Date?
    @NSManaged public var reviewedBy: String?
    @NSManaged public var reviewNotes: String?
    @NSManaged public var totalDays: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    convenience init(context: NSManagedObjectContext,
                    employeeId: UUID,
                    startDate: Date,
                    endDate: Date,
                    requestType: TimeOffType,
                    reason: String) {
        self.init(context: context)
        self.id = UUID()
        self.employeeId = employeeId
        self.startDate = startDate
        self.endDate = endDate
        self.requestType = requestType.rawValue
        self.reason = reason
        self.status = TimeOffStatus.pending.rawValue
        self.requestedAt = Date()
        self.totalDays = Self.calculateBusinessDays(from: startDate, to: endDate)
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func calculateBusinessDays(from startDate: Date, to endDate: Date) -> Double {
        let calendar = Calendar.current
        var businessDays = 0.0
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            if weekday != 1 && weekday != 7 {
                businessDays += 1
            }
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return businessDays
    }
}

enum TimeOffType: String, CaseIterable {
    case pto = "PTO"
    case sick = "Sick Leave"
    case unpaid = "Unpaid Leave"
    case vacation = "Vacation"
    case personal = "Personal Day"
    case bereavement = "Bereavement"
    
    var icon: String {
        switch self {
        case .pto: return "calendar.badge.clock"
        case .sick: return "cross.case"
        case .unpaid: return "calendar.badge.minus"
        case .vacation: return "beach.umbrella"
        case .personal: return "person.crop.circle"
        case .bereavement: return "heart"
        }
    }
}

enum TimeOffStatus: String {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .denied: return "Denied"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        }
    }
}

extension TimeOffRequest {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "TimeOffRequest"
        entity.managedObjectClassName = NSStringFromClass(TimeOffRequest.self)
        
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
            makeAttribute("startDate", type: .dateAttributeType, optional: false),
            makeAttribute("endDate", type: .dateAttributeType, optional: false),
            makeAttribute("requestType", type: .stringAttributeType, optional: false),
            makeAttribute("reason", type: .stringAttributeType),
            makeAttribute("status", type: .stringAttributeType, optional: false, defaultValue: "pending"),
            makeAttribute("requestedAt", type: .dateAttributeType, optional: false),
            makeAttribute("reviewedAt", type: .dateAttributeType),
            makeAttribute("reviewedBy", type: .stringAttributeType),
            makeAttribute("reviewNotes", type: .stringAttributeType),
            makeAttribute("totalDays", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        return entity
    }
}

extension TimeOffRequest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeOffRequest> {
        return NSFetchRequest<TimeOffRequest>(entityName: "TimeOffRequest")
    }
    
    static func fetchPendingRequests(context: NSManagedObjectContext) -> [TimeOffRequest] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", TimeOffStatus.pending.rawValue)
        request.sortDescriptors = [NSSortDescriptor(key: "requestedAt", ascending: false)]
        return (try? context.fetch(request)) ?? []
    }
    
    static func fetchRequestsForEmployee(_ employeeId: UUID, context: NSManagedObjectContext) -> [TimeOffRequest] {
        let request = fetchRequest()
        request.predicate = NSPredicate(format: "employeeId == %@", employeeId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        return (try? context.fetch(request)) ?? []
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
    
    var statusEnum: TimeOffStatus {
        TimeOffStatus(rawValue: status ?? "pending") ?? .pending
    }
    
    var typeEnum: TimeOffType {
        TimeOffType(rawValue: requestType ?? "PTO") ?? .pto
    }
}
