# Square Inventory Sync - Core Data Migration Guide

## Current Issue

The Square Inventory Sync implementation was written for **SwiftData**, but ProTech uses **Core Data**. This requires significant modifications to make them compatible.

## Two Implementation Options

### Option 1: Convert Square Models to Core Data (Recommended)
Convert SquareSyncMapping, SyncLog, and SquareConfiguration to Core Data entities.

**Pros**:
- Consistent with existing ProTech architecture
- Single persistence layer
- Better integration with existing code

**Cons**:
- Requires Core Data entity definitions
- More initial setup

### Option 2: Hybrid Approach
Keep Square models in SwiftData, but bridge to Core Data for InventoryItem.

**Pros**:
- Modern SwiftData for new features
- Minimal changes to Square sync code

**Cons**:
- Two persistence layers
- More complex data synchronization

## Required Changes for Option 1 (Core Data)

### 1. Update SquareInventorySyncManager

Current (SwiftData):
```swift
class SquareInventorySyncManager {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
```

Change to (Core Data):
```swift
class SquareInventorySyncManager {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
    }
}
```

### 2. Update Fetch Descriptors

Current (SwiftData):
```swift
let descriptor = FetchDescriptor<InventoryItem>(
    predicate: #Predicate { $0.id == item.id }
)
let items = try modelContext.fetch(descriptor)
```

Change to (Core Data):
```swift
let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
let items = try context.fetch(fetchRequest)
```

### 3. Fix InventoryItem Property Names

The InventoryItem model uses different property names:

| Used in Square Sync | Actual Core Data Property |
|---------------------|---------------------------|
| `item.price` | `item.sellingPrice` |
| `item.lastModified` | `item.updatedAt` |
| `item.reorderPoint` (Int) | `item.reorderPoint` (Int32) |
| `item.quantity` (Int) | `item.quantity` (Int32) |

### 4. Create Core Data Entities for Square Models

#### SquareSyncMapping Entity
```swift
extension SquareSyncMapping {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SquareSyncMapping"
        entity.managedObjectClassName = NSStringFromClass(SquareSyncMapping.self)
        
        entity.properties = [
            makeAttribute("id", type: .UUIDAttributeType, optional: false),
            makeAttribute("proTechItemId", type: .UUIDAttributeType, optional: false),
            makeAttribute("squareCatalogObjectId", type: .stringAttributeType, optional: false),
            makeAttribute("squareVariationId", type: .stringAttributeType),
            makeAttribute("lastSyncedAt", type: .dateAttributeType, optional: false),
            makeAttribute("syncStatus", type: .stringAttributeType, optional: false),
            makeAttribute("syncDirection", type: .stringAttributeType, optional: false),
            makeAttribute("conflictResolution", type: .stringAttributeType, optional: false),
            makeAttribute("version", type: .integer32AttributeType, optional: false),
            makeAttribute("errorMessage", type: .stringAttributeType)
        ]
        
        return entity
    }
}
```

#### SyncLog Entity
```swift
extension SyncLog {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SyncLog"
        // ... similar structure
    }
}
```

#### SquareConfiguration Entity
```swift
extension SquareConfiguration {
    static func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "SquareConfiguration"
        // ... similar structure
    }
}
```

### 5. Update CoreDataManager

Add Square entities to the model:
```swift
model.entities = [
    // ... existing entities
    SquareSyncMapping.entityDescription(),
    SyncLog.entityDescription(),
    SquareConfiguration.entityDescription()
]
```

### 6. Fix Type Conversions

```swift
// Int32 <-> Int conversions
let quantity = Int(item.quantity) // Int32 to Int
item.quantity = Int32(newQuantity) // Int to Int32

// Optional UUID handling
guard let itemId = item.id else { return }
let uuidString = itemId.uuidString

// Price property
let price = item.sellingPrice // NOT item.price
item.sellingPrice = newPrice

// Last modified
let lastModified = item.updatedAt // NOT item.lastModified
item.updatedAt = Date()
```

## Quick Fix: Disable Square Sync Until Migration

To get the project building immediately, comment out or remove the Square sync files:

```swift
// Comment out in project:
// - SquareInventorySyncManager.swift
// - SquareSyncDashboardView.swift
// - SquareInventorySyncSettingsView.swift
```

Keep these files (they don't depend on InventoryItem):
- SquareAPIService.swift
- SquareAPIModels.swift
- SquareWebhookHandler.swift
- SquareSyncScheduler.swift

And keep the models as Core Data entities once migrated:
- SquareSyncMapping (needs Core Data version)
- SyncLog (needs Core Data version)  
- SquareConfiguration (needs Core Data version)

## Implementation Steps

1. ✅ Create Core Data entity descriptions for Square models
2. ✅ Update CoreDataManager to include Square entities
3. ✅ Rewrite SquareInventorySyncManager for Core Data
4. ✅ Fix all InventoryItem property references
5. ✅ Update UI views to use Core Data fetch requests
6. ✅ Test thoroughly with sandbox

## Estimated Time

- Core Data migration: 4-6 hours
- Testing and debugging: 2-3 hours
- **Total: 6-9 hours**

## Alternative: Use Existing InventoryService

ProTech already has an `InventoryService`. Consider extending it with Square sync methods instead of creating a separate sync manager:

```swift
extension InventoryService {
    func syncWithSquare(item: InventoryItem) async throws {
        // Sync logic here
    }
    
    func importFromSquare() async throws {
        // Import logic
    }
}
```

This would be cleaner and more consistent with the existing architecture.

---

## Decision Required

**Choose one approach:**

1. **Full Core Data Migration** - Recommended for production
2. **Disable Square Sync** - Temporary solution to get building
3. **Extend InventoryService** - Alternative architecture

---

*Last Updated: 2025-10-02*
