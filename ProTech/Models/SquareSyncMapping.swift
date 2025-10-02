//
//  SquareSyncMapping.swift
//  ProTech
//
//  Maps ProTech inventory items to Square catalog objects
//

import Foundation
import SwiftData

@Model
class SquareSyncMapping {
    @Attribute(.unique) var id: UUID
    var proTechItemId: UUID
    var squareCatalogObjectId: String
    var squareVariationId: String?
    var lastSyncedAt: Date
    var syncStatus: SyncStatus
    var syncDirection: SyncDirection
    var conflictResolution: ConflictResolutionStrategy
    var metadata: [String: String]
    var version: Int
    var errorMessage: String?
    
    init(
        id: UUID = UUID(),
        proTechItemId: UUID,
        squareCatalogObjectId: String,
        squareVariationId: String? = nil,
        lastSyncedAt: Date = Date(),
        syncStatus: SyncStatus = .pending,
        syncDirection: SyncDirection = .bidirectional,
        conflictResolution: ConflictResolutionStrategy = .mostRecent,
        metadata: [String: String] = [:],
        version: Int = 1,
        errorMessage: String? = nil
    ) {
        self.id = id
        self.proTechItemId = proTechItemId
        self.squareCatalogObjectId = squareCatalogObjectId
        self.squareVariationId = squareVariationId
        self.lastSyncedAt = lastSyncedAt
        self.syncStatus = syncStatus
        self.syncDirection = syncDirection
        self.conflictResolution = conflictResolution
        self.metadata = metadata
        self.version = version
        self.errorMessage = errorMessage
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
