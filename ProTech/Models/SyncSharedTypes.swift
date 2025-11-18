//
//  SyncSharedTypes.swift
//  ProTech
//
//  Centralized sync-related enumerations and helpers used across the app.
//

import Foundation

// MARK: - Sync Lifecycle Status

/// Represents the lifecycle status of a queued operation.
public enum SyncStatus: String, Codable, CaseIterable {
    case pending
    case inProgress
    case completed
    case failed
    
    public var isTerminal: Bool {
        switch self {
        case .pending, .inProgress:
            return false
        case .completed, .failed:
            return true
        }
    }
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    public var iconName: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.triangle"
        }
    }
}

// MARK: - Sync Outcomes

/// Represents the outcome/state for records that participate in sync.
public enum SyncOutcome: String, Codable, CaseIterable {
    case synced
    case pending
    case failed
    case conflict
    case disabled
    
    public var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .conflict: return "Conflict"
        case .disabled: return "Disabled"
        }
    }
    
    public var iconName: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .pending: return "clock.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .conflict: return "exclamationmark.2"
        case .disabled: return "pause.circle.fill"
        }
    }
}

// MARK: - Sync Directions

/// Direction of data flow when synchronising with external systems.
public enum SyncDirection: String, Codable, CaseIterable {
    case toSquare
    case fromSquare
    case bidirectional
    
    public var displayName: String {
        switch self {
        case .toSquare: return "ProTech → Square"
        case .fromSquare: return "Square → ProTech"
        case .bidirectional: return "Bidirectional"
        }
    }
}

// MARK: - Queue Operations

/// Operation types supported by the offline queue.
public enum SyncQueueOperationType: String, Codable, CaseIterable {
    case uploadCustomer
    case uploadTicket
    case uploadInventory
    case downloadCustomers
    case downloadTickets
    case downloadInventory
    case deleteCustomer
    case deleteTicket
    case deleteInventory
    
    public var displayName: String {
        switch self {
        case .uploadCustomer: return "Upload Customer"
        case .uploadTicket: return "Upload Ticket"
        case .uploadInventory: return "Upload Inventory"
        case .downloadCustomers: return "Download Customers"
        case .downloadTickets: return "Download Tickets"
        case .downloadInventory: return "Download Inventory"
        case .deleteCustomer: return "Delete Customer"
        case .deleteTicket: return "Delete Ticket"
        case .deleteInventory: return "Delete Inventory"
        }
    }
}

// MARK: - Sync Log Operations

/// Canonical operations stored in `SyncLog` for audit/history.
public enum SyncHistoryOperation: String, Codable, CaseIterable {
    case create
    case update
    case delete
    case batchImport
    case batchExport
    case webhookReceived
    case conflictResolved
    case mappingCreated
    case mappingDeleted
    
    public var displayName: String {
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
    
    public var iconName: String {
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
