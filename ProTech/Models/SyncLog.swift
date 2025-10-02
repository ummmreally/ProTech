//
//  SyncLog.swift
//  ProTech
//
//  Tracks all synchronization operations for audit and debugging
//

import Foundation
import SwiftData

@Model
class SyncLog {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var operation: SyncOperation
    var itemId: UUID?
    var squareObjectId: String?
    var status: SyncStatus
    var errorMessage: String?
    var changedFields: [String]
    var syncDuration: TimeInterval
    var batchId: UUID?
    var details: String?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        operation: SyncOperation,
        itemId: UUID? = nil,
        squareObjectId: String? = nil,
        status: SyncStatus,
        errorMessage: String? = nil,
        changedFields: [String] = [],
        syncDuration: TimeInterval = 0,
        batchId: UUID? = nil,
        details: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.operation = operation
        self.itemId = itemId
        self.squareObjectId = squareObjectId
        self.status = status
        self.errorMessage = errorMessage
        self.changedFields = changedFields
        self.syncDuration = syncDuration
        self.batchId = batchId
        self.details = details
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
