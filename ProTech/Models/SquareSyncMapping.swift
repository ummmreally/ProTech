//
//  SquareSyncMapping.swift
//  ProTech
//
//  Maps ProTech inventory items to Square catalog objects
//

import Foundation
import CoreData

@objc(SquareSyncMapping)
public class SquareSyncMapping: NSManagedObject {}

extension SquareSyncMapping {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SquareSyncMapping> {
        NSFetchRequest<SquareSyncMapping>(entityName: "SquareSyncMapping")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var proTechItemId: UUID?
    @NSManaged public var squareCatalogObjectId: String?
    @NSManaged public var squareVariationId: String?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var syncStatusRaw: String?
    @NSManaged public var syncDirectionRaw: String?
    @NSManaged public var conflictResolutionRaw: String?
    @NSManaged public var metadataData: Data?
    @NSManaged public var version: Int32
    @NSManaged public var errorMessage: String?
    
    // Computed properties for enums
    var syncStatus: SyncStatus {
        get {
            guard let raw = syncStatusRaw else { return .pending }
            return SyncStatus(rawValue: raw) ?? .pending
        }
        set {
            syncStatusRaw = newValue.rawValue
        }
    }
    
    var syncDirection: SyncDirection {
        get {
            guard let raw = syncDirectionRaw else { return .bidirectional }
            return SyncDirection(rawValue: raw) ?? .bidirectional
        }
        set {
            syncDirectionRaw = newValue.rawValue
        }
    }
    
    var conflictResolution: ConflictResolutionStrategy {
        get {
            guard let raw = conflictResolutionRaw else { return .mostRecent }
            return ConflictResolutionStrategy(rawValue: raw) ?? .mostRecent
        }
        set {
            conflictResolutionRaw = newValue.rawValue
        }
    }
    
    var metadata: [String: String] {
        get {
            guard let data = metadataData,
                  let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            metadataData = try? JSONEncoder().encode(newValue)
        }
    }
}

extension SquareSyncMapping: Identifiable {}

extension SquareSyncMapping {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SquareSyncMapping"
        entity.managedObjectClassName = NSStringFromClass(SquareSyncMapping.self)
        
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
            makeAttribute("proTechItemId", type: .UUIDAttributeType, optional: false),
            makeAttribute("squareCatalogObjectId", type: .stringAttributeType, optional: false),
            makeAttribute("squareVariationId", type: .stringAttributeType),
            makeAttribute("lastSyncedAt", type: .dateAttributeType, optional: false),
            makeAttribute("syncStatusRaw", type: .stringAttributeType, optional: false, defaultValue: "pending"),
            makeAttribute("syncDirectionRaw", type: .stringAttributeType, optional: false, defaultValue: "bidirectional"),
            makeAttribute("conflictResolutionRaw", type: .stringAttributeType, optional: false, defaultValue: "mostRecent"),
            makeAttribute("metadataData", type: .binaryDataAttributeType),
            makeAttribute("version", type: .integer32AttributeType, optional: false, defaultValue: 1),
            makeAttribute("errorMessage", type: .stringAttributeType)
        ]
        
        // Create unique index on id
        let idAttr = entity.properties.first { $0.name == "id" } as! NSAttributeDescription
        let idIndex = NSFetchIndexDescription(name: "square_sync_mapping_id_index", elements: [NSFetchIndexElementDescription(property: idAttr, collationType: .binary)])
        entity.indexes = [idIndex]
        
        return entity
    }
}

enum SyncStatus: String, Codable {
    case synced
    case pending
    case failed
    case conflict
    case disabled
    
    var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .conflict: return "Conflict"
        case .disabled: return "Disabled"
        }
    }
    
    var iconName: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .conflict: return "exclamationmark.2"
        case .disabled: return "pause.circle.fill"
        }
    }
}

enum SyncDirection: String, Codable {
    case toSquare
    case fromSquare
    case bidirectional
    
    var displayName: String {
        switch self {
        case .toSquare: return "ProTech → Square"
        case .fromSquare: return "Square → ProTech"
        case .bidirectional: return "Bidirectional"
        }
    }
}

enum ConflictResolutionStrategy: String, Codable {
    case squareWins
    case proTechWins
    case mostRecent
    case manual
    
    var displayName: String {
        switch self {
        case .squareWins: return "Square Wins"
        case .proTechWins: return "ProTech Wins"
        case .mostRecent: return "Most Recent Wins"
        case .manual: return "Manual Resolution"
        }
    }
    
    var description: String {
        switch self {
        case .squareWins:
            return "Always use Square's data when conflicts occur"
        case .proTechWins:
            return "Always use ProTech's data when conflicts occur"
        case .mostRecent:
            return "Use the most recently modified data"
        case .manual:
            return "Require manual resolution for each conflict"
        }
    }
}
