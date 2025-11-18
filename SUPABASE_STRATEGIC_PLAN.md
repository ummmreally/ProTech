# ProTech Supabase Strategic Plan
## Mass Market Deployment Strategy

> **Goal:** Transition ProTech from local-only Core Data to a cloud-first architecture using Supabase for multi-device sync, real-time collaboration, and scalable mass market deployment.

---

## 📊 Executive Summary

**Current State:**
- ✅ Supabase Swift SDK integrated
- ✅ Basic sync services scaffolded (`SupabaseService`, `SupabaseSyncService`)
- ✅ 30+ Core Data entities for repair shop operations
- ⚠️ CloudKit disabled, local-only storage
- ⚠️ No production Supabase schema deployed
- ⚠️ Incomplete sync layer between Core Data ↔ Supabase

**Target State:**
- 🎯 Full bidirectional sync (Core Data ↔ Supabase)
- 🎯 Multi-device support (macOS, iOS, Web planned)
- 🎯 Real-time updates across devices
- 🎯 Offline-first with conflict resolution
- 🎯 Row-level security (RLS) for multi-tenant data
- 🎯 Scalable backend for thousands of repair shops

---

## 🏗️ Architecture Overview

### Current Architecture
```
┌─────────────────────┐
│   ProTech macOS     │
│                     │
│  ┌───────────────┐  │
│  │  Core Data    │  │  (Local SQLite)
│  │   (Local)     │  │
│  └───────────────┘  │
│         │           │
│         ▼           │
│  ┌───────────────┐  │
│  │ Partial Sync  │  │  (Incomplete)
│  │   Services    │  │
│  └───────────────┘  │
└─────────────────────┘
```

### Target Architecture (Supabase-Powered)
```
┌──────────────────────────────────────────────────────────┐
│                    Supabase Cloud                         │
│  ┌────────────┐  ┌──────────┐  ┌───────────────────┐    │
│  │ PostgreSQL │  │   Auth   │  │   Realtime        │    │
│  │    +RLS    │  │          │  │   Subscriptions   │    │
│  └────────────┘  └──────────┘  └───────────────────┘    │
│  ┌────────────┐  ┌──────────┐  ┌───────────────────┐    │
│  │  Storage   │  │  Edge    │  │   Webhooks        │    │
│  │  (Photos)  │  │Functions │  │                   │    │
│  └────────────┘  └──────────┘  └───────────────────┘    │
└──────────────────────────────────────────────────────────┘
                          ▲
                          │ REST/GraphQL API
                          │ Real-time WebSocket
    ┌─────────────────────┼─────────────────────┐
    │                     │                     │
┌───┴────────┐    ┌───────┴─────┐     ┌────────┴─────┐
│  ProTech   │    │   ProTech   │     │   Customer   │
│   macOS    │    │     iOS     │     │  Web Portal  │
│            │    │             │     │              │
│ Core Data  │    │ Core Data   │     │ Direct API   │
│  + Sync    │    │  + Sync     │     │              │
└────────────┘    └─────────────┘     └──────────────┘
```

---

## 📋 Implementation Phases

### Phase 1: Database Schema & Setup (Week 1-2)
**Goal:** Establish production-ready Supabase schema

#### 1.1 Supabase Project Setup
- [x] Project already exists: `ucpgsubidqbhxstgykyt.supabase.co`
- [ ] Verify project region (should match target audience)
- [ ] Configure custom domain (optional): `api.protech.app`
- [ ] Set up staging environment for testing

#### 1.2 Schema Migration
**Priority Entities** (Phase 1):
- `employees` - User accounts & authentication
- `customers` - Customer records
- `tickets` - Repair tickets (core business entity)
- `inventory_items` - Parts inventory
- `time_clock_entries` - Employee time tracking

**SQL Migration Tasks:**
1. Generate TypeScript types from Core Data model
2. Create equivalent PostgreSQL tables with proper indexing
3. Add `created_at`, `updated_at`, `sync_version` to all tables
4. Add `deleted_at` for soft deletes (conflict resolution)
5. Create composite indexes for common queries

