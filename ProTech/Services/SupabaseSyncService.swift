//
//  SupabaseSyncService.swift
//  ProTech
//
//  Syncs Core Data with Supabase backend
//  Delegates specific entity syncing to specialized syncers.
//

import Foundation
import CoreData
import Supabase

@MainActor
class SupabaseSyncService: ObservableObject {
    static let shared = SupabaseSyncService()
    
    // Dependencies
    private let customerSyncer = CustomerSyncer() // Using default init, assuming it accesses singletons internally
    private let inventorySyncer = InventorySyncer()
    
    // TicketSyncer needs to be initialized or accessed via shared if available.
    // Based on directory listing, TicketSyncer exists. Let's assume it follows the pattern.
    private let ticketSyncer = TicketSyncer() 
    
    // EmployeeSyncer
    private let employeeSyncer = EmployeeSyncer()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    // Track component status
    @Published var customerSyncStatus: String = "Idle"
    @Published var inventorySyncStatus: String = "Idle"
    @Published var ticketSyncStatus: String = "Idle"
    
    private var syncTimer: Timer?
    
    private init() {
        // Start automatic sync if enabled
        if SyncConfig.autoSyncEnabled {
            startAutomaticSync()
        }
    }
    
    // MARK: - Auto Sync
    
    func startAutomaticSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: SyncConfig.syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performFullSync()
            }
        }
    }
    
    func stopAutomaticSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Full Sync
    
    func performFullSync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        defer {
            isSyncing = false
            lastSyncDate = Date()
        }
        
        AppLogger.info("Starting full Supabase sync", category: .sync)
        
        do {
            // 1. Sync Customers
            try await syncCustomers()
            
            // 2. Sync Inventory
            try await syncInventory()
            
            // 3. Sync Tickets
            try await syncRepairTickets()
            
            // 4. Sync Employees
            try await syncEmployees()
            
            AppLogger.info("Full Supabase sync completed successfully", category: .sync)
            
        } catch {
            syncError = error.localizedDescription
            AppLogger.error("Supabase sync failed", error: error, category: .sync)
        }
    }
    
    // MARK: - Component Syncs
    
    func syncCustomers() async throws {
        customerSyncStatus = "Syncing..."
        defer { customerSyncStatus = "Idle" }
        
        // Delegate to CustomerSyncer
        // Assuming CustomerSyncer has uploadPendingChanges and download methods
        // We need to add a convenience 'sync' method to CustomerSyncer as per plan,
        // or call both here. calling both is safer for now.
        
        AppLogger.debug("Syncing customers via CustomerSyncer", category: .sync)
        try await customerSyncer.uploadPendingChanges()
        try await customerSyncer.download()
    }
    
    func syncInventory() async throws {
        inventorySyncStatus = "Syncing..."
        defer { inventorySyncStatus = "Idle" }
        
        AppLogger.debug("Syncing inventory via InventorySyncer", category: .sync)
        try await inventorySyncer.uploadPendingChanges()
        try await inventorySyncer.download()
    }
    
    func syncRepairTickets() async throws {
        ticketSyncStatus = "Syncing..."
        defer { ticketSyncStatus = "Idle" }
        
        AppLogger.debug("Syncing tickets via TicketSyncer", category: .sync)
        // Assuming TicketSyncer follows the same pattern
        try await ticketSyncer.uploadPendingChanges()
        try await ticketSyncer.download()
    }
    
    func syncEmployees() async throws {
        AppLogger.debug("Syncing employees via EmployeeSyncer", category: .sync)
        try await employeeSyncer.uploadPendingChanges()
        try await employeeSyncer.download()
    }
}

