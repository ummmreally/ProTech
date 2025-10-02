# Square Integration - Quick Reference

## 🚀 Quick Start Checklist

- [ ] Create Square Developer account
- [ ] Create Square application
- [ ] Copy Application ID and Secret
- [ ] Update credentials in `SquareAPIService.swift`
- [ ] Configure URL scheme in Xcode
- [ ] Connect to Square in ProTech settings
- [ ] Select primary location
- [ ] Configure sync settings
- [ ] Perform initial sync
- [ ] Monitor sync dashboard

---

## 📁 File Structure

```
ProTech/
├── Models/
│   ├── SquareSyncMapping.swift       # Item mapping model
│   ├── SyncLog.swift                 # Sync history model
│   ├── SquareConfiguration.swift     # Settings model
│   └── SquareAPIModels.swift         # API data models
│
├── Services/
│   ├── SquareAPIService.swift        # API client
│   ├── SquareInventorySyncManager.swift  # Sync orchestrator
│   ├── SquareSyncScheduler.swift     # Background scheduler
│   └── SquareWebhookHandler.swift    # Webhook processor
│
└── Views/
    ├── Settings/
    │   └── SquareSettingsView.swift  # Settings UI
    └── Inventory/
        └── SquareSyncDashboardView.swift  # Sync dashboard
```

---

## 🔑 Key Classes

### SquareAPIService
**Purpose**: Handles all Square API communication

**Key Methods**:
- `exchangeCodeForToken()` - OAuth authentication
- `listCatalogItems()` - Fetch Square items
- `createCatalogItem()` - Create item in Square
- `batchRetrieveInventoryCounts()` - Get inventory counts
- `setInventoryCount()` - Update inventory quantity

### SquareInventorySyncManager
**Purpose**: Orchestrates synchronization logic

**Key Methods**:
- `importAllFromSquare()` - Import all Square items
- `exportAllToSquare()` - Export all ProTech items
- `syncItem()` - Sync single item
- `syncAllItems()` - Sync all items
- `detectConflicts()` - Find sync conflicts
- `resolveConflict()` - Resolve conflict

### SquareSyncScheduler
**Purpose**: Manages scheduled background sync

**Key Methods**:
- `startScheduledSync()` - Enable auto-sync
- `stopScheduledSync()` - Disable auto-sync
- `performManualSync()` - Trigger immediate sync

---

## 🎯 Common Tasks

### Connect to Square
```swift
// In SquareSettingsView
1. Click "Connect to Square"
2. Authorize in browser
3. Return to app
4. Select location
```

### Import from Square
```swift
// Programmatically
try await syncManager.importAllFromSquare()

// Via UI
Inventory → Square Sync → Menu → Import from Square
```

### Export to Square
```swift
// Programmatically
try await syncManager.exportAllToSquare()

// Via UI
Inventory → Square Sync → Menu → Export to Square
```

### Sync Single Item
```swift
let item: InventoryItem = ...
try await syncManager.syncItem(item, direction: .bidirectional)
```

### Enable Auto-Sync
```swift
let interval: TimeInterval = .oneHour
syncManager.startAutoSync(interval: interval)
```

### Check Sync Status
```swift
let stats = syncManager.getSyncStatistics()
print("Synced: \(stats.syncedItems)/\(stats.totalItems)")
```

---

## 🔄 Sync Strategies

### Bidirectional Sync
- Changes flow both ways
- Conflicts detected and resolved
- **Best for**: Most use cases

### To Square Only
- ProTech → Square
- Square changes ignored
- **Best for**: ProTech as source of truth

### From Square Only
- Square → ProTech
- ProTech changes ignored
- **Best for**: Square as source of truth

---

## ⚠️ Conflict Resolution

### Most Recent Wins
```swift
// Automatically uses newest data
strategy: .mostRecent
```

### Square Wins
```swift
// Always prefer Square data
strategy: .squareWins
```

### ProTech Wins
```swift
// Always prefer ProTech data
strategy: .proTechWins
```

### Manual Resolution
```swift
// Require user decision
strategy: .manual
```

---

## 📊 Data Models

### SquareSyncMapping
```swift
@Model
class SquareSyncMapping {
    var proTechItemId: UUID
    var squareCatalogObjectId: String
    var squareVariationId: String?
    var lastSyncedAt: Date
    var syncStatus: SyncStatus
    var syncDirection: SyncDirection
}
```

### SyncLog
```swift
@Model
class SyncLog {
    var timestamp: Date
    var operation: SyncOperation
    var status: SyncStatus
    var errorMessage: String?
    var syncDuration: TimeInterval
}
```

### SquareConfiguration
```swift
@Model
class SquareConfiguration {
    var accessToken: String
    var merchantId: String
    var locationId: String
    var syncEnabled: Bool
    var syncInterval: TimeInterval
    var defaultConflictResolution: ConflictResolutionStrategy
}
```

---

## 🛠️ API Endpoints

### Authentication
```
POST /oauth2/token
POST /oauth2/refresh
```

