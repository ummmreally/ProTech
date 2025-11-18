//
//  CustomerSyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for customers
//

import Foundation
import CoreData
import Supabase

@MainActor
class CustomerSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    private var subscription: Task<Void, Never>?
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Upload
    
    /// Upload a local customer to Supabase
    func upload(_ customer: Customer) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        guard let customerId = customer.id else {
            throw SyncError.conflict(details: "Customer missing ID")
        }
        
        let supabaseCustomer = SupabaseCustomer(
            id: customerId,
            shopId: shopId,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email,
            phone: customer.phone,
            address: customer.address,
            notes: customer.notes,
            squareCustomerId: customer.squareCustomerId,
            createdAt: customer.createdAt ?? Date(),
            updatedAt: customer.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1 // Default sync version
        )
        
        try await supabase.client
            .from("customers")
            .upsert(supabaseCustomer)
            .execute()
        
        // Mark as synced
        customer.cloudSyncStatus = "synced"
        customer.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        
        let pendingCustomers = try coreData.viewContext.fetch(request)
        
        for customer in pendingCustomers {
            try await upload(customer)
        }
    }
    
    // MARK: - Download
    
    /// Download all customers from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteCustomers: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil) // Only get non-deleted records
            .execute()
            .value
        
        for remote in remoteCustomers {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabaseCustomer) async throws {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let local = results.first {
            // Merge existing: use newest version
            if shouldUpdateLocal(local, from: remote) {
                updateLocal(local, from: remote)
            }
        } else {
            // Create new local record
            createLocal(from: remote)
        }
        
        try coreData.viewContext.save()
    }
    
    private func shouldUpdateLocal(_ local: Customer, from remote: SupabaseCustomer) -> Bool {
        // Use timestamp for comparison since Customer doesn't have syncVersion
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: Customer, from remote: SupabaseCustomer) {
        local.firstName = remote.firstName
        local.lastName = remote.lastName
        local.email = remote.email
        local.phone = remote.phone
        local.address = remote.address
        local.notes = remote.notes
        local.squareCustomerId = remote.squareCustomerId
        local.updatedAt = remote.updatedAt
        // Note: Customer entity doesn't have syncVersion property
        local.cloudSyncStatus = "synced"
    }
    
    private func createLocal(from remote: SupabaseCustomer) {
        let customer = Customer(context: coreData.viewContext)
        customer.id = remote.id
        customer.createdAt = remote.createdAt
        updateLocal(customer, from: remote)
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Subscribe to realtime changes for customers
    func subscribeToChanges() async {
        guard getShopId() != nil else { return }
        
        // TODO: Implement realtime subscription with proper Supabase Realtime API
        // The realtime API requires proper channel setup and event handling
        // For now, use polling via download() at intervals
        subscription = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                try? await self.download()
            }
        }
    }
    
    func unsubscribe() {
        subscription?.cancel()
        subscription = nil
    }
    
    private func deleteLocal(id: UUID) async throws {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let customer = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(customer)
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Handle sync conflicts with user interaction
    func resolveConflict(_ local: Customer, _ remote: SupabaseCustomer) async -> ConflictResolution {
        // For now, use automatic resolution based on configuration
        switch SyncConfig.conflictStrategy {
        case .serverWins:
            return .useRemote
        case .localWins:
            return .useLocal
        case .newestWins:
            let localDate = local.updatedAt ?? Date.distantPast
            return remote.updatedAt > localDate ? .useRemote : .useLocal
        }
    }
    
    // MARK: - Helpers
    
    private func getShopId() -> UUID? {
        // Get from auth JWT claims or use default for testing
        if let shopIdString = supabase.currentShopId {
            return UUID(uuidString: shopIdString)
        }
        // Use default shop for testing
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
}

// MARK: - Models

struct SupabaseCustomer: Codable {
    let id: UUID
    let shopId: UUID
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let address: String?
    let notes: String?
    let squareCustomerId: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopId = "shop_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case phone
        case address
        case notes
        case squareCustomerId = "square_customer_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// SyncError is defined in SyncErrors.swift

enum ConflictResolution {
    case useLocal
    case useRemote
    case merge
}

// Note: Conflict resolution strategy is defined in SupabaseConfig.swift
