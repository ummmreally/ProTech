//
//  SyncCoordinator.swift
//  ProTech
//
//  Central coordination point for all application synchronization.
//  Replaces the deprecated UnifiedSyncManager.
//

import Foundation
import SwiftUI

@MainActor
class SyncCoordinator: ObservableObject {
    static let shared = SyncCoordinator()
    
    // Dependencies
    private let supabaseSync = SupabaseSyncService.shared
    private let squareCustomerSync = SquareCustomerSyncManager.shared
    private let squareInventorySync = SquareInventorySyncManager.shared
    
    @Published var isSyncing = false
    @Published var currentOperation: String?
    @Published var lastSyncError: Error?
    @Published var lastSyncDate: Date?
    
    private init() {}
    
    /// Perform a full application sync
    func performFullSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        currentOperation = "Starting full sync..."
        lastSyncError = nil
        
        defer {
            isSyncing = false
            currentOperation = nil
            lastSyncDate = Date()
        }
        
        // 1. Sync Customers (High Priority)
        currentOperation = "Syncing customers..."
        await syncCustomers()
        
        // 2. Sync Inventory
        currentOperation = "Syncing inventory..."
        await syncInventory()
        
        // 3. Sync Other Supabase Data (Employees, Tickets)
        currentOperation = "Syncing application data..."
        await supabaseSync.performFullSync()
        
        AppLogger.info("Full sync completed", category: .sync)
    }
    
    /// Sync only inventory from all sources
    func syncCustomers() async {
        // Square -> Core Data
        await squareCustomerSync.syncCustomersFromSquare()
        
        // Core Data <-> Supabase
        try? await SupabaseSyncService.shared.syncCustomers()
    }
    
    /// Sync only inventory from all sources
    func syncInventory() async {
        // Square -> Core Data
        try? await squareInventorySync.importAllFromSquare()
        
        // Core Data <-> Supabase
        try? await SupabaseSyncService.shared.syncInventory()
    }
}
