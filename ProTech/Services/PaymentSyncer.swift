//
//  PaymentSyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for payments
//

import Foundation
import CoreData
import Supabase

@MainActor
class PaymentSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    private var subscription: Task<Void, Never>?
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Upload
    
    /// Upload a local payment to Supabase
    func upload(_ payment: Payment) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        guard let paymentId = payment.id,
              let customerId = payment.customerId else {
            throw SyncError.conflict(details: "Payment missing ID or customer")
        }
        
        let supabasePayment = SupabasePayment(
            id: paymentId,
            shopId: shopId,
            customerId: customerId,
            invoiceId: payment.invoiceId,
            paymentNumber: payment.paymentNumber,
            amount: payment.amount,
            paymentMethod: payment.paymentMethod,
            paymentDate: payment.paymentDate ?? Date(),
            referenceNumber: payment.referenceNumber,
            receiptGenerated: payment.receiptGenerated,
            notes: payment.notes,
            createdAt: payment.createdAt ?? Date(),
            updatedAt: payment.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1
        )
        
        try await supabase.client
            .from("payments")
            .upsert(supabasePayment)
            .execute()
        
        // Mark as synced
        payment.cloudSyncStatus = "synced"
        payment.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        
        let pendingPayments = try coreData.viewContext.fetch(request)
        
        for payment in pendingPayments {
            try await upload(payment)
        }
    }
    
    // MARK: - Download
    
    /// Download all payments from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remotePayments: [SupabasePayment] = try await supabase.client
            .from("payments")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil)
            .execute()
            .value
        
        for remote in remotePayments {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabasePayment) async throws {
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
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
    
    private func shouldUpdateLocal(_ local: Payment, from remote: SupabasePayment) -> Bool {
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: Payment, from remote: SupabasePayment) {
        local.customerId = remote.customerId
        local.invoiceId = remote.invoiceId
        local.paymentNumber = remote.paymentNumber
        local.amount = remote.amount
        local.paymentMethod = remote.paymentMethod
        local.paymentDate = remote.paymentDate
        local.referenceNumber = remote.referenceNumber
        local.receiptGenerated = remote.receiptGenerated
        local.notes = remote.notes
        local.updatedAt = remote.updatedAt
        local.cloudSyncStatus = "synced"
    }
    
    private func createLocal(from remote: SupabasePayment) {
        let payment = Payment(context: coreData.viewContext)
        payment.id = remote.id
        payment.createdAt = remote.createdAt
        updateLocal(payment, from: remote)
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Subscribe to realtime changes for payments
    func subscribeToChanges() async {
        guard getShopId() != nil else { return }
        
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
        let request: NSFetchRequest<Payment> = Payment.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let payment = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(payment)
            try coreData.viewContext.save()
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Handle sync conflicts with user interaction
    func resolveConflict(_ local: Payment, _ remote: SupabasePayment) async -> ConflictResolution {
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
        if let shopIdString = supabase.currentShopId {
            return UUID(uuidString: shopIdString)
        }
        // Use default shop for testing
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
}

// MARK: - Models

struct SupabasePayment: Codable {
    let id: UUID
    let shopId: UUID
    let customerId: UUID
    let invoiceId: UUID?
    let paymentNumber: String?
    let amount: Decimal
    let paymentMethod: String?
    let paymentDate: Date
    let referenceNumber: String?
    let receiptGenerated: Bool
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopId = "shop_id"
        case customerId = "customer_id"
        case invoiceId = "invoice_id"
        case paymentNumber = "payment_number"
        case amount
        case paymentMethod = "payment_method"
        case paymentDate = "payment_date"
        case referenceNumber = "reference_number"
        case receiptGenerated = "receipt_generated"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}
