//
//  InventorySyncer.swift
//  ProTech
//
//  Handles bidirectional sync between Core Data and Supabase for inventory items
//

import Foundation
import CoreData
import Supabase

@MainActor
class InventorySyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    @Published var isSyncing = false
    @Published var syncError: Error?
    @Published var lastSyncDate: Date?
    
    // MARK: - Upload
    
    /// Upload a local inventory item to Supabase
    func upload(_ item: InventoryItem) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        guard let itemId = item.id else {
            throw SyncError.conflict(details: "Inventory item missing ID")
        }
        
        let supabaseItem = SupabaseInventoryItem(
            id: itemId,
            shopId: shopId,
            sku: item.sku,
            partNumber: item.partNumber,
            name: item.name ?? "",
            category: item.category,
            cost: item.costDouble,
            price: item.priceDouble,
            quantity: Int(item.quantity),
            minQuantity: Int(item.minQuantity),
            isActive: item.isActive,
            createdAt: item.createdAt ?? Date(),
            updatedAt: item.updatedAt ?? Date(),
            deletedAt: nil,
            syncVersion: 1 // Default sync version
        )
        
        try await supabase.client
            .from("inventory_items")
            .upsert(supabaseItem)
            .execute()
        
        // Mark as synced
        item.cloudSyncStatus = "synced"
        item.updatedAt = Date()
        try coreData.viewContext.save()
    }
    
    /// Upload all pending local changes
    func uploadPendingChanges() async throws {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus == %@ OR cloudSyncStatus == nil", "pending")
        
        let pendingItems = try coreData.viewContext.fetch(request)
        
        for item in pendingItems {
            try await upload(item)
        }
    }
    
    // MARK: - Download
    
    /// Download all inventory items from Supabase and merge with local
    func download() async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let remoteItems: [SupabaseInventoryItem] = try await supabase.client
            .from("inventory_items")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil)
            .order("name", ascending: true)
            .execute()
            .value
        
        for remote in remoteItems {
            try await mergeOrCreate(remote)
        }
        
        lastSyncDate = Date()
    }
    
    // MARK: - Merge
    
    private func mergeOrCreate(_ remote: SupabaseInventoryItem) async throws {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
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
    
    private func shouldUpdateLocal(_ local: InventoryItem, from remote: SupabaseInventoryItem) -> Bool {
        let localDate = local.updatedAt ?? Date.distantPast
        return remote.updatedAt > localDate
    }
    
    private func updateLocal(_ local: InventoryItem, from remote: SupabaseInventoryItem) {
        local.sku = remote.sku
        local.partNumber = remote.partNumber
        local.name = remote.name
        local.category = remote.category
        local.cost = NSDecimalNumber(value: remote.cost)
        local.price = NSDecimalNumber(value: remote.price)
        local.quantity = Int32(remote.quantity)
        local.minQuantity = Int32(remote.minQuantity)
        local.isActive = remote.isActive
        local.updatedAt = remote.updatedAt
        local.cloudSyncStatus = "synced"
        // Note: syncVersion doesn't exist on InventoryItem model, using updatedAt for conflict resolution
    }
    
    private func createLocal(from remote: SupabaseInventoryItem) {
        let item = InventoryItem(context: coreData.viewContext)
        item.id = remote.id
        item.createdAt = remote.createdAt
        updateLocal(item, from: remote)
    }
    
    // MARK: - Low Stock Alerts
    
    /// Check for items below minimum stock and return them
    func checkLowStock() async throws -> [InventoryItem] {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let remoteItems: [SupabaseInventoryItem] = try await supabase.client
            .from("inventory_items")
            .select()
            .eq("shop_id", value: shopId.uuidString)
            .is("deleted_at", value: nil)
            .lte("quantity", value: "min_quantity")
            .execute()
            .value
        
        // Update local with low stock items
        for remote in remoteItems {
            try await mergeOrCreate(remote)
        }
        
        // Return local low stock items
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "quantity <= minQuantity AND isActive == true")
        
        return try coreData.viewContext.fetch(request)
    }
    
    // MARK: - Stock Adjustments
    
    /// Adjust stock quantity for an item
    func adjustStock(
        itemId: UUID,
        adjustment: Int,
        reason: String? = nil
    ) async throws {
        // Update locally first
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        guard let item = try coreData.viewContext.fetch(request).first else {
            throw SyncError.itemNotFound
        }
        
        let newQuantity = Int(item.quantity) + adjustment
        item.quantity = Int32(newQuantity)
        item.updatedAt = Date()
        item.cloudSyncStatus = "pending"
        
        try coreData.viewContext.save()
        
        // Upload to Supabase
        try await upload(item)
        
        // Log the adjustment (optional, for audit trail)
        if let reason = reason {
            await logStockAdjustment(itemId: itemId, adjustment: adjustment, reason: reason, newQuantity: newQuantity)
        }
    }
    
    private func logStockAdjustment(
        itemId: UUID,
        adjustment: Int,
        reason: String,
        newQuantity: Int
    ) async {
        // In production, you might want to create a stock_adjustments table
        print("Stock adjustment: Item \(itemId) adjusted by \(adjustment) to \(newQuantity). Reason: \(reason)")
    }
    
    // MARK: - Realtime Subscriptions
    
    /// Subscribe to realtime changes for inventory
    func subscribeToChanges() async {
        // TODO: Implement proper Supabase Realtime API
        print("Realtime subscriptions not yet implemented for InventorySyncer")
    }
    
    // TODO: Uncomment when Supabase Realtime types are available
    /*
    private func handleRealtimeChange(_ payload: PostgresChangePayload) async {
        guard let record = payload.record else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: record)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            let remoteItem = try decoder.decode(SupabaseInventoryItem.self, from: jsonData)
            
            switch payload.eventType {
            case .insert, .update:
                try await mergeOrCreate(remoteItem)
                
                // Check if low stock alert is needed
                if remoteItem.quantity <= remoteItem.minQuantity {
                    await sendLowStockNotification(remoteItem)
                }
            case .delete:
                try await deleteLocal(id: remoteItem.id)
            default:
                break
            }
        } catch {
            print("Failed to handle realtime change: \(error)")
            syncError = error
        }
    }
    */
    
    private func deleteLocal(id: UUID) async throws {
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        if let item = try coreData.viewContext.fetch(request).first {
            coreData.viewContext.delete(item)
            try coreData.viewContext.save()
        }
    }
    
    private func sendLowStockNotification(_ item: SupabaseInventoryItem) async {
        // Send notification to UI or notification service
        NotificationCenter.default.post(
            name: .lowStockAlert,
            object: nil,
            userInfo: [
                "itemId": item.id,
                "name": item.name,
                "quantity": item.quantity,
                "minQuantity": item.minQuantity
            ]
        )
    }
    
    // MARK: - Batch Operations
    
    /// Batch upload multiple inventory items
    func batchUpload(_ items: [InventoryItem]) async throws {
        guard let shopId = getShopId() else {
            throw SyncError.notAuthenticated
        }
        
        let supabaseItems = items.compactMap { item -> SupabaseInventoryItem? in
            guard let itemId = item.id else { return nil }
            return SupabaseInventoryItem(
                id: itemId,
                shopId: shopId,
                sku: item.sku,
                partNumber: item.partNumber,
                name: item.name ?? "",
                category: item.category,
                cost: item.cost.doubleValue,
                price: item.price.doubleValue,
                quantity: Int(item.quantity),
                minQuantity: Int(item.minQuantity),
                isActive: item.isActive,
                createdAt: item.createdAt ?? Date(),
                updatedAt: item.updatedAt ?? Date(),
                deletedAt: nil,
                syncVersion: 1 // Default sync version
            )
        }
        
        // Upload in batches of 100
        let batchSize = 100
        for batch in supabaseItems.chunked(into: batchSize) {
            try await supabase.client
                .from("inventory_items")
                .upsert(batch)
                .execute()
        }
        
        // Mark all as synced
        for item in items {
            item.cloudSyncStatus = "synced"
            item.updatedAt = Date()
        }
        
        try coreData.viewContext.save()
    }
    
    // MARK: - Helpers
    
    private func getShopId() -> UUID? {
        if let shopIdString = supabase.currentShopId {
            return UUID(uuidString: shopIdString)
        }
        return UUID(uuidString: "00000000-0000-0000-0000-000000000001")
    }
}

// MARK: - Models

struct SupabaseInventoryItem: Codable {
    let id: UUID
    let shopId: UUID
    let sku: String?
    let partNumber: String?
    let name: String
    let category: String?
    let cost: Double
    let price: Double
    let quantity: Int
    let minQuantity: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case shopId = "shop_id"
        case sku
        case partNumber = "part_number"
        case name
        case category
        case cost
        case price
        case quantity
        case minQuantity = "min_quantity"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
        case syncVersion = "sync_version"
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let lowStockAlert = Notification.Name("lowStockAlert")
}

// Note: SyncError.itemNotFound is already defined in SyncErrors.swift
