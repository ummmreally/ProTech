//
//  SquareInventorySyncManager.swift
//  ProTech
//
//  Orchestrates synchronization between ProTech and Square inventory
//

import Foundation
import SwiftData
import Combine

@MainActor
class SquareInventorySyncManager: ObservableObject {
    @Published var syncStatus: SyncManagerStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var currentOperation: String?
    
    private let apiService: SquareAPIService
    private let modelContext: ModelContext
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, apiService: SquareAPIService = .shared) {
        self.modelContext = modelContext
        self.apiService = apiService
        loadLastSyncDate()
    }
    
    // MARK: - Configuration
    
    func getConfiguration() -> SquareConfiguration? {
        let descriptor = FetchDescriptor<SquareConfiguration>()
        return try? modelContext.fetch(descriptor).first
    }
    
    func saveConfiguration(_ config: SquareConfiguration) throws {
        modelContext.insert(config)
        try modelContext.save()
        apiService.setConfiguration(config)
    }
    
    // MARK: - Initial Setup
    
    func performInitialSetup(accessToken: String, merchantId: String, locationId: String, environment: SquareEnvironment) async throws {
        syncStatus = .syncing
        currentOperation = "Setting up Square integration..."
        
        let config = SquareConfiguration(
            accessToken: accessToken,
            merchantId: merchantId,
            locationId: locationId,
            environment: environment
        )
        
        try saveConfiguration(config)
        
        syncStatus = .completed
        currentOperation = nil
    }
    
    func importAllFromSquare() async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Importing items from Square..."
        syncProgress = 0.0
        
        let startTime = Date()
        var importedCount = 0
        var cursor: String?
        var hasMore = true
        
        while hasMore {
            let response = try await apiService.listCatalogItems(cursor: cursor)
            
            if let objects = response.objects {
                for object in objects {
                    if object.type == .item, let itemData = object.itemData {
                        try await importSquareItem(object: object, itemData: itemData, locationId: config.locationId)
                        importedCount += 1
                    }
                }
            }
            
            cursor = response.cursor
            hasMore = cursor != nil
            
            syncProgress = min(0.9, Double(importedCount) / 100.0) // Estimate progress
        }
        
        // Log the import
        let log = SyncLog(
            operation: .batchImport,
            status: .synced,
            changedFields: [],
            syncDuration: Date().timeIntervalSince(startTime),
            details: "Imported \(importedCount) items from Square"
        )
        modelContext.insert(log)
        try modelContext.save()
        
        lastSyncDate = Date()
        syncProgress = 1.0
        syncStatus = .completed
        currentOperation = nil
    }
    
    func exportAllToSquare() async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Exporting items to Square..."
        syncProgress = 0.0
        
        let startTime = Date()
        
        // Fetch all inventory items
        let descriptor = FetchDescriptor<InventoryItem>()
        let items = try modelContext.fetch(descriptor)
        
        var exportedCount = 0
        let totalItems = items.count
        
        for item in items {
            // Check if already mapped
            if getMapping(for: item) == nil {
                try await exportItemToSquare(item: item, locationId: config.locationId)
                exportedCount += 1
            }
            
            syncProgress = Double(exportedCount) / Double(totalItems)
        }
        
        // Log the export
        let log = SyncLog(
            operation: .batchExport,
            status: .synced,
            changedFields: [],
            syncDuration: Date().timeIntervalSince(startTime),
            details: "Exported \(exportedCount) items to Square"
        )
        modelContext.insert(log)
        try modelContext.save()
        
        lastSyncDate = Date()
        syncProgress = 1.0
        syncStatus = .completed
        currentOperation = nil
    }
    
    // MARK: - Sync Operations
    
    func syncItem(_ item: InventoryItem, direction: SyncDirection) async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        let startTime = Date()
        
        if let mapping = getMapping(for: item) {
            // Item is already mapped, sync based on direction
            switch direction {
            case .toSquare:
                try await updateSquareItem(item: item, mapping: mapping, locationId: config.locationId)
            case .fromSquare:
                try await updateProTechItem(item: item, mapping: mapping)
            case .bidirectional:
                try await bidirectionalSync(item: item, mapping: mapping, locationId: config.locationId)
            }
        } else {
            // No mapping exists, create new item
            if direction == .toSquare || direction == .bidirectional {
                try await exportItemToSquare(item: item, locationId: config.locationId)
            }
        }
        
        // Log the sync
        let log = SyncLog(
            operation: .update,
            itemId: item.id,
            status: .synced,
            changedFields: [],
            syncDuration: Date().timeIntervalSince(startTime)
        )
        modelContext.insert(log)
        try modelContext.save()
    }
    
    func syncAllItems() async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Syncing all items..."
        syncProgress = 0.0
        
        let descriptor = FetchDescriptor<InventoryItem>()
        let items = try modelContext.fetch(descriptor)
        
        var syncedCount = 0
        let totalItems = items.count
        
        for item in items {
            try await syncItem(item, direction: config.defaultSyncDirection)
            syncedCount += 1
            syncProgress = Double(syncedCount) / Double(totalItems)
        }
        
        lastSyncDate = Date()
        syncProgress = 1.0
        syncStatus = .completed
        currentOperation = nil
    }
    
    func syncChangedItems(since date: Date) async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Syncing changed items..."
        
        // Fetch items modified since date
        var descriptor = FetchDescriptor<InventoryItem>(
            predicate: #Predicate { $0.lastModified ?? Date.distantPast > date }
        )
        let changedItems = try modelContext.fetch(descriptor)
        
        for item in changedItems {
            try await syncItem(item, direction: config.defaultSyncDirection)
        }
        
        lastSyncDate = Date()
        syncStatus = .completed
        currentOperation = nil
    }
    
    // MARK: - Mapping Management
    
    func createMapping(proTechItem: InventoryItem, squareObjectId: String, squareVariationId: String? = nil) throws -> SquareSyncMapping {
        let mapping = SquareSyncMapping(
            proTechItemId: proTechItem.id,
            squareCatalogObjectId: squareObjectId,
            squareVariationId: squareVariationId,
            syncStatus: .synced
        )
        
        modelContext.insert(mapping)
        try modelContext.save()
        
        // Log mapping creation
        let log = SyncLog(
            operation: .mappingCreated,
            itemId: proTechItem.id,
            squareObjectId: squareObjectId,
            status: .synced,
            changedFields: []
        )
        modelContext.insert(log)
        try modelContext.save()
        
        return mapping
    }
    
    func getMapping(for item: InventoryItem) -> SquareSyncMapping? {
        let descriptor = FetchDescriptor<SquareSyncMapping>(
            predicate: #Predicate { $0.proTechItemId == item.id }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func getMapping(forSquareObjectId objectId: String) -> SquareSyncMapping? {
        let descriptor = FetchDescriptor<SquareSyncMapping>(
            predicate: #Predicate { $0.squareCatalogObjectId == objectId }
        )
        return try? modelContext.fetch(descriptor).first
    }
    
    func removeMapping(_ mapping: SquareSyncMapping) throws {
        modelContext.delete(mapping)
        try modelContext.save()
        
        // Log mapping deletion
        let log = SyncLog(
            operation: .mappingDeleted,
            itemId: mapping.proTechItemId,
            squareObjectId: mapping.squareCatalogObjectId,
            status: .synced,
            changedFields: []
        )
        modelContext.insert(log)
        try modelContext.save()
    }
    
    // MARK: - Conflict Resolution
    
    func detectConflicts() async throws -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        let descriptor = FetchDescriptor<SquareSyncMapping>(
            predicate: #Predicate { $0.syncStatus == .conflict }
        )
        let conflictMappings = try modelContext.fetch(descriptor)
        
        for mapping in conflictMappings {
            // Fetch ProTech item
            let itemDescriptor = FetchDescriptor<InventoryItem>(
                predicate: #Predicate { $0.id == mapping.proTechItemId }
            )
            guard let proTechItem = try modelContext.fetch(itemDescriptor).first else { continue }
            
            // Fetch Square item
            let squareResponse = try await apiService.getCatalogItem(objectId: mapping.squareCatalogObjectId)
            guard let squareObject = squareResponse.object else { continue }
            
            let conflict = SyncConflict(
                proTechItem: proTechItem,
                squareObject: squareObject,
                conflictingFields: detectConflictingFields(proTechItem: proTechItem, squareObject: squareObject),
                proTechLastModified: proTechItem.lastModified ?? Date.distantPast,
                squareLastModified: ISO8601DateFormatter().date(from: squareObject.updatedAt) ?? Date.distantPast
            )
            
            conflicts.append(conflict)
        }
        
        return conflicts
    }
    
    func resolveConflict(_ conflict: SyncConflict, strategy: ConflictResolutionStrategy) async throws {
        guard let config = getConfiguration(),
              let mapping = getMapping(for: conflict.proTechItem) else {
            throw SyncError.mappingNotFound
        }
        
        switch strategy {
        case .squareWins:
            try await updateProTechItem(item: conflict.proTechItem, mapping: mapping)
        case .proTechWins:
            try await updateSquareItem(item: conflict.proTechItem, mapping: mapping, locationId: config.locationId)
        case .mostRecent:
            if conflict.squareLastModified > conflict.proTechLastModified {
                try await updateProTechItem(item: conflict.proTechItem, mapping: mapping)
            } else {
                try await updateSquareItem(item: conflict.proTechItem, mapping: mapping, locationId: config.locationId)
            }
        case .manual:
            // Manual resolution handled by UI
            return
        }
        
        // Update mapping status
        mapping.syncStatus = .synced
        mapping.lastSyncedAt = Date()
        try modelContext.save()
        
        // Log conflict resolution
        let log = SyncLog(
            operation: .conflictResolved,
            itemId: conflict.proTechItem.id,
            squareObjectId: mapping.squareCatalogObjectId,
            status: .synced,
            changedFields: conflict.conflictingFields,
            details: "Resolved using strategy: \(strategy.displayName)"
        )
        modelContext.insert(log)
        try modelContext.save()
    }
    
    // MARK: - Scheduling
    
    func startAutoSync(interval: TimeInterval) {
        stopAutoSync()
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                do {
                    let lastSync = self.lastSyncDate ?? .distantPast
                    try await self.syncChangedItems(since: lastSync)
                } catch {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func stopAutoSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Webhooks
    
    func processWebhookEvent(_ event: WebhookEvent) async throws {
        let startTime = Date()
        
        // Handle different event types
        if event.type.contains("inventory") {
            // Inventory change event
            if let objectId = event.data.object?.id,
               let mapping = getMapping(forSquareObjectId: objectId) {
                let itemDescriptor = FetchDescriptor<InventoryItem>(
                    predicate: #Predicate { $0.id == mapping.proTechItemId }
                )
                if let item = try modelContext.fetch(itemDescriptor).first {
                    try await updateProTechItem(item: item, mapping: mapping)
                }
            }
        } else if event.type.contains("catalog") {
            // Catalog change event
            if let object = event.data.object {
                if let mapping = getMapping(forSquareObjectId: object.id) {
                    // Update existing item
                    let itemDescriptor = FetchDescriptor<InventoryItem>(
                        predicate: #Predicate { $0.id == mapping.proTechItemId }
                    )
                    if let item = try modelContext.fetch(itemDescriptor).first {
                        try await updateProTechItem(item: item, mapping: mapping)
                    }
                }
            }
        }
        
        // Log webhook event
        let log = SyncLog(
            operation: .webhookReceived,
            squareObjectId: event.data.id,
            status: .synced,
            changedFields: [],
            syncDuration: Date().timeIntervalSince(startTime),
            details: "Event type: \(event.type)"
        )
        modelContext.insert(log)
        try modelContext.save()
    }
    
    // MARK: - Utilities
    
    func validateSyncReadiness() throws {
        guard getConfiguration() != nil else {
            throw SyncError.notConfigured
        }
    }
    
    func getSyncStatistics() -> SyncStatistics {
        let mappingDescriptor = FetchDescriptor<SquareSyncMapping>()
        let allMappings = (try? modelContext.fetch(mappingDescriptor)) ?? []
        
        let syncedItems = allMappings.filter { $0.syncStatus == .synced }.count
        let pendingItems = allMappings.filter { $0.syncStatus == .pending }.count
        let failedItems = allMappings.filter { $0.syncStatus == .failed }.count
        
        let logDescriptor = FetchDescriptor<SyncLog>()
        let logs = (try? modelContext.fetch(logDescriptor)) ?? []
        
        let averageSyncTime = logs.isEmpty ? nil : logs.map { $0.syncDuration }.reduce(0, +) / Double(logs.count)
        let lastLog = logs.sorted(by: { $0.timestamp > $1.timestamp }).first
        
        return SyncStatistics(
            totalItems: allMappings.count,
            syncedItems: syncedItems,
            pendingItems: pendingItems,
            failedItems: failedItems,
            lastSyncDuration: lastLog?.syncDuration,
            averageSyncTime: averageSyncTime
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func importSquareItem(object: CatalogObject, itemData: CatalogItem, locationId: String) async throws {
        // Check if item already exists by SKU
        if let variation = itemData.variations?.first,
           let sku = variation.itemVariationData.sku {
            let descriptor = FetchDescriptor<InventoryItem>(
                predicate: #Predicate { $0.sku == sku }
            )
            if let existingItem = try modelContext.fetch(descriptor).first {
                // Create mapping for existing item
                _ = try createMapping(
                    proTechItem: existingItem,
                    squareObjectId: object.id,
                    squareVariationId: variation.id
                )
                return
            }
        }
        
        // Create new inventory item
        let newItem = InventoryItem(
            name: itemData.name,
            sku: itemData.variations?.first?.itemVariationData.sku ?? "",
            category: itemData.categoryId ?? "",
            quantity: 0,
            reorderPoint: itemData.variations?.first?.itemVariationData.inventoryAlertThreshold ?? 0,
            cost: 0,
            price: Double(itemData.variations?.first?.itemVariationData.priceMoney?.amount ?? 0) / 100.0,
            supplier: nil,
            location: "",
            notes: itemData.description
        )
        
        modelContext.insert(newItem)
        try modelContext.save()
        
        // Create mapping
        _ = try createMapping(
            proTechItem: newItem,
            squareObjectId: object.id,
            squareVariationId: itemData.variations?.first?.id
        )
        
        // Sync inventory count
        if let variationId = itemData.variations?.first?.id {
            if let count = try await apiService.getInventoryCount(catalogObjectId: variationId, locationId: locationId) {
                newItem.quantity = count.quantityInt
                try modelContext.save()
            }
        }
    }
    
    private func exportItemToSquare(item: InventoryItem, locationId: String) async throws {
        // Create catalog object
        let variation = CatalogItemVariation(
            id: "#\(item.id.uuidString)",
            type: "ITEM_VARIATION",
            updatedAt: nil,
            version: nil,
            itemVariationData: ItemVariationData(
                itemId: nil,
                name: "Regular",
                sku: item.sku,
                upc: nil,
                ordinal: 0,
                pricingType: "FIXED_PRICING",
                priceMoney: Money(dollars: item.price),
                locationOverrides: nil,
                trackInventory: true,
                inventoryAlertType: "LOW_QUANTITY",
                inventoryAlertThreshold: item.reorderPoint,
                userData: nil,
                serviceDuration: nil,
                availableForBooking: nil,
                itemOptionValues: nil,
                measurementUnitId: nil,
                sellable: true,
                stockable: true
            )
        )
        
        let catalogItem = CatalogItem(
            name: item.name,
            description: item.notes,
            abbreviation: nil,
            labelColor: nil,
            availableOnline: true,
            availableForPickup: true,
            availableElectronically: nil,
            categoryId: nil,
            taxIds: nil,
            modifierListInfo: nil,
            variations: [variation],
            productType: "REGULAR",
            skipModifierScreen: nil,
            itemOptions: nil
        )
        
        let catalogObject = CatalogObject(
            id: "#\(item.id.uuidString)",
            type: .item,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            version: 1,
            isDeleted: false,
            catalogV1Ids: nil,
            itemData: catalogItem
        )
        
        let request = CatalogItemRequest(
            idempotencyKey: UUID().uuidString,
            object: catalogObject
        )
        
        let response = try await apiService.createCatalogItem(request)
        
        guard let createdObject = response.object,
              let createdVariation = createdObject.itemData?.variations?.first else {
            throw SyncError.invalidResponse
        }
        
        // Create mapping
        _ = try createMapping(
            proTechItem: item,
            squareObjectId: createdObject.id,
            squareVariationId: createdVariation.id
        )
        
        // Sync inventory count
        if let variationId = createdVariation.id {
            _ = try await apiService.setInventoryCount(
                catalogObjectId: variationId,
                locationId: locationId,
                quantity: item.quantity
            )
        }
    }
    
    private func updateSquareItem(item: InventoryItem, mapping: SquareSyncMapping, locationId: String) async throws {
        // Fetch current Square item
        let response = try await apiService.getCatalogItem(objectId: mapping.squareCatalogObjectId)
        guard var catalogObject = response.object else {
            throw SyncError.invalidResponse
        }
        
        // Update item data
        catalogObject.itemData?.name = item.name
        catalogObject.itemData?.description = item.notes
        catalogObject.itemData?.variations?.first?.itemVariationData.sku = item.sku
        catalogObject.itemData?.variations?.first?.itemVariationData.priceMoney = Money(dollars: item.price)
        catalogObject.itemData?.variations?.first?.itemVariationData.inventoryAlertThreshold = item.reorderPoint
        
        let request = CatalogItemRequest(
            idempotencyKey: UUID().uuidString,
            object: catalogObject
        )
        
        _ = try await apiService.updateCatalogItem(objectId: mapping.squareCatalogObjectId, itemRequest: request)
        
        // Update inventory count
        if let variationId = mapping.squareVariationId {
            _ = try await apiService.setInventoryCount(
                catalogObjectId: variationId,
                locationId: locationId,
                quantity: item.quantity
            )
        }
        
        mapping.lastSyncedAt = Date()
        mapping.syncStatus = .synced
        try modelContext.save()
    }
    
    private func updateProTechItem(item: InventoryItem, mapping: SquareSyncMapping) async throws {
        let response = try await apiService.getCatalogItem(objectId: mapping.squareCatalogObjectId)
        guard let catalogObject = response.object,
              let itemData = catalogObject.itemData,
              let variation = itemData.variations?.first else {
            throw SyncError.invalidResponse
        }
        
        item.name = itemData.name
        item.notes = itemData.description
        item.sku = variation.itemVariationData.sku ?? item.sku
        item.price = Double(variation.itemVariationData.priceMoney?.amount ?? 0) / 100.0
        item.reorderPoint = variation.itemVariationData.inventoryAlertThreshold ?? item.reorderPoint
        
        // Update inventory count
        if let variationId = variation.id,
           let config = getConfiguration() {
            if let count = try await apiService.getInventoryCount(catalogObjectId: variationId, locationId: config.locationId) {
                item.quantity = count.quantityInt
            }
        }
        
        mapping.lastSyncedAt = Date()
        mapping.syncStatus = .synced
        try modelContext.save()
    }
    
    private func bidirectionalSync(item: InventoryItem, mapping: SquareSyncMapping, locationId: String) async throws {
        // Fetch Square item
        let response = try await apiService.getCatalogItem(objectId: mapping.squareCatalogObjectId)
        guard let squareObject = response.object else {
            throw SyncError.invalidResponse
        }
        
        let squareLastModified = ISO8601DateFormatter().date(from: squareObject.updatedAt) ?? .distantPast
        let proTechLastModified = item.lastModified ?? .distantPast
        
        if squareLastModified > mapping.lastSyncedAt && proTechLastModified > mapping.lastSyncedAt {
            // Both modified since last sync - conflict
            mapping.syncStatus = .conflict
            try modelContext.save()
            throw SyncError.conflict
        } else if squareLastModified > mapping.lastSyncedAt {
            // Square is newer
            try await updateProTechItem(item: item, mapping: mapping)
        } else if proTechLastModified > mapping.lastSyncedAt {
            // ProTech is newer
            try await updateSquareItem(item: item, mapping: mapping, locationId: locationId)
        }
    }
    
    private func detectConflictingFields(proTechItem: InventoryItem, squareObject: CatalogObject) -> [String] {
        var conflicts: [String] = []
        
        guard let itemData = squareObject.itemData,
              let variation = itemData.variations?.first else {
            return conflicts
        }
        
        if proTechItem.name != itemData.name {
            conflicts.append("name")
        }
        
        if proTechItem.sku != (variation.itemVariationData.sku ?? "") {
            conflicts.append("sku")
        }
        
        let squarePrice = Double(variation.itemVariationData.priceMoney?.amount ?? 0) / 100.0
        if abs(proTechItem.price - squarePrice) > 0.01 {
            conflicts.append("price")
        }
        
        return conflicts
    }
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastSquareSync") as? Date
    }
    
    private func saveLastSyncDate() {
        if let date = lastSyncDate {
            UserDefaults.standard.set(date, forKey: "lastSquareSync")
        }
    }
}

// MARK: - Supporting Types

enum SyncManagerStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case completed
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .syncing: return "Syncing..."
        case .error: return "Error"
        case .completed: return "Completed"
        }
    }
}

struct SyncConflict {
    let proTechItem: InventoryItem
    let squareObject: CatalogObject
    let conflictingFields: [String]
    let proTechLastModified: Date
    let squareLastModified: Date
}

struct SyncStatistics {
    let totalItems: Int
    let syncedItems: Int
    let pendingItems: Int
    let failedItems: Int
    let lastSyncDuration: TimeInterval?
    let averageSyncTime: TimeInterval?
    
    var syncPercentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(syncedItems) / Double(totalItems) * 100
    }
}

enum SyncError: Error, LocalizedError {
    case notConfigured
    case mappingNotFound
    case invalidResponse
    case conflict
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Square sync is not configured"
        case .mappingNotFound:
            return "Item mapping not found"
        case .invalidResponse:
            return "Invalid response from Square"
        case .conflict:
            return "Sync conflict detected"
        }
    }
}