**Sample Migration:**
```sql
-- employees table (maps to Employee entity)
CREATE TABLE public.employees (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_number TEXT UNIQUE,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  role TEXT NOT NULL DEFAULT 'technician',
  is_admin BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  hourly_rate DECIMAL(10,2),
  hire_date TIMESTAMPTZ,
  phone TEXT,
  password_hash TEXT, -- Migrate to Supabase Auth
  pin_code TEXT, -- Keep for quick local auth
  failed_pin_attempts INTEGER DEFAULT 0,
  pin_locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  
  -- Sync metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 1,
  
  -- Multi-tenancy
  shop_id UUID NOT NULL REFERENCES shops(id)
);

-- Row Level Security (RLS)
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see employees from their shop
CREATE POLICY "Employees visible to shop members"
  ON public.employees FOR SELECT
  USING (shop_id = auth.jwt() ->> 'shop_id');
```

#### 1.3 Multi-Tenancy Setup
**Challenge:** Multiple repair shops using same database

**Solution:** Add `shop_id` to all tables
```sql
CREATE TABLE public.shops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  subscription_tier TEXT DEFAULT 'free',
  subscription_expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add shop_id foreign key to all entities
ALTER TABLE customers ADD COLUMN shop_id UUID REFERENCES shops(id);
ALTER TABLE tickets ADD COLUMN shop_id UUID REFERENCES shops(id);
-- ... repeat for all tables
```

---

### Phase 2: Authentication Layer (Week 2-3)
**Goal:** Migrate from local authentication to Supabase Auth

#### 2.1 Auth Strategy
**Current:** Local PIN + Email/Password stored in Core Data
**Target:** Supabase Auth with local PIN fallback

**Hybrid Authentication Flow:**
1. **Primary**: Supabase Auth (email/password, magic links)
2. **Secondary**: Local PIN for quick access (cached)
3. **Fallback**: Offline PIN auth when network unavailable

#### 2.2 Implementation Tasks
- [ ] Create `AuthenticationManager` to bridge Supabase Auth + local auth
- [ ] Migrate existing employees to Supabase Auth
- [ ] Store JWT tokens securely (Keychain)
- [ ] Implement refresh token rotation
- [ ] Add biometric authentication (Touch ID/Face ID)

**Code Structure:**
```swift
class AuthenticationManager: ObservableObject {
    private let supabase = SupabaseService.shared
    private let localAuth = AuthenticationService.shared
    
    enum AuthMode {
        case online(supabase: Bool, pin: Bool)
        case offline(pinOnly: Bool)
    }
    
    func authenticate(email: String, password: String) async throws {
        // Try Supabase first
        do {
            try await supabase.signIn(email: email, password: password)
            // Cache session locally
            await cacheSession()
        } catch {
            // Fallback to local auth if offline
            if !isOnline {
                return try localAuth.loginWithEmail(email, password: password)
            }
            throw error
        }
    }
}
```

#### 2.3 Security Enhancements
- [ ] Implement JWT-based RLS policies
- [ ] Add MFA (multi-factor authentication) support
- [ ] Session management with automatic refresh
- [ ] Audit logging for all auth events

---

### Phase 3: Sync Layer Architecture (Week 3-5)
**Goal:** Build robust bidirectional sync

#### 3.1 Sync Strategy: Operational Transformation
**Conflict Resolution:**
- **Last Write Wins (LWW)**: Use `updated_at` timestamp
- **Version Vectors**: Track `sync_version` to detect conflicts
- **Merge Strategy**: Configurable per-entity (newest wins, server wins, manual)

#### 3.2 Sync Components

**A. Change Tracking**
```swift
class CoreDataChangeTracker {
    // Track all changes in Core Data
    func trackInsert(_ object: NSManagedObject)
    func trackUpdate(_ object: NSManagedObject, changedKeys: Set<String>)
    func trackDelete(_ object: NSManagedObject)
    
    // Generate delta for upload
    func getPendingChanges() -> [SyncChange]
}
```

**B. Sync Queue**
```swift
class SyncQueue {
    private var pendingUploads: [SyncChange] = []
    private var pendingDownloads: [SyncChange] = []
    
    func enqueue(change: SyncChange)
    func processQueue() async throws
    func resolveConflict(_ local: SyncChange, _ remote: SyncChange) -> SyncChange
}
```

**C. Entity Syncer (Per-Entity)**
```swift
protocol EntitySyncer {
    associatedtype CoreDataEntity: NSManagedObject
    associatedtype SupabaseModel: Codable
    
    func upload(entity: CoreDataEntity) async throws
    func download(model: SupabaseModel) async throws
    func merge(local: CoreDataEntity, remote: SupabaseModel) async throws
}
```

#### 3.3 Implementation Plan
1. **Week 3:** Implement `CustomerSyncer` (simplest entity)
2. **Week 4:** Implement `TicketSyncer` (complex with relations)
3. **Week 5:** Implement remaining entity syncers

