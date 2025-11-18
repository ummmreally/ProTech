# ProTech Supabase Sync Documentation

## 🔗 Live Project Configuration

### Project Details
- **Project ID:** `sztwxxwnhupwmvxhbzyo`
- **Project URL:** `https://sztwxxwnhupwmvxhbzyo.supabase.co`
- **Dashboard:** [Supabase Dashboard](https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo)
- **Region:** us-east-1

### API Keys
```swift
// Anon Key (Public - Safe for client-side)
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dHd4eHduaHVwd212eGhienlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMTgwNjAsImV4cCI6MjA3NTg5NDA2MH0.bXsI9XFPIBNtHZR46HiM5qXfzhqZMYOBn1v2UAFAOAk
```

---

## 🏗️ Architecture Overview

### Core Components

```
┌─────────────────────────────────────────────────────┐
│                   ProTech App                        │
├─────────────────────────────────────────────────────┤
│                                                      │
│  ┌──────────────┐      ┌──────────────────────┐   │
│  │  Core Data   │◄────►│   Sync Services      │   │
│  │   (Local)    │      │  - CustomerSyncer    │   │
│  └──────────────┘      │  - TicketSyncer      │   │
│                        │  - InventorySyncer    │   │
│                        │  - EmployeeSyncer     │   │
│                        └──────────┬───────────┘   │
│                                   │                 │
│  ┌──────────────────────┐        │                │
│  │  Offline Queue       │◄───────┤                │
│  │  Manager             │        │                │
│  └──────────────────────┘        │                │
│                                   ▼                │
│  ┌─────────────────────────────────────────────┐  │
│  │         SupabaseService & Auth              │  │
│  └─────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────┘
                     │
                     │ HTTPS + WebSocket
                     ▼
┌─────────────────────────────────────────────────────┐
│                Supabase Cloud                       │
├─────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐              │
│  │  PostgreSQL  │  │   Realtime   │              │
│  │   with RLS   │  │  Subscriptions│              │
│  └──────────────┘  └──────────────┘              │
│                                                    │
│  ┌──────────────┐  ┌──────────────┐              │
│  │   Storage    │  │     Auth     │              │
│  │   Buckets    │  │    (JWT)     │              │
│  └──────────────┘  └──────────────┘              │
└─────────────────────────────────────────────────────┘
```

---

## 🔄 Sync Process

### 1. Initial Setup

```swift
// 1. Configure Supabase (already done in SupabaseConfig.swift)
static let supabaseURL = "https://sztwxxwnhupwmvxhbzyo.supabase.co"
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

// 2. Initialize services (happens on app launch)
SupabaseService.shared.initialize()
SupabaseAuthService.shared.initialize()
OfflineQueueManager.shared.startMonitoring()
```

### 2. Authentication Flow

```swift
// Sign up new employee
try await authService.signUp(
    email: "employee@shop.com",
    password: "SecurePassword123!",
    employeeNumber: "EMP001",
    firstName: "John",
    lastName: "Doe",
    role: "technician",
    pin: "1234",
    shopId: shopId
)

// Sign in
try await authService.signIn(
    email: "employee@shop.com",
    password: "SecurePassword123!"
)

// PIN authentication (for kiosk mode)
try await authService.signInWithPIN(
    employeeNumber: "EMP001",
    pin: "1234"
)
```

### 3. Data Sync Operations

#### Upload (Local → Supabase)
```swift
// Single entity upload
let customer = // ... Core Data customer
try await customerSyncer.upload(customer)

// Batch upload
let customers = // ... array of customers
try await customerSyncer.batchUpload(customers)
```

#### Download (Supabase → Local)
```swift
// Download all changes
try await customerSyncer.download()

// Download with filter
try await ticketSyncer.downloadPending()
```

#### Bidirectional Sync
```swift
// Full sync (upload pending + download changes)
try await customerSyncer.sync()
```

### 4. Conflict Resolution

The system uses `sync_version` and timestamps for conflict resolution:

```swift
enum ConflictResolution {
    case serverWins    // Server data overwrites local
    case localWins     // Local data overwrites server  
    case newestWins    // Newest timestamp wins (default)
}
```

**Conflict Detection:**
1. Compare `sync_version` fields
2. Check `updated_at` timestamps
3. Apply resolution strategy

---

## 🔌 Offline Support

### Offline Queue Manager

When offline, all operations are queued:

```swift
// Operations are automatically queued when offline
offlineQueue.queueCustomerUpload(customer)
offlineQueue.queueTicketUpload(ticket)

// Process queue when back online
await offlineQueue.processPendingQueue()
```

### Network Monitoring
```swift
// Check network status
if offlineQueue.isOnline {
    // Process sync operations
} else {
    // Queue for later
}

// Monitor network changes
offlineQueue.$isOnline
    .sink { isOnline in
        if isOnline {
            // Trigger sync
        }
    }
```

---

## 🚦 Real-time Features

### Subscribe to Changes
```swift
// Customer updates
await customerSyncer.subscribeToChanges()

// Ticket status updates
ticketSyncer.onRealtimeUpdate = { ticket in
    // Update UI
}

// Inventory low stock alerts
inventorySyncer.onLowStock = { items in
    // Show notification
}
```

