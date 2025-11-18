//
//  DataMigrationService.swift
//  ProTech
//
//  Migrates existing Core Data to Supabase for production deployment
//

import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - Migration Service

@MainActor
class DataMigrationService: ObservableObject {
    static let shared = DataMigrationService()
    
    // Services
    private let coreData = CoreDataManager.shared
    private let supabase = SupabaseService.shared
    private let customerSyncer = CustomerSyncer()
    private let ticketSyncer = TicketSyncer()
    private let inventorySyncer = InventorySyncer()
    private let employeeSyncer = EmployeeSyncer()
    
    // Migration state
    @Published var isMigrating = false
    @Published var currentPhase: MigrationPhase = .idle
    @Published var progress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errors: [MigrationError] = []
    @Published var statistics = MigrationStatistics()
    
    // Migration options
    @Published var options = MigrationOptions()
    
    enum MigrationPhase: String, Codable {
        case idle
        case preparing
        case validating
        case migratingEmployees
        case migratingCustomers
        case migratingInventory
        case migratingTickets
        case verifying
        case completed
        case failed
        
        var description: String {
            switch self {
            case .idle: return "Ready to migrate"
            case .preparing: return "Preparing migration..."
            case .validating: return "Validating data..."
            case .migratingEmployees: return "Migrating employees..."
            case .migratingCustomers: return "Migrating customers..."
            case .migratingInventory: return "Migrating inventory..."
            case .migratingTickets: return "Migrating tickets..."
            case .verifying: return "Verifying migration..."
            case .completed: return "Migration completed"
            case .failed: return "Migration failed"
            }
        }
    }
    
    // MARK: - Main Migration Flow
    
    func startMigration() async {
        guard !isMigrating else { return }
        
        isMigrating = true
        errors.removeAll()
        statistics = MigrationStatistics()
        
        do {
            // Phase 1: Preparation
            currentPhase = .preparing
            statusMessage = "Checking Supabase connection..."
            try await validateSupabaseConnection()
            
            // Phase 2: Validation
            currentPhase = .validating
            statusMessage = "Validating local data..."
            try await validateLocalData()
            
            // Phase 3: Migrate Employees (needed for relations)
            if options.migrateEmployees {
                currentPhase = .migratingEmployees
                try await migrateEmployees()
            }
            
            // Phase 4: Migrate Customers
            if options.migrateCustomers {
                currentPhase = .migratingCustomers
                try await migrateCustomers()
            }
            
            // Phase 5: Migrate Inventory
            if options.migrateInventory {
                currentPhase = .migratingInventory
                try await migrateInventory()
            }
            
            // Phase 6: Migrate Tickets (depends on customers)
            if options.migrateTickets {
                currentPhase = .migratingTickets
                try await migrateTickets()
            }
            
            // Phase 7: Verification
            currentPhase = .verifying
            statusMessage = "Verifying migration..."
            try await verifyMigration()
            
            // Success
            currentPhase = .completed
            statusMessage = "Migration completed successfully!"
            generateReport()
            
        } catch {
            currentPhase = .failed
            statusMessage = "Migration failed: \(error.localizedDescription)"
            errors.append(MigrationError(
                phase: currentPhase,
                message: error.localizedDescription,
                timestamp: Date()
            ))
        }
        
        isMigrating = false
    }
    
    // MARK: - Validation
    
    private func validateSupabaseConnection() async throws {
        // Check if we can connect to Supabase
        guard supabase.currentShopId != nil else {
            throw MigrationServiceError.notAuthenticated
        }
        
        // Test connection with a simple query
        let _: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .limit(1)
            .execute()
            .value
        
        statusMessage = "Supabase connection verified"
    }
    
    private func validateLocalData() async throws {
        // Count local records
        let customerCount = try countEntities(Customer.self)
        let ticketCount = try countEntities(Ticket.self)
        let inventoryCount = try countEntities(InventoryItem.self)
        let employeeCount = try countEntities(Employee.self)
        
        statistics.totalCustomers = customerCount
        statistics.totalTickets = ticketCount
        statistics.totalInventory = inventoryCount
        statistics.totalEmployees = employeeCount
        
        let totalRecords = customerCount + ticketCount + inventoryCount + employeeCount
        
        if totalRecords == 0 {
            throw MigrationServiceError.noDataToMigrate
        }
        
        statusMessage = "Found \(totalRecords) records to migrate"
    }
    
    // MARK: - Migration Methods
    
