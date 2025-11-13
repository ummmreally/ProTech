# Add Square Entities to Core Data Model

## Problem
The app crashes with:
```
NSFetchRequest could not locate an NSEntityDescription for entity name 'SquareConfiguration'
```

## Root Cause
The Square-related Core Data entities are defined in Swift but **not added to the `.xcdatamodeld` file**.

## Required Entities

You need to add these 3 entities to `ProTech.xcdatamodeld`:

### 1. SquareConfiguration
### 2. SquareSyncMapping  
### 3. SyncLog (if exists)

## How to Add Entities in Xcode

### Step 1: Open the Data Model
1. In Xcode, open `ProTech.xcdatamodeld/ProTech.xcdatamodel`
2. This will open the Core Data Model Editor

### Step 2: Add SquareConfiguration Entity

1. Click the **"+ Add Entity"** button at the bottom
2. Rename "Entity" to **"SquareConfiguration"**
3. With SquareConfiguration selected, add these **Attributes**:

| Attribute Name | Type | Optional | Default Value |
|----------------|------|----------|---------------|
| id | UUID | No | - |
| accessToken | String | No | - |
| refreshToken | String | Yes | - |
| merchantId | String | No | - |
| locationId | String | No | - |
| locationName | String | Yes | - |
| environmentRaw | String | No | "sandbox" |
| syncEnabled | Boolean | No | true |
| syncInterval | Double | No | 3600.0 |
| lastFullSync | Date | Yes | - |
| webhookSignatureKey | String | Yes | - |
| webhookSubscriptionId | String | Yes | - |
| defaultConflictResolutionRaw | String | No | "mostRecent" |
| defaultSyncDirectionRaw | String | No | "bidirectional" |
| createdAt | Date | No | - |
| updatedAt | Date | No | - |

4. In the **Data Model Inspector** (right panel), set:
   - **Class:** `SquareConfiguration`
   - **Module:** `ProTech`
   - **Codegen:** `Manual/None`

### Step 3: Add SquareSyncMapping Entity

1. Click **"+ Add Entity"** again
2. Rename to **"SquareSyncMapping"**
3. Add these **Attributes**:

| Attribute Name | Type | Optional | Default Value |
|----------------|------|----------|---------------|
| id | UUID | No | - |
| proTechItemId | UUID | No | - |
| squareCatalogObjectId | String | No | - |
| squareVariationId | String | Yes | - |
| lastSyncedAt | Date | Yes | - |
| syncStatusRaw | String | No | "pending" |
| conflictData | String | Yes | - |
| version | Integer 32 | No | 1 |
| createdAt | Date | No | - |
| updatedAt | Date | No | - |

4. In the **Data Model Inspector**:
   - **Class:** `SquareSyncMapping`
   - **Module:** `ProTech`
   - **Codegen:** `Manual/None`

### Step 4: Add SyncLog Entity (Optional)

1. Click **"+ Add Entity"** again
2. Rename to **"SyncLog"**
3. Add these **Attributes**:

| Attribute Name | Type | Optional | Default Value |
|----------------|------|----------|---------------|
| id | UUID | No | - |
| timestamp | Date | No | - |
| operationRaw | String | No | - |
| itemId | UUID | Yes | - |
| squareObjectId | String | Yes | - |
| statusRaw | String | No | - |
| changedFields | Transformable | Yes | - |
| syncDuration | Double | No | 0.0 |
| details | String | Yes | - |
| errorMessage | String | Yes | - |

4. In the **Data Model Inspector**:
   - **Class:** `SyncLog`  
   - **Module:** `ProTech`
   - **Codegen:** `Manual/None`

### Step 5: Save and Clean Build

1. Save the data model (**Cmd+S**)
2. Clean the build folder: **Product → Clean Build Folder** (Cmd+Shift+K)
3. Rebuild the app: **Product → Build** (Cmd+B)

## Alternative: Temporary Fix (Comment Out)

If you want to skip Square sync for now, you can temporarily disable it:

In `SquareInventorySyncManager.swift` line ~31-36, wrap the config check:
```swift
// Load and set configuration on initialization
if let config = getConfiguration() {
    apiService.setConfiguration(config)
    print("✅ SquareInventorySyncManager initialized with configuration")
} else {
    print("⚠️ SquareInventorySyncManager initialized WITHOUT configuration")
}
```

Change to:
```swift
// Temporarily disabled - add SquareConfiguration entity to Core Data model first
print("⚠️ Square sync disabled - Core Data entities not configured")
return  // Early return to prevent crash
```

## Why This Happened

The Swift model classes (`SquareConfiguration.swift`, `SquareSyncMapping.swift`) were created but the corresponding Core Data entity definitions were never added to the `.xcdatamodeld` file. Core Data needs both:
1. The Swift class definition (✅ exists)
2. The entity schema in the data model file (❌ missing)

## After Adding Entities

The app will need to migrate or reset the Core Data store since you're adding new entities. You may see a migration error on first launch - this is normal. The app should handle it automatically.

If you get persistent migration errors:
1. Delete the app from Applications folder
2. Clean derived data: **Cmd+Shift+K** then close Xcode
3. Delete `~/Library/Containers/Nugentic.ProTech/`
4. Reopen Xcode and rebuild
