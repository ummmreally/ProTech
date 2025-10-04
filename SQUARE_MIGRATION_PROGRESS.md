# Square Core Data Migration - Progress Report

## Completed Steps ✅

### 1. ✅ Created Core Data Entity Descriptions
All three Square models have been converted from SwiftData to Core Data:

- **SquareSyncMapping.swift** - Converted to NSManagedObject
- **SyncLog.swift** - Converted to NSManagedObject  
- **SquareConfiguration.swift** - Converted to NSManagedObject

Key changes:
- Removed `@Model` and `import SwiftData`
- Added `@objc` class declarations inheriting from `NSManagedObject`
- Changed properties to `@NSManaged`
- Stored enums as raw string values with computed properties
- Added `entityDescription()` methods with full Core Data schema
- Created proper indexes

### 2. ✅ Updated CoreDataManager
Added Square entities to the Core Data model:

```swift
SquareSyncMapping.entityDescription(),
SyncLog.entityDescription(),
SquareConfiguration.entityDescription()
```

## Remaining Steps ⏳

### 3. Rewrite SquareInventorySyncManager for Core Data

**File**: `ProTech/Services/SquareInventorySyncManager.swift`

**Required Changes**:

```swift
// Change from:
private let modelContext: ModelContext
init(modelContext: ModelContext)

// To:
private let context: NSManagedObjectContext
init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext)
```

**Fetch Request Changes**:

```swift
// OLD (SwiftData):
let descriptor = FetchDescriptor<InventoryItem>(
    predicate: #Predicate { $0.id == itemId }
)
let items = try modelContext.fetch(descriptor)

// NEW (Core Data):
let fetchRequest: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
let items = try context.fetch(fetchRequest)
```

**Insert/Save Changes**:

```swift
// OLD (SwiftData):
modelContext.insert(mapping)
try modelContext.save()

// NEW (Core Data):
let mapping = SquareSyncMapping(context: context)
// Set properties...
try context.save()
```

### 4. Fix InventoryItem Property References

**Property Name Mapping**:

| Current Code | Correct Property |
|--------------|------------------|
| `item.price` | `item.sellingPrice` |
| `item.lastModified` | `item.updatedAt` |
| `item.description` | `item.itemDescription` |

**Type Conversions**:

```swift
// Int32 ↔ Int
let quantity = Int(item.quantity)  // Int32 → Int
item.quantity = Int32(newQty)      // Int → Int32

// Optional handling
guard let itemId = item.id else { return }
guard let itemName = item.name else { return }
```

### 5. Update UI Views for Core Data

**File**: `ProTech/Views/Inventory/SquareSyncDashboardView.swift`

**Changes Needed**:

```swift
// Replace @Query with @FetchRequest
@FetchRequest(
    sortDescriptors: [NSSortDescriptor(keyPath: \SyncLog.timestamp, ascending: false)],
    animation: .default
)
private var syncLogs: FetchedResults<SyncLog>
```

**File**: `ProTech/Views/Settings/SquareInventorySyncSettingsView.swift`

**Changes Needed**:

```swift
// Change init parameter
init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext)

// Update configuration loading
let fetchRequest: NSFetchRequest<SquareConfiguration> = SquareConfiguration.fetchRequest()
configuration = try? context.fetch(fetchRequest).first
```

## Quick Implementation Guide

### Step 3: SquareInventorySyncManager

**Lines to Change** (approximate):
- Line 15-25: Change init and context
- Line 120-130: Update fetch requests
- Line 200-210: Update inserts
- Line 230-240: Update queries
- Line 540-550: Fix property names (price → sellingPrice)
- Line 610-620: Fix Int32 conversions
- Line 660-670: Fix optional handling

### Step 4: Property Fixes

**Global Find & Replace**:
- `item.price` → `item.sellingPrice`
- `item.lastModified` → `item.updatedAt`
- `item.description` → `item.itemDescription`

**Manual Fixes** (type conversions):
- All `item.quantity` and `item.reorderPoint` need Int32 ↔ Int conversion
- All UUID and String optionals need unwrapping

### Step 5: UI Updates

**SquareSyncDashboardView.swift**:
1. Replace `@Query` with `@FetchRequest`
2. Change `FetchDescriptor` to `NSFetchRequest`
3. Update init to accept `NSManagedObjectContext`

**SquareInventorySyncSettingsView.swift**:
1. Change `@Environment(\.modelContext)` to pass `NSManagedObjectContext`
2. Update all model access to use Core Data patterns
3. Replace `.save()` calls with `try context.save()`

## Estimated Time Remaining

- **Step 3**: 2-3 hours (largest file, ~700 lines)
- **Step 4**: 1 hour (find & replace + manual fixes)
- **Step 5**: 1-2 hours (two view files)

**Total**: 4-6 hours

## Testing Checklist

After completing all steps:

- [ ] Project builds without errors
- [ ] Can create SquareConfiguration
- [ ] Can save sync mappings
- [ ] Can query sync logs
- [ ] UI loads without crashes
- [ ] Settings view displays correctly
- [ ] Sync dashboard shows data

## Known Issues to Watch For

1. **Optional UUID**: `item.id` is `UUID?`, must unwrap
2. **Int32 vs Int**: Core Data uses Int32 for integers
3. **Enum Storage**: Stored as String, accessed via computed properties
4. **Context Thread Safety**: Ensure all Core Data operations on correct thread
5. **@MainActor**: Views may need `@MainActor` isolation

## Next Actions

1. Wait for rate limit to clear
2. Complete Step 3 (SquareInventorySyncManager)
3. Complete Step 4 (Property fixes)
4. Complete Step 5 (UI updates)
5. Test build
6. Run and verify functionality

---

**Status**: 2 of 5 steps complete (40%)  
**Last Updated**: 2025-10-02 13:50