### Catalog
```
GET  /v2/catalog/list
GET  /v2/catalog/object/{id}
POST /v2/catalog/object
POST /v2/catalog/batch-upsert
DELETE /v2/catalog/object/{id}
```

### Inventory
```
POST /v2/inventory/counts/batch-retrieve
POST /v2/inventory/changes/batch-create
POST /v2/inventory/physical-count
```

### Webhooks
```
POST /v2/webhooks/subscriptions
GET  /v2/webhooks/subscriptions
```

---

## 🔐 Security Checklist

- [ ] Store `clientSecret` in Keychain (not in code)
- [ ] Use HTTPS for all API calls
- [ ] Verify webhook signatures
- [ ] Encrypt access tokens at rest
- [ ] Never log sensitive data
- [ ] Rotate tokens periodically
- [ ] Use sandbox for testing
- [ ] Validate all API responses

---

## 🐛 Debugging

### Enable Verbose Logging
```swift
// In SquareAPIService
print("📤 Request: \(request)")
print("📥 Response: \(response)")
```

### Check Sync Logs
```swift
// Query recent logs
let descriptor = FetchDescriptor<SyncLog>(
    sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
)
let logs = try modelContext.fetch(descriptor)
```

### Test API Connection
```swift
let isValid = try await SquareAPIService.shared.validateToken()
print("Connection valid: \(isValid)")
```

### View Mappings
```swift
let descriptor = FetchDescriptor<SquareSyncMapping>()
let mappings = try modelContext.fetch(descriptor)
print("Total mappings: \(mappings.count)")
```

---

## 📈 Performance Tips

1. **Use Batch Operations**
   ```swift
   // Good: Batch upsert
   try await apiService.batchUpsertCatalogItems(items)
   
   // Avoid: Individual creates
   for item in items {
       try await apiService.createCatalogItem(item)
   }
   ```

2. **Incremental Sync**
   ```swift
   // Only sync changed items
   let lastSync = Date().addingTimeInterval(-3600)
   try await syncManager.syncChangedItems(since: lastSync)
   ```

3. **Respect Rate Limits**
   ```swift
   // Automatic retry with backoff
   try await apiService.retryWithExponentialBackoff {
       try await apiService.listCatalogItems()
   }
   ```

4. **Cache Catalog Data**
   ```swift
   // Store locally, refresh periodically
   UserDefaults.standard.set(Date(), forKey: "lastCatalogFetch")
   ```

---

## 🧪 Testing

### Sandbox Environment
```swift
let config = SquareConfiguration(
    accessToken: "SANDBOX_TOKEN",
    merchantId: "SANDBOX_MERCHANT",
    locationId: "SANDBOX_LOCATION",
    environment: .sandbox  // Use sandbox
)
```

### Mock Data
```swift
// Create test items
let testItem = InventoryItem(
    name: "Test Item",
    sku: "TEST-001",
    quantity: 10,
    price: 99.99
)
```

### Unit Tests
```swift
func testSyncItem() async throws {
    let item = createTestItem()
    try await syncManager.syncItem(item, direction: .toSquare)
    
    let mapping = syncManager.getMapping(for: item)
    XCTAssertNotNil(mapping)
    XCTAssertEqual(mapping?.syncStatus, .synced)
}
```

---

## 📱 UI Navigation

### Settings
```
Settings → Integrations → Square
```

### Sync Dashboard
```
Inventory → Square Sync
```

### Item Details
```
Inventory → [Select Item] → Square Mapping
```

---

## 🚨 Error Codes

| Code | Error | Solution |
|------|-------|----------|
| 401 | Unauthorized | Refresh token or reconnect |
| 429 | Rate limit | Wait and retry |
| 404 | Not found | Check object ID |
| 400 | Bad request | Validate request data |
| 500 | Server error | Retry later |

---

## 💡 Pro Tips

1. **Start with Sandbox**: Always test in sandbox before production
2. **Unique SKUs**: Ensure every item has a unique SKU
3. **Regular Backups**: Backup data before major syncs
4. **Monitor First Sync**: Watch the first few syncs closely
5. **Use Webhooks**: Enable for real-time updates
6. **Off-Peak Syncs**: Schedule large syncs during off-hours
7. **Document Conflicts**: Keep notes on how you resolve conflicts
8. **Test Rollback**: Have a plan to undo changes if needed

---

## 📞 Support

### Square Support
- Developer Portal: https://developer.squareup.com/
- Forums: https://developer.squareup.com/forums
- API Status: https://status.squareup.com/

### ProTech Support
- Check sync logs in app
- Review documentation
- Test in sandbox first

---

## 🔗 Quick Links

- [Implementation Plan](SQUARE_INVENTORY_SYNC_IMPLEMENTATION_PLAN.md)
- [Setup Guide](SQUARE_SETUP_GUIDE.md)
- [Square API Docs](https://developer.squareup.com/reference/square)
- [OAuth Guide](https://developer.squareup.com/docs/oauth-api/overview)

---

*Quick Reference v1.0 - Last Updated: 2025-10-02*
