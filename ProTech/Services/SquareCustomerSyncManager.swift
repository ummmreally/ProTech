//
//  SquareCustomerSyncManager.swift
//  ProTech
//
//  Orchestrates synchronization between ProTech and Square customers
//

import Foundation
import CoreData
import Combine

@MainActor
class SquareCustomerSyncManager: ObservableObject {
    static let shared = SquareCustomerSyncManager()
    
    @Published var syncStatus: SyncManagerStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    @Published var currentOperation: String?
    @Published var syncStats = CustomerSyncStats()
    
    private let apiService: SquareAPIService
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext, apiService: SquareAPIService = .shared) {
        self.context = context
        self.apiService = apiService
    }
    
    func importAllFromSquare() async throws {
        await syncCustomersFromSquare()
    }
    
    func exportAllToSquare() async throws {
        // Not implemented yet
        throw SquareAPIError.apiError(message: "Export not implemented")
    }
    
    func syncAll() async throws {
        try await importAllFromSquare()
    }
    
    func getLocalCustomersCount() -> Int {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }
    
    func getSyncedCustomersCount() -> Int {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "squareCustomerId != nil AND cloudSyncStatus == 'synced'")
        return (try? context.count(for: request)) ?? 0
    }
    
    func getUnsyncedCustomersCount() -> Int {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "squareCustomerId == nil OR cloudSyncStatus != 'synced'")
        return (try? context.count(for: request)) ?? 0
    }
    
    func syncCustomersFromSquare() async {
        guard apiService.isConfigured else {
            errorMessage = "Square is not configured"
            syncStatus = .error("Square is not configured")
            return
        }
        
        syncStatus = .syncing
        currentOperation = "Fetching customers..."
        syncProgress = 0.0
        errorMessage = nil
        syncStats = CustomerSyncStats()
        
        do {
            var cursor: String?
            var hasMore = true
            var totalSynced = 0
            
            // Basic progress estimation - assuming batch of 100
            // In a real scenario, we might want to fetch counts first if available
            
            while hasMore {
                let response = try await apiService.listCustomers(cursor: cursor)
                
                if let customers = response.customers {
                    currentOperation = "Saving \(customers.count) customers..."
                    await saveCustomersToCoreData(customers)
                    totalSynced += customers.count
                }
                
                cursor = response.cursor
                hasMore = cursor != nil
                
                // Artificially advance progress for infinite loading feel until done
                if syncProgress < 0.9 {
                    syncProgress += 0.1
                }
            }
            
            lastSyncDate = Date()
            syncStatus = .completed
            syncProgress = 1.0
            
        } catch {
            AppLogger.error("Square Sync Error", error: error, category: .sync)
            errorMessage = error.localizedDescription
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    private func saveCustomersToCoreData(_ squareCustomers: [SquareCustomer]) async {
        await context.perform {
            for squareCustomer in squareCustomers {
                self.upsertCustomer(squareCustomer)
            }
            
            do {
                if self.context.hasChanges {
                    try self.context.save()
                }
            } catch {
                AppLogger.error("Error saving customers", error: error, category: .database)
            }
        }
    }
    
    private func upsertCustomer(_ squareCust: SquareCustomer) {
        // Try to find by squareCustomerId
        let fetchRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "squareCustomerId == %@", squareCust.id)
        fetchRequest.fetchLimit = 1
        
        var customer: Customer!
        
        if let existing = try? context.fetch(fetchRequest).first {
            customer = existing
        } else {
            // Try to find by email if available, to avoid duplicates if they were created locally
            if let email = squareCust.emailAddress, !email.isEmpty {
                 let emailRequest: NSFetchRequest<Customer> = Customer.fetchRequest()
                 emailRequest.predicate = NSPredicate(format: "email == %@", email)
                 emailRequest.fetchLimit = 1
                 if let existingByEmail = try? context.fetch(emailRequest).first {
                     customer = existingByEmail
                 }
            }
        }
        
        if customer == nil {
            customer = Customer(context: context)
            customer.id = UUID()
            customer.createdAt = Date() // Or parse squareCust.createdAt if desired
        }
        
        // Update fields
        customer.squareCustomerId = squareCust.id
        customer.firstName = squareCust.givenName
        customer.lastName = squareCust.familyName
        customer.email = squareCust.emailAddress
        customer.phone = squareCust.phoneNumber
        customer.notes = squareCust.note
        
        // Address flattening
        if let addr = squareCust.address {
            customer.address = addr.formattedAddress
        }
        
        customer.updatedAt = Date() 
        customer.cloudSyncStatus = "synced" // We just pulled it, so it's in sync
        
        DispatchQueue.main.async {
            self.syncStats.imported += 1
            self.syncStats.total += 1
        }
    }
}

struct CustomerSyncStats {
    var imported: Int = 0
    var exported: Int = 0
    var updated: Int = 0
    var failed: Int = 0
    var total: Int = 0
}