### Team Presence
```swift
// Track team member presence
presenceMonitor.startMonitoring(employeeId: id)

// Broadcast activity
await channel.track([
    "employee_id": employeeId,
    "online": true,
    "activity": "working_on_ticket"
])
```

---

## 🧪 Testing Sync

### Using SyncTestView

1. **Open Test View:**
   - Launch the app
   - Navigate to Admin → Sync Test

2. **Run Test Suites:**
   - Quick Test - Basic connectivity
   - Authentication - Login/signup flow
   - Customer Sync - CRUD operations
   - Ticket Sync - With dependencies
   - Inventory Sync - Stock management
   - Full Test - All operations

3. **Monitor Results:**
   - ✅ Green = Passed
   - ❌ Red = Failed
   - View detailed error messages
   - Check timing metrics

### Command Line Testing

```bash
# Make script executable
chmod +x verify_supabase.sh

# Run verification
./verify_supabase.sh
```

Expected output:
```
✅ Connection successful
✅ Successfully queried shops table
✅ Auth service is healthy
✅ Storage service is accessible
✅ Realtime endpoint configured
```

---

## 📊 Migration Process

### Using DataMigrationView

1. **Prepare Migration:**
   - Ensure Supabase is connected
   - Create backup of Core Data
   - Configure migration options

2. **Run Migration:**
   ```swift
   await migrationService.startMigration()
   ```

3. **Monitor Progress:**
   - View real-time progress bars
   - Check error logs
   - Review statistics

### Migration Options
- **Skip Existing:** Don't re-migrate synced records
- **Continue on Error:** Don't stop for individual failures
- **Batch Operations:** Upload in batches for performance
- **Create Backup:** Backup before migration

---

## 🔒 Security Considerations

### Row Level Security (RLS)
All tables enforce shop isolation:
```sql
-- Example RLS policy
CREATE POLICY "Shop isolation" ON customers
FOR ALL USING (shop_id = auth.jwt() ->> 'shop_id');
```

### Authentication
- JWT tokens with custom claims
- Shop ID embedded in token
- Role-based access control
- Session timeout (30 minutes)

### Data Protection
- HTTPS for all API calls
- Encrypted storage buckets
- Soft deletes with `deleted_at`
- Audit trail with `sync_version`

---

## 🚨 Troubleshooting

### Common Issues

#### 1. Connection Failed
```
Error: Network request failed
```
**Solution:** Check network connection and Supabase URL

#### 2. Authentication Error
```
Error: Invalid login credentials
```
**Solution:** Verify email/password or recreate account

#### 3. RLS Policy Violation
```
Error: new row violates row-level security policy
```
**Solution:** Ensure user has correct shop_id in JWT claims

#### 4. Sync Conflicts
```
Error: Conflict detected, version mismatch
```
**Solution:** Review conflict resolution strategy

### Debug Mode

Enable detailed logging:
```swift
// In SupabaseService
static let debugMode = true

// View logs
print(supabase.debugLog)
```

### Check Sync Status

```swift
// Check entity sync status
if customer.cloudSyncStatus == "synced" {
    // Successfully synced
} else if customer.cloudSyncStatus == "pending" {
    // Waiting to sync
} else if customer.cloudSyncStatus == "error" {
    // Sync failed
}
```

---

## 📈 Performance Optimization

### Batch Operations
```swift
// Instead of individual uploads
for customer in customers {
    try await upload(customer) // ❌ Slow
}

// Use batch upload
try await batchUpload(customers) // ✅ Fast
```

### Pagination
```swift
// Download in pages
var offset = 0
let limit = 100

while true {
    let batch = try await download(offset: offset, limit: limit)
    if batch.isEmpty { break }
    offset += limit
}
```

### Caching
- Materialized views for reports
- Local cache for frequently accessed data
- Indexed queries for performance

---

## 📝 Monitoring & Logs

### View Logs in Supabase Dashboard
1. Go to [Dashboard](https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo)
2. Navigate to Logs
3. Filter by service:
   - API logs
   - Auth logs
   - Database logs
   - Realtime logs

### Local Logging
```swift
// Enable sync logging
SyncLogger.shared.logLevel = .debug

// View sync operations
SyncLogger.shared.operations.forEach { op in
    print("\(op.timestamp): \(op.type) - \(op.status)")
}
```

---

## 🚀 Production Checklist

Before going to production:

- [ ] Run security audit (`SecurityAuditService`)
- [ ] Test with 1000+ records
- [ ] Verify offline mode works
- [ ] Test conflict resolution
- [ ] Check error handling
- [ ] Review RLS policies
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Document procedures
- [ ] Train users

---

## 📞 Support

### Resources
- [Supabase Documentation](https://supabase.com/docs)
- [Project Dashboard](https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo)
- [Status Page](https://status.supabase.com)

### Common Commands

```bash
# Test connection
curl https://sztwxxwnhupwmvxhbzyo.supabase.co/rest/v1/

# Check auth
curl https://sztwxxwnhupwmvxhbzyo.supabase.co/auth/v1/health

# View project in dashboard
open https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo
```

---

## 🎯 Next Steps

1. **Test Live Sync:** Run SyncTestView with real data
2. **Migration:** Use DataMigrationView to migrate existing data
3. **Monitor:** Watch real-time sync in action
4. **Optimize:** Review performance metrics
5. **Deploy:** Prepare for production rollout
