//
//  SyncLog.swift
//  ProTech
//
//  Tracks all synchronization operations for audit and debugging
//

import Foundation
import CoreData

@objc(SyncLog)
public class SyncLog: NSManagedObject {}

extension SyncLog {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SyncLog> {
        NSFetchRequest<SyncLog>(entityName: "SyncLog")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var operationRaw: String?
    @NSManaged public var itemId: UUID?
    @NSManaged public var squareObjectId: String?
    @NSManaged public var statusRaw: String?
    @NSManaged public var errorMessage: String?
    @NSManaged public var changedFieldsData: Data?
    @NSManaged public var syncDuration: Double
    @NSManaged public var batchId: UUID?
    @NSManaged public var details: String?
    
    // Computed properties for enums
    var operation: SyncOperation {
        get {
            guard let raw = operationRaw else { return .update }
            return SyncOperation(rawValue: raw) ?? .update
        }
        set {
            operationRaw = newValue.rawValue
        }
    }
    
    var status: SyncStatus {
        get {
            guard let raw = statusRaw else { return .pending }
            return SyncStatus(rawValue: raw) ?? .pending
        }
        set {
            statusRaw = newValue.rawValue
        }
    }
    
    var changedFields: [String] {
        get {
            guard let data = changedFieldsData,
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            changedFieldsData = try? JSONEncoder().encode(newValue)
        }
    }
}

extension SyncLog: Identifiable {}

extension SyncLog {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SyncLog"
        entity.managedObjectClassName = NSStringFromClass(SyncLog.self)
        
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
            makeAttribute("timestamp", type: .dateAttributeType, optional: false),
            makeAttribute("operationRaw", type: .stringAttributeType, optional: false),
            makeAttribute("itemId", type: .UUIDAttributeType),
            makeAttribute("squareObjectId", type: .stringAttributeType),
            makeAttribute("statusRaw", type: .stringAttributeType, optional: false),
            makeAttribute("errorMessage", type: .stringAttributeType),
            makeAttribute("changedFieldsData", type: .binaryDataAttributeType),
            makeAttribute("syncDuration", type: .doubleAttributeType, optional: false, defaultValue: 0.0),
            makeAttribute("batchId", type: .UUIDAttributeType),
            makeAttribute("details", type: .stringAttributeType)
        ]
        
        // Create index on timestamp for sorting
        let timestampAttr = entity.properties.first { $0.name == "timestamp" } as! NSAttributeDescription
        let timestampIndex = NSFetchIndexDescription(name: "sync_log_timestamp_index", elements: [NSFetchIndexElementDescription(property: timestampAttr, collationType: .binary)])
        entity.indexes = [timestampIndex]
        
        return entity
    }
}

enum SyncOperation: String, Codable {
    case create
    case update
    case delete
    case batchImport
    case batchExport
    case webhookReceived
    case conflictResolved
    case mappingCreated
    case mappingDeleted
    
    var displayName: String {
        switch self {
        case .create: return "Create"
        case .update: return "Update"
        case .delete: return "Delete"
        case .batchImport: return "Batch Import"
        case .batchExport: return "Batch Export"
        case .webhookReceived: return "Webhook Received"
        case .conflictResolved: return "Conflict Resolved"
        case .mappingCreated: return "Mapping Created"
        case .mappingDeleted: return "Mapping Deleted"
        }
    }
    
    var iconName: String {
        switch self {
        case .create: return "plus.circle"
        case .update: return "arrow.triangle.2.circlepath"
        case .delete: return "trash"
        case .batchImport: return "arrow.down.circle"
        case .batchExport: return "arrow.up.circle"
        case .webhookReceived: return "bell.fill"
        case .conflictResolved: return "checkmark.shield"
        case .mappingCreated: return "link.circle"
        case .mappingDeleted: return "link.circle.fill"
        }
    }
}