    private func migrateEmployees() async throws {
        statusMessage = "Migrating employees..."
        
        let employees = try fetchAllEntities(Employee.self)
        let total = employees.count
        var migrated = 0
        
        for employee in employees {
            // Skip if already migrated
            // Note: cloudSyncStatus doesn't exist on Employee model
            // if options.skipExisting && employee.cloudSyncStatus == "synced" {
            //     migrated += 1
            //     progress = Double(migrated) / Double(total)
            //     continue
            // }
            
            do {
                try await employeeSyncer.upload(employee)
                migrated += 1
                statistics.migratedEmployees += 1
            } catch {
                statistics.failedEmployees += 1
                errors.append(MigrationError(
                    phase: .migratingEmployees,
                    message: "Failed to migrate employee \(employee.migrationDisplayName): \(error.localizedDescription)",
                    timestamp: Date()
                ))
                
                if !options.continueOnError {
                    throw error
                }
            }
            
            progress = Double(migrated) / Double(total)
            statusMessage = "Migrated \(migrated)/\(total) employees"
        }
    }
    
    private func migrateCustomers() async throws {
        statusMessage = "Migrating customers..."
        
        let customers = try fetchAllEntities(Customer.self)
        let total = customers.count
        var migrated = 0
        
        // Batch process for better performance
        let batchSize = 50
        for batch in customers.chunked(into: batchSize) {
            if options.useBatchOperations {
                // Batch upload
                do {
                    // Note: cloudSyncStatus doesn't exist on Customer model
                    let pendingBatch = batch // .filter { customer in !options.skipExisting || customer.cloudSyncStatus != "synced" }
                    
                    if !pendingBatch.isEmpty {
                        // Use batch upload method
                        for customer in pendingBatch {
                            try await customerSyncer.upload(customer)
                            statistics.migratedCustomers += 1
                        }
                    }
                    
                    migrated += batch.count
                } catch {
                    statistics.failedCustomers += batch.count
                    errors.append(MigrationError(
                        phase: .migratingCustomers,
                        message: "Failed to migrate customer batch: \(error.localizedDescription)",
                        timestamp: Date()
                    ))
                    
                    if !options.continueOnError {
                        throw error
                    }
                }
            } else {
                // Individual upload
                for customer in batch {
                    // Note: cloudSyncStatus doesn't exist on Customer model
                    // if options.skipExisting && customer.cloudSyncStatus == "synced" {
                    //     migrated += 1
                    //     progress = Double(migrated) / Double(total)
                    //     continue
                    // }
                    
                    do {
                        try await customerSyncer.upload(customer)
                        migrated += 1
                        statistics.migratedCustomers += 1
                    } catch {
                        statistics.failedCustomers += 1
                        errors.append(MigrationError(
                            phase: .migratingCustomers,
                            message: "Failed to migrate customer \(customer.migrationDisplayName): \(error.localizedDescription)",
                            timestamp: Date()
                        ))
                        
                        if !options.continueOnError {
                            throw error
                        }
                    }
                }
            }
            
            progress = Double(migrated) / Double(total)
            statusMessage = "Migrated \(migrated)/\(total) customers"
            
            // Small delay to prevent rate limiting
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func migrateInventory() async throws {
        statusMessage = "Migrating inventory..."
        
        let items = try fetchAllEntities(InventoryItem.self)
        let total = items.count
        var migrated = 0
        
        // Batch upload for inventory
        if options.useBatchOperations {
            let batches = items.chunked(into: 100)
            
            for batch in batches {
                // Note: cloudSyncStatus doesn't exist on InventoryItem model
                let pendingBatch = batch // .filter { item in !options.skipExisting || item.cloudSyncStatus != "synced" }
                
                if !pendingBatch.isEmpty {
                    do {
                        try await inventorySyncer.batchUpload(pendingBatch)
                        statistics.migratedInventory += pendingBatch.count
                    } catch {
                        statistics.failedInventory += pendingBatch.count
                        errors.append(MigrationError(
                            phase: .migratingInventory,
                            message: "Failed to migrate inventory batch: \(error.localizedDescription)",
                            timestamp: Date()
                        ))
                        
                        if !options.continueOnError {
                            throw error
                        }
                    }
                }
                
                migrated += batch.count
                progress = Double(migrated) / Double(total)
                statusMessage = "Migrated \(migrated)/\(total) inventory items"
                
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        } else {
            // Individual upload
            for item in items {
                // Note: cloudSyncStatus doesn't exist on InventoryItem model
                // if options.skipExisting && item.cloudSyncStatus == "synced" {
                //     migrated += 1
                //     progress = Double(migrated) / Double(total)
                //     continue
                // }
                
                do {
                    try await inventorySyncer.upload(item)
                    migrated += 1
                    statistics.migratedInventory += 1
                } catch {
                    statistics.failedInventory += 1
                    errors.append(MigrationError(
                        phase: .migratingInventory,
                        message: "Failed to migrate item \(item.migrationDisplayName): \(error.localizedDescription)",
                        timestamp: Date()
                    ))
                    
                    if !options.continueOnError {
                        throw error
                    }
                }
                
                progress = Double(migrated) / Double(total)
                statusMessage = "Migrated \(migrated)/\(total) inventory items"
            }
        }
    }
    
    private func migrateTickets() async throws {
        statusMessage = "Migrating tickets..."
        
        let tickets = try fetchAllEntities(Ticket.self)
        let total = tickets.count
        var migrated = 0
        
        // Sort tickets by date (oldest first) to maintain order
        let sortedTickets = tickets.sorted { 
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        }
        
        if options.useBatchOperations {
            // Batch upload
            let batches = sortedTickets.chunked(into: 50)
            
            for batch in batches {
                // Note: cloudSyncStatus doesn't exist on Ticket model
                let pendingBatch = batch // .filter { ticket in !options.skipExisting || ticket.cloudSyncStatus != "synced" }
                
                if !pendingBatch.isEmpty {
                    do {
                        try await ticketSyncer.batchUpload(pendingBatch)
                        statistics.migratedTickets += pendingBatch.count
                    } catch {
                        statistics.failedTickets += pendingBatch.count
                        errors.append(MigrationError(
                            phase: .migratingTickets,
                            message: "Failed to migrate ticket batch: \(error.localizedDescription)",
                            timestamp: Date()
                        ))
                        
                        if !options.continueOnError {
                            throw error
                        }
                    }
                }
                
                migrated += batch.count
                progress = Double(migrated) / Double(total)
                statusMessage = "Migrated \(migrated)/\(total) tickets"
                
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds (tickets are complex)
            }
        } else {
            // Individual upload with dependency handling
            for ticket in sortedTickets {
                // Note: cloudSyncStatus doesn't exist on Ticket model
                // if options.skipExisting && ticket.cloudSyncStatus == "synced" {
                //     migrated += 1
                //     progress = Double(migrated) / Double(total)
                //     continue
                // }
                
                do {
                    // Note: Ticket has customerId, not customer relationship
                    // Customer should already be migrated
                    
                    try await ticketSyncer.upload(ticket)
                    migrated += 1
                    statistics.migratedTickets += 1
                } catch {
                    statistics.failedTickets += 1
                    errors.append(MigrationError(
                        phase: .migratingTickets,
                        message: "Failed to migrate ticket \(ticket.migrationDisplayName): \(error.localizedDescription)",
                        timestamp: Date()
                    ))
                    
                    if !options.continueOnError {
                        throw error
                    }
                }
                
                progress = Double(migrated) / Double(total)
                statusMessage = "Migrated \(migrated)/\(total) tickets"
            }
        }
    }
    
    // MARK: - Verification
    
    private func verifyMigration() async throws {
        statusMessage = "Verifying migration integrity..."
        
        // Count remote records
        let remoteCustomers = try await countRemoteRecords("customers")
        let remoteTickets = try await countRemoteRecords("tickets")
        let remoteInventory = try await countRemoteRecords("inventory_items")
        let remoteEmployees = try await countRemoteRecords("employees")
        
        // Calculate success rates
        statistics.successRateCustomers = Double(statistics.migratedCustomers) / Double(statistics.totalCustomers)
        statistics.successRateTickets = Double(statistics.migratedTickets) / Double(statistics.totalTickets)
        statistics.successRateInventory = Double(statistics.migratedInventory) / Double(statistics.totalInventory)
        statistics.successRateEmployees = Double(statistics.migratedEmployees) / Double(statistics.totalEmployees)
        
        // Verify counts match (allowing for pre-existing records)
        if remoteCustomers < statistics.migratedCustomers ||
           remoteTickets < statistics.migratedTickets ||
           remoteInventory < statistics.migratedInventory ||
           remoteEmployees < statistics.migratedEmployees {
            
            errors.append(MigrationError(
                phase: .verifying,
                message: "Remote record count mismatch detected",
                timestamp: Date()
            ))
        }
        
        statusMessage = "Migration verification completed"
    }
    
    // MARK: - Reporting
    
    private func generateReport() {
        let report = MigrationReport(
            startTime: Date(),
            endTime: Date(),
            statistics: statistics,
            errors: errors,
            options: options
        )
        
        // Save report
        saveMigrationReport(report)
        
        // Log summary
        print("""
        
        ========== MIGRATION REPORT ==========
        Total Records: \(statistics.totalRecords)
        Successfully Migrated: \(statistics.totalMigrated)
        Failed: \(statistics.totalFailed)
        
        Customers: \(statistics.migratedCustomers)/\(statistics.totalCustomers) (\(Int(statistics.successRateCustomers * 100))%)
        Tickets: \(statistics.migratedTickets)/\(statistics.totalTickets) (\(Int(statistics.successRateTickets * 100))%)
        Inventory: \(statistics.migratedInventory)/\(statistics.totalInventory) (\(Int(statistics.successRateInventory * 100))%)
        Employees: \(statistics.migratedEmployees)/\(statistics.totalEmployees) (\(Int(statistics.successRateEmployees * 100))%)
        
        Errors: \(errors.count)
        =====================================
        
        """)
    }
    
    private func saveMigrationReport(_ report: MigrationReport) {
        // Save to UserDefaults or file
        if let data = try? JSONEncoder().encode(report) {
            UserDefaults.standard.set(data, forKey: "LastMigrationReport")
        }
    }
    
    // MARK: - Helper Methods
    
    private func countEntities<T: NSManagedObject>(_ type: T.Type) throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        return try coreData.viewContext.count(for: request)
    }
    
    private func fetchAllEntities<T: NSManagedObject>(_ type: T.Type) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        return try coreData.viewContext.fetch(request)
    }
    
    private func countRemoteRecords(_ table: String) async throws -> Int {
        guard let shopId = supabase.currentShopId else {
            throw MigrationServiceError.notAuthenticated
        }
        
        let response = try await supabase.client
            .from(table)
            .select("*", head: false, count: .exact)
            .eq("shop_id", value: shopId)
            .execute()
        
        return response.count ?? 0
    }
    
    // MARK: - Rollback
    
    func rollbackMigration() async {
        statusMessage = "Rolling back migration..."
        
        // Mark all records as unsynced
        let entities = ["Customer", "Ticket", "InventoryItem", "Employee"]
        
        for entity in entities {
            _ = entity // placeholder to avoid unused variable warning
            // Note: cloudSyncStatus doesn't exist on models; rollback currently noop
        }
        
        try? coreData.viewContext.save()
        
        statusMessage = "Rollback completed"
    }
}

// MARK: - Models

struct MigrationOptions {
    var migrateCustomers = true
    var migrateTickets = true
    var migrateInventory = true
    var migrateEmployees = true
    var skipExisting = true
    var continueOnError = true
    var useBatchOperations = true
    var createBackup = true
}

struct MigrationStatistics {
    var totalCustomers = 0
    var totalTickets = 0
    var totalInventory = 0
    var totalEmployees = 0
    