**Priority Order:**
1. Customers
2. Tickets
3. Employees
4. Inventory Items
5. Invoices/Payments
6. Time Entries
7. Appointments
8. (Others as needed)

---

### Phase 4: Offline Support & Conflict Resolution (Week 5-6)
**Goal:** Ensure app works offline with graceful sync

#### 4.1 Offline-First Architecture
```swift
class OfflineManager {
    @Published var isOnline: Bool = true
    @Published var pendingChanges: Int = 0
    
    func queueChange(_ change: SyncChange) {
        // Store in local queue
        syncQueue.enqueue(change)
        pendingChanges += 1
    }
    
    func syncWhenOnline() async {
        guard isOnline else { return }
        
        // Upload all pending changes
        await syncQueue.processQueue()
        pendingChanges = 0
    }
}
```

#### 4.2 Conflict Resolution UI
- [ ] Build conflict resolution screen
- [ ] Show side-by-side comparison (local vs server)
- [ ] Allow user to choose winning version
- [ ] Auto-resolve based on strategy when possible

#### 4.3 Testing Scenarios
- [ ] Create ticket while offline → sync when online
- [ ] Two devices modify same ticket → resolve conflict
- [ ] Delete on one device, update on another → tombstone handling
- [ ] Large batch sync (100+ records)

---

### Phase 5: Real-Time Features (Week 6-7)
**Goal:** Enable collaborative features

#### 5.1 Realtime Subscriptions
```swift
class RealtimeManager {
    func subscribeToTickets(shopId: UUID) async {
        await supabase.client
            .from("tickets")
            .on(.all) { event in
                switch event {
                case .insert(let record):
                    await self.handleRemoteInsert(record)
                case .update(let record):
                    await self.handleRemoteUpdate(record)
                case .delete(let record):
                    await self.handleRemoteDelete(record)
                }
            }
            .subscribe()
    }
}
```

#### 5.2 Collaborative Features
- [ ] Live ticket status updates
- [ ] "User X is editing ticket Y" indicators
- [ ] Real-time inventory updates
- [ ] Team notifications (new ticket assigned)

---

### Phase 6: Data Migration & Testing (Week 7-8)
**Goal:** Safely migrate existing users

#### 6.1 Migration Tool
```swift
class DataMigrationTool {
    func migrateToSupabase() async throws {
        // 1. Create shop account
        let shop = try await createShop()
        
        // 2. Migrate employees
        let employees = Employee.fetchAll()
        for employee in employees {
            try await migrateEmployee(employee, shopId: shop.id)
        }
        
        // 3. Migrate customers
        // 4. Migrate tickets
        // 5. Verify data integrity
    }
}
```

#### 6.2 Testing Strategy
**Unit Tests:**
- Sync logic for each entity
- Conflict resolution algorithms
- Offline queue management

**Integration Tests:**
- Full sync cycle (local → server → local)
- Multi-device scenarios
- Network failure handling

**Load Tests:**
- 1,000 tickets sync performance
- 10 concurrent users
- Large file uploads (photos)

---

### Phase 7: Storage & Media (Week 8-9)
**Goal:** Handle photos, signatures, PDFs

#### 7.1 Supabase Storage Integration
```swift
class MediaSyncService {
    func uploadRepairPhoto(_ imageData: Data, ticketId: UUID) async throws -> URL {
        let fileName = "\(ticketId)/\(UUID().uuidString).jpg"
        
        try await supabase.client.storage
            .from("repair-photos")
            .upload(path: fileName, file: imageData)
        
        return try await supabase.client.storage
            .from("repair-photos")
            .getPublicURL(path: fileName)
    }
}
```

#### 7.2 Caching Strategy
- [ ] Local cache for recently viewed images
- [ ] Lazy loading for image galleries
- [ ] Progressive image quality (thumbnails → full)
- [ ] Automatic cleanup of old cache

---

### Phase 8: Production Deployment (Week 9-10)
**Goal:** Launch to mass market

#### 8.1 Pre-Launch Checklist
- [ ] Database backups configured (PITR enabled)
- [ ] Rate limiting on API endpoints
- [ ] Monitoring & alerting (Sentry/DataDog)
- [ ] CDN for storage buckets
- [ ] SSL/TLS verified
- [ ] RLS policies audited
- [ ] Load testing completed (1000+ concurrent users)

