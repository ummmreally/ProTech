# Square Integration - File Organization

## Overview

ProTech now has **two separate Square integrations**:

1. **Square POS** - Payment processing
2. **Square Inventory Sync** - Inventory synchronization

---

## File Structure

### Square POS (Payment Processing)

**Location**: `ProTech/Views/POS/`

**Files**:
- `SquareSettingsView.swift` - POS configuration settings
- Other POS-related files

**Purpose**: Process payments through Square POS

**Key Features**:
- Payment processing
- Transaction handling
- POS terminal integration

---

### Square Inventory Sync (NEW)

**Location**: `ProTech/Views/Settings/` and `ProTech/Services/`

**Files**:

#### Models
- `Models/SquareSyncMapping.swift`
- `Models/SyncLog.swift`
- `Models/SquareConfiguration.swift`
- `Models/SquareAPIModels.swift`

#### Services
- `Services/SquareAPIService.swift`
- `Services/SquareInventorySyncManager.swift`
- `Services/SquareSyncScheduler.swift`
- `Services/SquareWebhookHandler.swift`

#### Views
- `Views/Settings/SquareInventorySyncSettingsView.swift` ⭐ (renamed to avoid conflict)
- `Views/Inventory/SquareSyncDashboardView.swift`

**Purpose**: Synchronize inventory between ProTech and Square

**Key Features**:
- Bidirectional inventory sync
- Conflict resolution
- Auto-sync scheduling
- Webhook support
- Batch operations

---

## Navigation

### Square POS Settings
```
Settings → POS → Square Settings
```

### Square Inventory Sync Settings
```
Settings → Integrations → Square Inventory Sync
```

### Square Sync Dashboard
```
Inventory → Square Sync
```

---

## Important Notes

### File Naming Convention

To avoid conflicts, the inventory sync settings view was renamed:

**Old**: `SquareSettingsView.swift` (conflicted with POS)  
**New**: `SquareInventorySyncSettingsView.swift` ✅

### Enum Conflicts

Both integrations define `SquareEnvironment` enum. They are kept separate:

**POS Version** (in `SquareSettingsView.swift`):
```swift
enum SquareEnvironment: String, Codable {
    case sandbox
    case production
}
```

**Inventory Sync Version** (in `SquareConfiguration.swift`):
```swift
enum SquareEnvironment: String, Codable {
    case sandbox
    case production
    
    var displayName: String { ... }
    var baseURL: String { ... }
}
```

### Integration Points

The two integrations are **independent** but can share:
- Square credentials (if desired)
- Location ID
- Environment setting (sandbox/production)

---

## Usage

### For Payment Processing
Use the **Square POS** integration in `Views/POS/SquareSettingsView.swift`

### For Inventory Management
Use the **Square Inventory Sync** integration in `Views/Settings/SquareInventorySyncSettingsView.swift`

---

## Build Fix

The duplicate file error has been resolved by renaming:
- ❌ `Views/Settings/SquareSettingsView.swift` (conflicted)
- ✅ `Views/Settings/SquareInventorySyncSettingsView.swift` (fixed)

---

*Last Updated: 2025-10-02*
