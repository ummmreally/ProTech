//
//  SquareConfiguration.swift
//  ProTech
//
//  Stores Square API credentials and sync settings
//

import Foundation
import CoreData

@objc(SquareConfiguration)
public class SquareConfiguration: NSManagedObject {}

extension SquareConfiguration {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SquareConfiguration> {
        NSFetchRequest<SquareConfiguration>(entityName: "SquareConfiguration")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var accessToken: String?
    @NSManaged public var refreshToken: String?
    @NSManaged public var merchantId: String?
    @NSManaged public var locationId: String?
    @NSManaged public var locationName: String?
    @NSManaged public var environmentRaw: String?
    @NSManaged public var syncEnabled: Bool
    @NSManaged public var syncInterval: Double
    @NSManaged public var lastFullSync: Date?
    @NSManaged public var webhookSignatureKey: String?
    @NSManaged public var webhookSubscriptionId: String?
    @NSManaged public var defaultConflictResolutionRaw: String?
    @NSManaged public var defaultSyncDirectionRaw: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // Computed properties for enums
    var environment: SquareEnvironment {
        get {
            guard let raw = environmentRaw else { return .sandbox }
            return SquareEnvironment(rawValue: raw) ?? .sandbox
        }
        set {
            environmentRaw = newValue.rawValue
        }
    }
    
    var defaultConflictResolution: ConflictResolutionStrategy {
        get {
            guard let raw = defaultConflictResolutionRaw else { return .mostRecent }
            return ConflictResolutionStrategy(rawValue: raw) ?? .mostRecent
        }
        set {
            defaultConflictResolutionRaw = newValue.rawValue
        }
    }
    
    var defaultSyncDirection: SyncDirection {
        get {
            guard let raw = defaultSyncDirectionRaw else { return .bidirectional }
            return SyncDirection(rawValue: raw) ?? .bidirectional
        }
        set {
            defaultSyncDirectionRaw = newValue.rawValue
        }
    }
    
    var isConfigured: Bool {
        guard let token = accessToken, let merchant = merchantId, let location = locationId else {
            return false
        }
        return !token.isEmpty && !merchant.isEmpty && !location.isEmpty
    }
    
    var baseURL: String {
        environment.baseURL
    }
}

extension SquareConfiguration: Identifiable {}

extension SquareConfiguration {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SquareConfiguration"
        entity.managedObjectClassName = NSStringFromClass(SquareConfiguration.self)
        
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
            makeAttribute("accessToken", type: .stringAttributeType, optional: false),
            makeAttribute("refreshToken", type: .stringAttributeType),
            makeAttribute("merchantId", type: .stringAttributeType, optional: false),
            makeAttribute("locationId", type: .stringAttributeType, optional: false),
            makeAttribute("locationName", type: .stringAttributeType),
            makeAttribute("environmentRaw", type: .stringAttributeType, optional: false, defaultValue: "sandbox"),
            makeAttribute("syncEnabled", type: .booleanAttributeType, optional: false, defaultValue: true),
            makeAttribute("syncInterval", type: .doubleAttributeType, optional: false, defaultValue: 3600.0),
            makeAttribute("lastFullSync", type: .dateAttributeType),
            makeAttribute("webhookSignatureKey", type: .stringAttributeType),
            makeAttribute("webhookSubscriptionId", type: .stringAttributeType),
            makeAttribute("defaultConflictResolutionRaw", type: .stringAttributeType, optional: false, defaultValue: "mostRecent"),
            makeAttribute("defaultSyncDirectionRaw", type: .stringAttributeType, optional: false, defaultValue: "bidirectional"),
            makeAttribute("createdAt", type: .dateAttributeType, optional: false),
            makeAttribute("updatedAt", type: .dateAttributeType, optional: false)
        ]
        
        return entity
    }
}

enum SquareEnvironment: String, Codable {
    case sandbox
    case production
    
    var displayName: String {
        switch self {
        case .sandbox: return "Sandbox (Testing)"
        case .production: return "Production (Live)"
        }
    }
    
    var baseURL: String {
        switch self {
        case .sandbox: return "https://connect.squareupsandbox.com"
        case .production: return "https://connect.squareup.com"
        }
    }
}

// MARK: - Sync Interval Presets

extension TimeInterval {
    static let fifteenMinutes: TimeInterval = 900
    static let thirtyMinutes: TimeInterval = 1800
    static let oneHour: TimeInterval = 3600
    static let fourHours: TimeInterval = 14400
    static let daily: TimeInterval = 86400
    
    var syncIntervalDisplayName: String {
        switch self {
        case .fifteenMinutes: return "15 Minutes"
        case .thirtyMinutes: return "30 Minutes"
        case .oneHour: return "1 Hour"
        case .fourHours: return "4 Hours"
        case .daily: return "Daily"
        default: return "\(Int(self / 60)) Minutes"
        }
    }
}