#### 8.2 Deployment Strategy
**Phased Rollout:**
1. **Alpha** (Week 9): 5 internal test shops
2. **Beta** (Week 10): 50 early adopter shops
3. **Production** (Week 11): Full rollout

#### 8.3 Monitoring
```typescript
// Supabase Edge Function for health check
Deno.serve(async (req) => {
  const stats = {
    database: await checkDatabaseHealth(),
    auth: await checkAuthHealth(),
    storage: await checkStorageHealth(),
    realtime: await checkRealtimeHealth()
  };
  
  return new Response(JSON.stringify(stats), {
    headers: { "Content-Type": "application/json" }
  });
});
```

---

## 🔒 Security Architecture

### Row Level Security (RLS) Policies

#### Shop Isolation
```sql
-- Ensure users only see their shop's data
CREATE POLICY "shop_isolation_policy"
  ON public.tickets FOR ALL
  USING (shop_id = auth.jwt() ->> 'shop_id');
```

#### Role-Based Access Control
```sql
-- Admins can delete, technicians cannot
CREATE POLICY "admin_delete_policy"
  ON public.tickets FOR DELETE
  USING (
    auth.jwt() ->> 'role' = 'admin'
    AND shop_id = auth.jwt() ->> 'shop_id'
  );
```

### Data Encryption
- [ ] Encrypt sensitive fields (SSN, credit cards) at application layer
- [ ] Use Supabase Vault for secrets
- [ ] TLS 1.3 for all connections

---

## 📊 Performance Optimization

### Database Indexing
```sql
-- Composite index for common queries
CREATE INDEX idx_tickets_shop_status 
  ON tickets(shop_id, status, created_at DESC);

-- Full-text search for customers
CREATE INDEX idx_customers_search 
  ON customers USING gin(to_tsvector('english', 
    first_name || ' ' || last_name || ' ' || email));
```

### Caching Strategy
- **Client-side:** Core Data = local cache
- **Edge caching:** Supabase CDN for storage
- **Query caching:** Cache frequent queries (dashboard stats)

### Pagination
```swift
// Efficient pagination with cursor-based approach
func fetchTickets(after cursor: String?, limit: Int = 50) async throws {
    try await supabase.client
        .from("tickets")
        .select()
        .order("created_at", ascending: false)
        .range(from: cursor, to: cursor + limit)
        .execute()
}
```

---

## 💰 Cost Analysis

### Supabase Pricing Tiers

#### Starter Plan (Free)
- **Database:** 500 MB
- **Storage:** 1 GB
- **Bandwidth:** 2 GB
- **Suitable for:** Testing, small shops (<10 users)

#### Pro Plan ($25/month per project)
- **Database:** 8 GB included (+$0.125/GB after)
- **Storage:** 100 GB
- **Bandwidth:** 250 GB
- **Suitable for:** Small-medium shops (10-100 users)

#### Scale Plan (Custom)
- **Database:** Unlimited
- **Storage:** Unlimited
- **Bandwidth:** Unlimited
- **Suitable for:** Enterprise, multi-shop franchises

### Cost Projections
| Users | Monthly Cost | Revenue (20/mo) | Margin |
|-------|--------------|-----------------|--------|
| 10    | $25          | $200           | $175   |
| 100   | $75          | $2,000         | $1,925 |
| 1,000 | $300         | $20,000        | $19,700|
| 10,000| $1,500       | $200,000       | $198,500|

**Note:** Costs increase with storage (photos) and compute (realtime connections)

---

## 🚀 Alternative: Self-Hosted Supabase

### Benefits
- **No subscription limits**
- **Full control over data**
- **Unlimited scaling**

### Infrastructure
```yaml
# docker-compose.yml
services:
  postgres:
    image: supabase/postgres:latest
    volumes:
      - postgres-data:/var/lib/postgresql/data
  
  supabase-auth:
    image: supabase/gotrue:latest
  
  supabase-rest:
    image: postgrest/postgrest:latest
  
  supabase-realtime:
    image: supabase/realtime:latest
  
  supabase-storage:
    image: supabase/storage-api:latest
```

### Hosting Options
- **AWS:** ~$100-500/month (EC2 + RDS + S3)
- **DigitalOcean:** ~$50-200/month (Droplets + Spaces)
- **Railway/Fly.io:** ~$30-100/month (managed PostgreSQL)

---

## 🛠️ Development Tools

### Code Generation
```bash
# Generate Swift types from Supabase schema
supabase gen types swift > Models/SupabaseTypes.swift
```

