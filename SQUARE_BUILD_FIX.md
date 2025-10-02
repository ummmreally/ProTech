# Square Integration - Immediate Build Fix

## Problem

The Square Inventory Sync code was written for **SwiftData**, but ProTech uses **Core Data**. This causes ~40+ build errors.

## Immediate Solution: Exclude Problem Files

Temporarily exclude these files from the build target:

### In Xcode:

1. Select each file in Project Navigator
2. Open File Inspector (⌥⌘1)
3. Uncheck "ProTech" under **Target Membership**

### Files to Exclude:

**Exclude these (depend on InventoryItem with SwiftData)**:
- ✅ `Services/SquareInventorySyncManager.swift`
- ✅ `Views/Inventory/SquareSyncDashboardView.swift`
- ✅ `Views/Settings/SquareInventorySyncSettingsView.swift`

**Keep these (standalone, will work)**:
- ✅ `Services/SquareAPIService.swift` - API client (no dependencies)
- ✅ `Services/SquareWebhookHandler.swift` - Webhook handler
- ✅ `Services/SquareSyncScheduler.swift` - Scheduler
- ✅ `Models/SquareAPIModels.swift` - API data models
- ✅ `Models/SquareSyncMapping.swift` - Will need Core Data migration
- ✅ `Models/SyncLog.swift` - Will need Core Data migration
- ✅ `Models/SquareConfiguration.swift` - Will need Core Data migration

### After Excluding Files:

Your project should build successfully! ✅

## What Works Now

- Square API service (can make API calls)
- Square API models (data structures)
- Webhook infrastructure
- Documentation (all guides remain valid)

## What Doesn't Work Yet

- Actual inventory synchronization
- Sync dashboard UI
- Sync settings UI
- Automatic syncing

## Next Steps (Choose One)

### Option A: Full Core Data Migration (Recommended for Production)
Follow `SQUARE_COREDATA_MIGRATION_GUIDE.md` to properly integrate with Core Data.

**Time**: 6-9 hours  
**Result**: Full-featured Square inventory sync

### Option B: Simplified Integration
Create a simpler sync service that extends existing `InventoryService`.

**Time**: 3-4 hours  
**Result**: Basic Square sync functionality

### Option C: Use Later
Keep files excluded, implement Square sync in a future update.

**Time**: Now (0 hours)  
**Result**: Project builds, Square sync postponed

## Quick Steps to Build Now

1. Open ProTech.xcodeproj in Xcode
2. Select `SquareInventorySyncManager.swift`
3. File Inspector → Uncheck "ProTech" target
4. Repeat for `SquareSyncDashboardView.swift`
5. Repeat for `SquareInventorySyncSettingsView.swift`
6. Build (⌘B) - Should succeed!

---

*Fix Applied: 2025-10-02*