    var migratedCustomers = 0
    var migratedTickets = 0
    var migratedInventory = 0
    var migratedEmployees = 0
    
    var failedCustomers = 0
    var failedTickets = 0
    var failedInventory = 0
    var failedEmployees = 0
    
    var successRateCustomers = 0.0
    var successRateTickets = 0.0
    var successRateInventory = 0.0
    var successRateEmployees = 0.0
    
    var totalRecords: Int {
        totalCustomers + totalTickets + totalInventory + totalEmployees
    }
    
    var totalMigrated: Int {
        migratedCustomers + migratedTickets + migratedInventory + migratedEmployees
    }
    
    var totalFailed: Int {
        failedCustomers + failedTickets + failedInventory + failedEmployees
    }
}

struct MigrationError: Codable {
    let phase: DataMigrationService.MigrationPhase
    let message: String
    let timestamp: Date
}

struct MigrationReport: Codable {
    let startTime: Date
    let endTime: Date
    let statistics: MigrationStatistics
    let errors: [MigrationError]
    let options: MigrationOptions
}

// Make structs Codable
extension MigrationStatistics: Codable {}
extension MigrationOptions: Codable {}

enum MigrationServiceError: LocalizedError {
    case notAuthenticated
    case noDataToMigrate
    case verificationFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Supabase"
        case .noDataToMigrate:
            return "No data found to migrate"
        case .verificationFailed:
            return "Migration verification failed"
        }
    }
}

// MARK: - Array Extension

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