### Migration Scripts
```bash
# Create new migration
supabase migration new add_shops_table

# Apply migrations
supabase db push

# Rollback
supabase db reset
```

### Testing
```swift
// Mock Supabase for unit tests
class MockSupabaseClient: SupabaseClient {
    var mockData: [String: Any] = [:]
    
    override func from(_ table: String) -> QueryBuilder {
        return MockQueryBuilder(data: mockData[table])
    }
}
```

---

## 📚 Documentation & Training

### Developer Documentation
- [ ] API reference (generated from schema)
- [ ] Sync architecture diagrams
- [ ] Code examples for common tasks
- [ ] Troubleshooting guide

### User Documentation
- [ ] "Getting Started" guide
- [ ] Multi-device setup tutorial
- [ ] Offline mode explanation
- [ ] FAQ for sync conflicts

---

## 🎯 Success Metrics

### Technical KPIs
- **Sync success rate:** >99%
- **Average sync latency:** <2 seconds
- **Conflict rate:** <1% of syncs
- **Uptime:** 99.9%

### Business KPIs
- **Active users:** Track monthly active devices
- **Data volume:** Monitor database growth
- **API usage:** Track requests/day
- **Support tickets:** Aim for <5% users needing help

---

## ⚠️ Risk Mitigation

### Technical Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Data loss during sync | High | Transaction-based sync, backup before migration |
| Supabase outage | High | Offline-first architecture, cached data |
| Slow sync performance | Medium | Optimize queries, add indexes, batch operations |
| Schema migration bugs | High | Staging environment, gradual rollout |

### Business Risks
| Risk | Impact | Mitigation |
|------|--------|------------|
| Supabase pricing increases | Medium | Self-hosting option ready |
| User adoption resistance | Medium | Clear migration guide, benefits communication |
| Competitor launches similar | Low | Focus on unique features (Square integration) |

---

## 🗓️ Timeline Summary

| Phase | Duration | Key Deliverables |
|-------|----------|------------------|
| 1. Schema Setup | 2 weeks | PostgreSQL schema, RLS policies |
| 2. Authentication | 1 week | Supabase Auth integration |
| 3. Sync Layer | 3 weeks | Bidirectional sync for all entities |
| 4. Offline/Conflicts | 2 weeks | Conflict resolution, offline queue |
| 5. Real-time | 1 week | Live updates, collaborative features |
| 6. Migration & Testing | 2 weeks | Data migration tool, comprehensive tests |
| 7. Storage | 1 week | Photo/file uploads |
| 8. Production Deploy | 2 weeks | Monitoring, phased rollout |

**Total:** 14 weeks (3.5 months)

---

## 🎬 Next Steps

### Immediate Actions (This Week)
1. ✅ Review current Supabase project setup
2. ✅ Audit existing `SupabaseService` and `SupabaseSyncService` code
3. ✅ Design PostgreSQL schema for priority entities
4. ✅ Set up staging Supabase project for testing

### Week 1 Tasks
1. Create SQL migrations for `shops`, `employees`, `customers`, `tickets`
2. Implement RLS policies
3. Generate TypeScript/Swift types
4. Test basic CRUD operations

### Milestones
- **M1 (Week 2):** Schema deployed, basic auth working
- **M2 (Week 5):** Customers & Tickets syncing reliably
- **M3 (Week 8):** Full feature parity with offline support
- **M4 (Week 10):** Beta launch ready

---

## 📞 Support & Resources

### Supabase Resources
- [Supabase Docs](https://supabase.com/docs)
- [Swift Client SDK](https://github.com/supabase-community/supabase-swift)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)

### Team Contacts
- **Lead Developer:** [Your Name]
- **Database Admin:** [DBA Name]
- **DevOps:** [DevOps Name]

---

## ✅ Conclusion

Transitioning ProTech to Supabase will enable:
- ✅ **Multi-platform expansion** (iOS, Web)
- ✅ **Real-time collaboration** for teams
- ✅ **Scalable infrastructure** for mass market
- ✅ **Reduced maintenance** vs self-hosted solutions
- ✅ **Modern DX** for rapid feature development

**Estimated Effort:** 3.5 months (1 full-time developer)
**Estimated Cost:** $25-300/month (scales with usage)
**ROI:** Enables $200K+ ARR with 1,000 users

**Recommendation:** Proceed with phased implementation starting with Phase 1 (Schema Setup).

---

*Last Updated: January 2025*
*Document Version: 1.0*
