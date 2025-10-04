//
//  SquareCustomerSyncManager.swift
//  ProTech
//
//  Manages synchronization between ProTech and Square customers
//

import Foundation
import CoreData
import Combine

@MainActor
class SquareCustomerSyncManager: ObservableObject {
    @Published var syncStatus: SyncManagerStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var currentOperation: String?
    @Published var syncStats: CustomerSyncStats = CustomerSyncStats()
    
    private let apiService: SquareAPIService
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext, apiService: SquareAPIService = .shared) {
        self.context = context
        self.apiService = apiService
        loadLastSyncDate()
    }
    
    // MARK: - Import from Square
    
    func importAllFromSquare() async throws {
        syncStatus = .syncing
        currentOperation = "Importing customers from Square..."
        syncProgress = 0.0
        syncStats = CustomerSyncStats()
        errorMessage = nil
        
        let startTime = Date()
        var cursor: String?
        var hasMore = true
        var totalFetched = 0
        
        do {
            while hasMore {
                currentOperation = "Fetching customers from Square... (\(totalFetched) so far)"
                
                let response = try await apiService.listCustomers(cursor: cursor, limit: 100)
                
                if let customers = response.customers {
                    for squareCustomer in customers {
                        try await importSquareCustomer(squareCustomer)
                        syncStats.imported += 1
                        totalFetched += 1
                    }
                }
                
                cursor = response.cursor
                hasMore = cursor != nil
                
                syncProgress = min(0.9, Double(totalFetched) / 100.0)
            }
            
            try context.save()
            
            syncStatus = .completed
            lastSyncDate = Date()
            saveLastSyncDate()
            syncProgress = 1.0
            currentOperation = nil
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Customer import completed: \(syncStats.imported) imported in \(String(format: "%.1f", duration))s")
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            currentOperation = nil
            print("❌ Customer import failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Export to Square
    
    func exportAllToSquare() async throws {
        syncStatus = .syncing
        currentOperation = "Exporting customers to Square..."
        syncProgress = 0.0
        syncStats = CustomerSyncStats()
        errorMessage = nil
        
        let startTime = Date()
        
        do {
            let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "squareCustomerId == nil OR squareCustomerId == %@", "")
            
            let localCustomers = try context.fetch(fetchRequest)
            let total = localCustomers.count
            
            currentOperation = "Exporting \(total) customers to Square..."
            
            for (index, customer) in localCustomers.enumerated() {
                try await exportCustomerToSquare(customer)
                syncStats.exported += 1
                
                syncProgress = Double(index + 1) / Double(total)
                currentOperation = "Exported \(index + 1) of \(total) customers..."
                
                // Rate limiting: pause briefly between requests
                if index % 10 == 0 && index > 0 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                }
            }
            
            try context.save()
            
            syncStatus = .completed
            lastSyncDate = Date()
            saveLastSyncDate()
            syncProgress = 1.0
            currentOperation = nil
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Customer export completed: \(syncStats.exported) exported in \(String(format: "%.1f", duration))s")
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            currentOperation = nil
            print("❌ Customer export failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Bidirectional Sync
    
    func syncAll() async throws {
        syncStatus = .syncing
        currentOperation = "Starting bidirectional sync..."
        syncProgress = 0.0
        syncStats = CustomerSyncStats()
        errorMessage = nil
        
        let startTime = Date()
        
        do {
            // Phase 1: Import from Square (50% of progress)
            currentOperation = "Phase 1: Importing from Square..."
            try await importAllFromSquare()
            syncProgress = 0.5
            
            // Phase 2: Export to Square (remaining 50%)
            currentOperation = "Phase 2: Exporting to Square..."
            let exportStats = syncStats
            try await exportAllToSquare()
            
            // Combine stats
            syncStats.imported = exportStats.imported
            syncStats.exported += exportStats.exported
            
            syncStatus = .completed
            lastSyncDate = Date()
            saveLastSyncDate()
            syncProgress = 1.0
            currentOperation = nil
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ Bidirectional sync completed in \(String(format: "%.1f", duration))s")
            print("   Imported: \(syncStats.imported), Exported: \(syncStats.exported), Updated: \(syncStats.updated)")
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
            currentOperation = nil
            print("❌ Bidirectional sync failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Individual Operations
    
    private func importSquareCustomer(_ squareCustomer: SquareCustomer) async throws {
        // Check if customer already exists by Square ID
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "squareCustomerId == %@", squareCustomer.id)
        
        let existingCustomers = try context.fetch(fetchRequest)
        let customer: Customer
        
        if let existing = existingCustomers.first {
            customer = existing
            syncStats.updated += 1
        } else {
            customer = Customer(context: context)
            customer.id = UUID()
            customer.squareCustomerId = squareCustomer.id
            customer.createdAt = Date()
        }
        
        // Update customer data
        customer.firstName = squareCustomer.givenName
        customer.lastName = squareCustomer.familyName
        customer.email = squareCustomer.emailAddress
        customer.phone = squareCustomer.phoneNumber
        customer.address = squareCustomer.address?.formattedAddress
        customer.notes = squareCustomer.note
        customer.updatedAt = Date()
        customer.cloudSyncStatus = "synced"
    }
    
    private func exportCustomerToSquare(_ customer: Customer) async throws {
        // Prepare address if available
        var squareAddress: SquareAddress?
        if let addressString = customer.address, !addressString.isEmpty {
            squareAddress = SquareAddress(
                addressLine1: addressString,
                addressLine2: nil,
                addressLine3: nil,
                locality: nil,
                sublocality: nil,
                administrativeDistrictLevel1: nil,
                postalCode: nil,
                country: nil
            )
        }
        
        if let squareId = customer.squareCustomerId, !squareId.isEmpty {
            // Update existing Square customer
            _ = try await apiService.updateCustomer(
                customerId: squareId,
                givenName: customer.firstName,
                familyName: customer.lastName,
                emailAddress: customer.email,
                phoneNumber: customer.phone,
                address: squareAddress,
                note: customer.notes
            )
            
            customer.updatedAt = Date()
            customer.cloudSyncStatus = "synced"
            syncStats.updated += 1
            
        } else {
            // Create new Square customer
            let squareCustomer = try await apiService.createCustomer(
                givenName: customer.firstName,
                familyName: customer.lastName,
                emailAddress: customer.email,
                phoneNumber: customer.phone,
                address: squareAddress,
                note: customer.notes,
                referenceId: customer.id?.uuidString
            )
            
            customer.squareCustomerId = squareCustomer.id
            customer.updatedAt = Date()
            customer.cloudSyncStatus = "synced"
        }
    }
    
    // MARK: - Sync by Email/Phone (Smart Matching)
    
    func syncCustomerByEmail(_ email: String) async throws -> Customer? {
        let query = CustomerQuery(
            filter: CustomerFilter(
                createdAt: nil,
                updatedAt: nil,
                emailAddress: CustomerTextFilter(exact: email, fuzzy: nil),
                phoneNumber: nil
            ),
            sort: nil
        )
        
        let response = try await apiService.searchCustomers(query: query, limit: 1)
        
        if let squareCustomer = response.customers?.first {
            try await importSquareCustomer(squareCustomer)
            try context.save()
            
            let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "squareCustomerId == %@", squareCustomer.id)
            return try context.fetch(fetchRequest).first
        }
        
        return nil
    }
    
    func syncCustomerByPhone(_ phone: String) async throws -> Customer? {
        let query = CustomerQuery(
            filter: CustomerFilter(
                createdAt: nil,
                updatedAt: nil,
                emailAddress: nil,
                phoneNumber: CustomerTextFilter(exact: phone, fuzzy: nil)
            ),
            sort: nil
        )
        
        let response = try await apiService.searchCustomers(query: query, limit: 1)
        
        if let squareCustomer = response.customers?.first {
            try await importSquareCustomer(squareCustomer)
            try context.save()
            
            let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "squareCustomerId == %@", squareCustomer.id)
            return try context.fetch(fetchRequest).first
        }
        
        return nil
    }
    
    // MARK: - Statistics
    
    func getLocalCustomersCount() -> Int {
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    func getSyncedCustomersCount() -> Int {
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "squareCustomerId != nil AND squareCustomerId != %@", "")
        return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    func getUnsyncedCustomersCount() -> Int {
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "squareCustomerId == nil OR squareCustomerId == %@", "")
        return (try? context.count(for: fetchRequest)) ?? 0
    }
    
    // MARK: - Persistence
    
    private func loadLastSyncDate() {
        if let date = UserDefaults.standard.object(forKey: "SquareCustomerLastSyncDate") as? Date {
            lastSyncDate = date
        }
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "SquareCustomerLastSyncDate")
    }
}

// MARK: - Supporting Types

struct CustomerSyncStats {
    var imported: Int = 0
    var exported: Int = 0
    var updated: Int = 0
    var failed: Int = 0
    
    var total: Int {
        imported + exported + updated
    }
}
