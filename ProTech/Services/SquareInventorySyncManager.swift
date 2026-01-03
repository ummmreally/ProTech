//
//  SquareInventorySyncManager.swift
//  ProTech
//
//  Orchestrates synchronization between ProTech and Square inventory
//

import Foundation
import CoreData
import Combine

@MainActor
class SquareInventorySyncManager: ObservableObject {
    // Shared singleton instance for better performance
    static let shared = SquareInventorySyncManager()
    
    @Published var syncStatus: SyncManagerStatus = .idle
    @Published var syncProgress: Double = 0.0
    @Published var lastSyncDate: Date?
    @Published var errorMessage: String?
    @Published var currentOperation: String?
    
    private let apiService: SquareAPIService
    private let context: NSManagedObjectContext
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Cache for locations to avoid repeated API calls
    private var cachedLocations: [SquareLocation]?
    private var locationsCacheTime: Date?
    private let locationsCacheDuration: TimeInterval = 300 // 5 minutes
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext, apiService: SquareAPIService = .shared) {
        self.context = context
        self.apiService = apiService
        loadLastSyncDate()
        bootstrapConfiguration()
    }
    
    // MARK: - Configuration
    
    func getConfiguration() -> SquareConfiguration? {
        let fetchRequest: NSFetchRequest<SquareConfiguration> = SquareConfiguration.fetchRequest()
        return try? context.fetch(fetchRequest).first
    }
    
    func saveConfiguration(_ config: SquareConfiguration) throws {
        context.insert(config)
        try context.save()
        apiService.setConfiguration(config)
    }
    
    // MARK: - Initial Setup
    
    func performInitialSetup(accessToken: String, merchantId: String, locationId: String, environment: SquareEnvironment) async throws {
        syncStatus = .syncing
        currentOperation = "Setting up Square integration..."
        
        let config = SquareConfiguration(context: context)
        config.id = UUID()
        config.accessToken = accessToken
        config.merchantId = merchantId
        config.locationId = locationId
        config.environment = environment
        config.createdAt = Date()
        config.updatedAt = Date()
        
        try saveConfiguration(config)
        
        syncStatus = .completed
        currentOperation = nil
    }
    
    func importAllFromSquare() async throws {
        guard let config = getConfiguration(), let locationId = config.locationId else {
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
                        try await importSquareItem(object: object, itemData: itemData, locationId: locationId)
                        importedCount += 1
                    }
                }
            }
            
            cursor = response.cursor
            hasMore = cursor != nil
            
            syncProgress = min(0.9, Double(importedCount) / 100.0) // Estimate progress
        }
        
        // Log the import
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .batchImport
        log.status = .completed
        log.changedFields = []
        log.syncDuration = Date().timeIntervalSince(startTime)
        log.details = "Imported \(importedCount) items from Square"
        try context.save()
        
        lastSyncDate = Date()
        syncProgress = 1.0
        syncStatus = .completed
        currentOperation = nil
    }
    
    func exportAllToSquare() async throws {
        guard let config = getConfiguration(), let locationId = config.locationId else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Exporting items to Square..."
        syncProgress = 0.0
        
        let startTime = Date()
        
        // Fetch all inventory items
        let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        let items = try context.fetch(fetchRequest)
        
        var exportedCount = 0
        let totalItems = items.count
        
        for item in items {
            // Check if already mapped
            if getMapping(for: item) == nil {
                try await exportItemToSquare(item: item, locationId: locationId)
                exportedCount += 1
            }
            
            syncProgress = Double(exportedCount) / Double(totalItems)
        }
        
        // Log the export
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .batchExport
        log.status = .completed
        log.changedFields = []
        log.syncDuration = Date().timeIntervalSince(startTime)
        log.details = "Exported \(exportedCount) items to Square"
        try context.save()
        
        lastSyncDate = Date()
        syncProgress = 1.0
        syncStatus = .completed
        currentOperation = nil
    }
    
    // MARK: - Sync Operations
    
    func syncItem(_ item: InventoryItem, direction: SyncDirection) async throws {
        guard let config = getConfiguration(), let locationId = config.locationId else {
            throw SyncError.notConfigured
        }
        
        let startTime = Date()
        
        if let mapping = getMapping(for: item) {
            // Item is already mapped, sync based on direction
            switch direction {
            case .toSquare:
                try await updateSquareItem(item: item, mapping: mapping, locationId: locationId)
            case .fromSquare:
                try await updateProTechItem(item: item, mapping: mapping)
            case .bidirectional:
                try await bidirectionalSync(item: item, mapping: mapping, locationId: locationId)
            }
        } else {
            // No mapping exists, create new item
            if direction == .toSquare || direction == .bidirectional {
                try await exportItemToSquare(item: item, locationId: locationId)
            }
        }
        
        // Log the sync
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .update
        log.itemId = item.id
        log.status = .completed
        log.changedFields = []
        log.syncDuration = Date().timeIntervalSince(startTime)
        try context.save()
    }
    
    func syncAllItems() async throws {
        guard let config = getConfiguration() else {
            throw SyncError.notConfigured
        }
        
        syncStatus = .syncing
        currentOperation = "Syncing all items..."
        syncProgress = 0.0
        
        let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        let items = try context.fetch(fetchRequest)
        
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
        let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "updatedAt > %@", date as NSDate)
        let changedItems = try context.fetch(fetchRequest)
        
        for item in changedItems {
            try await syncItem(item, direction: config.defaultSyncDirection)
        }
        
        lastSyncDate = Date()
        syncStatus = .completed
        currentOperation = nil
    }
    
    // MARK: - Mapping Management
    
    func createMapping(proTechItem: InventoryItem, squareObjectId: String, squareVariationId: String? = nil) throws -> SquareSyncMapping {
        guard let itemId = proTechItem.id else {
            throw SyncError.invalidData("Item missing ID")
        }
        
        let mapping = SquareSyncMapping(context: context)
        mapping.id = UUID()
        mapping.proTechItemId = itemId
        mapping.squareCatalogObjectId = squareObjectId
        mapping.squareVariationId = squareVariationId
        mapping.lastSyncedAt = Date()
        mapping.syncStatus = .synced
        mapping.version = 1
        mapping.createdAt = Date()
        mapping.updatedAt = Date()
        
        try context.save()
        
        // Log mapping creation
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .mappingCreated
        log.itemId = itemId
        log.squareObjectId = squareObjectId
        log.status = .completed
        log.changedFields = []
        try context.save()
        
        return mapping
    }
    
    func getMapping(for item: InventoryItem) -> SquareSyncMapping? {
        guard let itemId = item.id else { return nil }
        let fetchRequest: NSFetchRequest<SquareSyncMapping> = SquareSyncMapping.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "proTechItemId == %@", itemId as CVarArg)
        return try? context.fetch(fetchRequest).first
    }
    
    func getMapping(forSquareObjectId objectId: String) -> SquareSyncMapping? {
        let fetchRequest: NSFetchRequest<SquareSyncMapping> = SquareSyncMapping.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "squareCatalogObjectId == %@", objectId)
        return try? context.fetch(fetchRequest).first
    }
    
    func removeMapping(_ mapping: SquareSyncMapping) throws {
        context.delete(mapping)
        try context.save()
        
        // Log mapping deletion
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .mappingDeleted
        log.itemId = mapping.proTechItemId
        log.squareObjectId = mapping.squareCatalogObjectId
        log.status = .completed
        log.changedFields = []
        try context.save()
    }
    
    // MARK: - Conflict Resolution
    
    func detectConflicts() async throws -> [SyncConflict] {
        var conflicts: [SyncConflict] = []
        
        let fetchRequest: NSFetchRequest<SquareSyncMapping> = SquareSyncMapping.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "syncStatusRaw == %@", "conflict")
        let conflictMappings = try context.fetch(fetchRequest)
        
        for mapping in conflictMappings {
            // Fetch ProTech item
            guard let proTechItemId = mapping.proTechItemId else { continue }
            let itemFetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
            itemFetchRequest.predicate = NSPredicate(format: "id == %@", proTechItemId as CVarArg)
            guard let proTechItem = try context.fetch(itemFetchRequest).first else { continue }
            
            // Fetch Square item
            guard let squareObjectId = mapping.squareCatalogObjectId else { continue }
            let squareResponse = try await apiService.getCatalogItem(objectId: squareObjectId)
            guard let squareObject = squareResponse.object else { continue }
            
            let conflict = SyncConflict(
                proTechItem: proTechItem,
                squareObject: squareObject,
                conflictingFields: detectConflictingFields(proTechItem: proTechItem, squareObject: squareObject),
                proTechLastModified: proTechItem.updatedAt ?? Date.distantPast,
                squareLastModified: ISO8601DateFormatter().date(from: squareObject.updatedAt) ?? Date.distantPast
            )
            
            conflicts.append(conflict)
        }
        
        return conflicts
    }
    
    func resolveConflict(_ conflict: SyncConflict, strategy: ConflictResolutionStrategy) async throws {
        guard let config = getConfiguration(),
              let locationId = config.locationId,
              let mapping = getMapping(for: conflict.proTechItem) else {
            throw SyncError.mappingNotFound
        }
        
        switch strategy {
        case .squareWins:
            try await updateProTechItem(item: conflict.proTechItem, mapping: mapping)
        case .proTechWins:
            try await updateSquareItem(item: conflict.proTechItem, mapping: mapping, locationId: locationId)
        case .mostRecent:
            if conflict.squareLastModified > conflict.proTechLastModified {
                try await updateProTechItem(item: conflict.proTechItem, mapping: mapping)
            } else {
                try await updateSquareItem(item: conflict.proTechItem, mapping: mapping, locationId: locationId)
            }
        case .manual:
            // Manual resolution handled by UI
            return
        }
        
        // Update mapping status
        mapping.syncStatus = .synced
        mapping.lastSyncedAt = Date()
        try context.save()
        
        // Log conflict resolution
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .conflictResolved
        log.itemId = conflict.proTechItem.id
        log.squareObjectId = mapping.squareCatalogObjectId
        log.status = .completed
        log.changedFields = conflict.conflictingFields
        log.details = "Resolved using strategy: \(strategy.displayName)"
        try context.save()
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
               let mapping = getMapping(forSquareObjectId: objectId),
               let proTechItemId = mapping.proTechItemId {
                let itemFetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
                itemFetchRequest.predicate = NSPredicate(format: "id == %@", proTechItemId as CVarArg)
                if let item = try? context.fetch(itemFetchRequest).first {
                    try await updateProTechItem(item: item, mapping: mapping)
                }
            }
        } else if event.type.contains("catalog") {
            // Catalog change event
            if let object = event.data.object {
                if let mapping = getMapping(forSquareObjectId: object.id),
                   let proTechItemId = mapping.proTechItemId {
                    // Update existing item
                    let itemFetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
                    itemFetchRequest.predicate = NSPredicate(format: "id == %@", proTechItemId as CVarArg)
                    if let item = try? context.fetch(itemFetchRequest).first {
                        try await updateProTechItem(item: item, mapping: mapping)
                    }
                }
            }
        }
        
        // Log webhook event
        let log = SyncLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.operation = .webhookReceived
        log.squareObjectId = event.data.id
        log.status = .completed
        log.changedFields = []
        log.syncDuration = Date().timeIntervalSince(startTime)
        log.details = "Event type: \(event.type)"
        try context.save()
    }
    
    // MARK: - Utilities
    
    func validateSyncReadiness() throws {
        guard getConfiguration() != nil else {
            throw SyncError.notConfigured
        }
    }
    
    func getSyncStatistics() -> SyncStatistics {
        let mappingFetchRequest: NSFetchRequest<SquareSyncMapping> = SquareSyncMapping.fetchRequest()
        let allMappings = (try? context.fetch(mappingFetchRequest)) ?? []
        
        let syncedItems = allMappings.filter { $0.syncStatus == .synced }.count
        let pendingItems = allMappings.filter { $0.syncStatus == .pending }.count
        let failedItems = allMappings.filter { $0.syncStatus == .failed }.count
        
        let logFetchRequest: NSFetchRequest<SyncLog> = SyncLog.fetchRequest()
        let logs = (try? context.fetch(logFetchRequest)) ?? []
        
        let averageSyncTime = logs.isEmpty ? nil : logs.map { $0.syncDuration }.reduce(0, +) / Double(logs.count)
        let lastLog = logs.sorted(by: { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }).first
        
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
            let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "sku == %@", sku)
            if let existingItem = try? context.fetch(fetchRequest).first {
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
        let newItem = InventoryItem(context: context)
        newItem.id = UUID()
        newItem.name = itemData.name
        newItem.sku = itemData.variations?.first?.itemVariationData.sku ?? ""
        newItem.category = itemData.categoryId ?? ""
        newItem.categoryName = itemData.categoryId ?? ""
        newItem.quantity = 0
        newItem.minQuantity = Int32(itemData.variations?.first?.itemVariationData.inventoryAlertThreshold ?? 5)
        newItem.cost = NSDecimalNumber(value: 0)
        newItem.price = NSDecimalNumber(value: Double(itemData.variations?.first?.itemVariationData.priceMoney?.amount ?? 0) / 100.0)
        newItem.createdAt = Date()
        newItem.updatedAt = Date()
        
        try context.save()
        
        // Create mapping
        _ = try createMapping(
            proTechItem: newItem,
            squareObjectId: object.id,
            squareVariationId: itemData.variations?.first?.id
        )
        
        // Sync inventory count
        if let variationId = itemData.variations?.first?.id {
            if let count = try await apiService.getInventoryCount(catalogObjectId: variationId, locationId: locationId) {
                newItem.quantity = Int32(count.quantityInt)
                try context.save()
            }
        }
    }
    
    private func exportItemToSquare(item: InventoryItem, locationId: String) async throws {
        guard item.id != nil else {
            throw SyncError.invalidData("Item missing ID")
        }
        
        // Generate unique temporary IDs for this API call (Square requires unique temp IDs per request)
        let tempItemId = "#\(UUID().uuidString)"
        let tempVariationId = "#\(UUID().uuidString)"
        
        // Create catalog object
        let variation = CatalogItemVariation(
            id: tempVariationId,
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
                priceMoney: Money(dollars: item.priceDouble),
                locationOverrides: nil,
                trackInventory: true,
                inventoryAlertType: "LOW_QUANTITY",
                inventoryAlertThreshold: 5, // Default threshold since reorderPoint not in schema
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
            name: item.name ?? "Unnamed Item",
            description: nil, // notes attribute doesn't exist in schema
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
            id: tempItemId,
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
                quantity: Int(item.quantity)
            )
        }
    }
    
    private func updateSquareItem(item: InventoryItem, mapping: SquareSyncMapping, locationId: String) async throws {
        guard let squareObjectId = mapping.squareCatalogObjectId else {
            throw SyncError.invalidData("Missing Square object ID")
        }
        
        // Fetch current Square item
        let response = try await apiService.getCatalogItem(objectId: squareObjectId)
        guard var catalogObject = response.object else {
            throw SyncError.invalidResponse
        }
        
        // Update item data (catalogObject properties are immutable, need to recreate)
        if let existingItemData = catalogObject.itemData {
            let updatedItem = CatalogItem(
                name: item.name ?? existingItemData.name,
                description: nil, // notes attribute doesn't exist in schema
                abbreviation: existingItemData.abbreviation,
                labelColor: existingItemData.labelColor,
                availableOnline: existingItemData.availableOnline,
                availableForPickup: existingItemData.availableForPickup,
                availableElectronically: existingItemData.availableElectronically,
                categoryId: existingItemData.categoryId,
                taxIds: existingItemData.taxIds,
                modifierListInfo: existingItemData.modifierListInfo,
                variations: existingItemData.variations?.map { variation in
                    CatalogItemVariation(
                        id: variation.id,
                        type: variation.type,
                        updatedAt: variation.updatedAt,
                        version: variation.version,
                        itemVariationData: ItemVariationData(
                            itemId: variation.itemVariationData.itemId,
                            name: variation.itemVariationData.name,
                            sku: item.sku,
                            upc: variation.itemVariationData.upc,
                            ordinal: variation.itemVariationData.ordinal,
                            pricingType: variation.itemVariationData.pricingType,
                            priceMoney: Money(dollars: item.priceDouble),
                            locationOverrides: variation.itemVariationData.locationOverrides,
                            trackInventory: variation.itemVariationData.trackInventory,
                            inventoryAlertType: variation.itemVariationData.inventoryAlertType,
                            inventoryAlertThreshold: 5, // Default threshold since reorderPoint not in schema
                            userData: variation.itemVariationData.userData,
                            serviceDuration: variation.itemVariationData.serviceDuration,
                            availableForBooking: variation.itemVariationData.availableForBooking,
                            itemOptionValues: variation.itemVariationData.itemOptionValues,
                            measurementUnitId: variation.itemVariationData.measurementUnitId,
                            sellable: variation.itemVariationData.sellable,
                            stockable: variation.itemVariationData.stockable
                        )
                    )
                } ?? [],
                productType: existingItemData.productType,
                skipModifierScreen: existingItemData.skipModifierScreen,
                itemOptions: existingItemData.itemOptions
            )
            
            catalogObject = CatalogObject(
                id: catalogObject.id,
                type: catalogObject.type,
                updatedAt: ISO8601DateFormatter().string(from: Date()),
                version: catalogObject.version,
                isDeleted: catalogObject.isDeleted,
                catalogV1Ids: catalogObject.catalogV1Ids,
                itemData: updatedItem
            )
        }
        
        let request = CatalogItemRequest(
            idempotencyKey: UUID().uuidString,
            object: catalogObject
        )
        
        _ = try await apiService.updateCatalogItem(objectId: squareObjectId, itemRequest: request)
        
        // Update inventory count
        if let variationId = mapping.squareVariationId {
            _ = try await apiService.setInventoryCount(
                catalogObjectId: variationId,
                locationId: locationId,
                quantity: Int(item.quantity)
            )
        }
        
        mapping.lastSyncedAt = Date()
        mapping.syncStatus = .synced
        try context.save()
    }
    
    private func updateProTechItem(item: InventoryItem, mapping: SquareSyncMapping) async throws {
        guard let squareObjectId = mapping.squareCatalogObjectId else {
            throw SyncError.invalidData("Missing Square object ID")
        }
        
        let response = try await apiService.getCatalogItem(objectId: squareObjectId)
        guard let catalogObject = response.object,
              let itemData = catalogObject.itemData,
              let variation = itemData.variations?.first else {
            throw SyncError.invalidResponse
        }
        
        item.name = itemData.name
        item.sku = variation.itemVariationData.sku ?? item.sku
        item.price = NSDecimalNumber(value: Double(variation.itemVariationData.priceMoney?.amount ?? 0) / 100.0)
        // Note: description and reorderPoint not in Core Data schema
        
        // Update inventory count
        if let variationId = variation.id,
           let config = getConfiguration(),
           let locationId = config.locationId {
            if let count = try await apiService.getInventoryCount(catalogObjectId: variationId, locationId: locationId) {
                item.quantity = Int32(count.quantityInt)
            }
        }
        
        mapping.lastSyncedAt = Date()
        mapping.syncStatus = .synced
        try context.save()
    }
    
    private func bidirectionalSync(item: InventoryItem, mapping: SquareSyncMapping, locationId: String) async throws {
        guard let squareObjectId = mapping.squareCatalogObjectId else {
            throw SyncError.invalidData("Missing Square object ID")
        }
        
        // Fetch Square item
        let response = try await apiService.getCatalogItem(objectId: squareObjectId)
        guard let squareObject = response.object else {
            throw SyncError.invalidResponse
        }
        
        let squareLastModified = ISO8601DateFormatter().date(from: squareObject.updatedAt) ?? .distantPast
        let proTechLastModified = item.updatedAt ?? .distantPast
        
        guard let mappingLastSynced = mapping.lastSyncedAt else {
            // No last sync date, treat as new
            try await updateProTechItem(item: item, mapping: mapping)
            return
        }
        
        if squareLastModified > mappingLastSynced && proTechLastModified > mappingLastSynced {
            // Both modified since last sync - conflict
            mapping.syncStatus = .conflict
            try context.save()
            throw SyncError.conflict(details: "Both Square and ProTech modified since last sync")
        } else if squareLastModified > mappingLastSynced {
            // Square is newer
            try await updateProTechItem(item: item, mapping: mapping)
        } else if proTechLastModified > mappingLastSynced {
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
        if abs(proTechItem.priceDouble - squarePrice) > 0.01 {
            conflicts.append("price")
        }
        
        return conflicts
    }
    
    private func loadLocations() async {
        AppLogger.debug("📥 loadLocations() started", category: .inventory)
    }
    
    private func bootstrapConfiguration() {
        if let config = getConfiguration() {
            apiService.setConfiguration(config)
            AppLogger.info("✅ SquareInventorySyncManager initialized with saved configuration", category: .inventory)
            return
        }
        
        guard SquareConfig.isConfigured else {
            AppLogger.warning("⚠️ SquareInventorySyncManager initialized WITHOUT configuration - credentials missing", category: .inventory)
            return
        }
        
        do {
            let config = SquareConfiguration(context: context)
            config.id = UUID()
            config.accessToken = SquareConfig.accessToken
            config.merchantId = SquareConfig.applicationId // Placeholder until actual merchant fetched
            config.locationId = SquareConfig.locationId
            config.environment = SquareConfig.environment
            config.syncEnabled = true
            config.syncInterval = 3600
            config.createdAt = Date()
            config.updatedAt = Date()
            
            try saveConfiguration(config)
            AppLogger.info("✅ SquareInventorySyncManager seeded configuration from SupabaseConfig.swift", category: .inventory)
        } catch {
            context.rollback()
            AppLogger.error("Failed to seed Square configuration", error: error, category: .inventory)
        }
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
    
    var isError: Bool {
        if case .error = self { return true }
        return false
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

// SyncError is defined in Models/SyncErrors.swift
