# Square Sync Crash Fix - Missing Core Data Attributes

## Issue
App crashes when syncing inventory from Square with:
```
-[InventoryItem setReorderPoint:]: unrecognized selector sent to instance
-[InventoryItem costPrice]: unrecognized selector sent to instance
```

## Root Cause

**Core Data schema mismatch**: Your `InventoryItem` Swift model has `reorderPoint` and `costPrice` attributes, but your SQLite database was created with an older schema that doesn't include them.

This happens when:
1. Code is updated with new attributes
2. Database file still uses old schema
3. Core Data doesn't auto-migrate for complex changes

## Solution: Reset Core Data Database

You need to delete the old database and let Core Data recreate it with the current schema.

### Option 1: Delete Database via Terminal (Safest)

```bash
# Close ProTech app first!

# Delete Core Data files
rm -rf ~/Library/Containers/Nugentic.ProTech/Data/Library/Application\ Support/ProTech/ProTech.sqlite*

# Restart ProTech app
```

### Option 2: Use Existing Script

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
./delete_core_data.sh
```

### Option 3: Programmatic Reset (Add to Code)

Add this to your app for development:

```swift
// In CoreDataManager.swift or a debug menu
func resetCoreData() {
    guard let storeURL = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url else {
        return
    }
    
    do {
        // Remove store
        try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(
            at: storeURL,
            ofType: NSSQLiteStoreType,
            options: nil
        )
        
        // Delete files
        try FileManager.default.removeItem(at: storeURL)
        try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
        try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
        
        // Reload
        loadPersistentStores()
        print("✅ Core Data reset complete")
    } catch {
        print("❌ Failed to reset Core Data: \(error)")
    }
}
```

## Why This Happens

### Core Data Schema Evolution
```
Old Schema          Current Schema       Database
-------------       ---------------      ---------
InventoryItem       InventoryItem        OLD
- name              - name               (missing)
- quantity          - quantity           (missing)
                    - reorderPoint ✅    
                    - costPrice ✅       
```

When Square sync tries to set `item.reorderPoint = ...`, Core Data throws "unrecognized selector" because the database column doesn't exist.

## After Reset

1. **Database recreated** with full schema
2. **All attributes available**: `reorderPoint`, `costPrice`, etc.
3. **Square sync works** without crashes
4. **You'll lose local data** (customers, tickets, inventory)
   - But Supabase data is safe (if you were syncing)
   - Square data can be re-imported

## Prevention for Production

For production apps, implement **proper Core Data migrations**:

```swift
// Add to Core Data model
let migration = NSMigrationManager(...)
migration.addMappingModel(...)

// Or use lightweight migration
let options = [
    NSMigratePersistentStoresAutomaticallyOption: true,
    NSInferMappingModelAutomaticallyOption: true
]
```

## Quick Fix Now

```bash
# 1. Close ProTech app
# 2. Run this command:
rm -rf ~/Library/Containers/Nugentic.ProTech/Data/Library/Application\ Support/ProTech/ProTech.sqlite*

# 3. Rebuild and run app
# 4. Try Square sync again
```

---

**Status**: Database reset required  
**Data Loss**: Local only (Supabase data preserved)  
**Time**: 1 minute to fix
