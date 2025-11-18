# 🗺️ Complete Supabase Sync Roadmap

**Comprehensive analysis of ALL 46 Core Data entities**

---

## 📊 Executive Summary

- **Total Entities**: 46
- **Currently Syncing**: 5 (11%)
- **Pending Migrations**: 2 (Appointments, Loyalty)
- **Should Sync**: 20 (44%)
- **Local Only**: 21 (45%)

**Goal**: Achieve 60% coverage (27 entities synced) for full multi-device support

---

## ✅ TIER 1: Currently Syncing (5 entities)

| # | Entity | Syncer | Table | Status |
|---|--------|--------|-------|--------|
| 1 | Customer | ✅ | `customers` | **LIVE** |
| 2 | Employee | ✅ | `employees` | **LIVE** |
| 3 | Ticket | ✅ | `tickets` | **LIVE** |
| 4 | InventoryItem | ✅ | `inventory_items` | **LIVE** |
| 5 | Appointment | ✅ | ⚠️ **MIGRATION PENDING** | **NEEDS PUSH** |

**Next Action**: `supabase db push` to activate Appointments

---

## 🔴 TIER 2: Critical Business Entities (10 entities)

**Must sync for normal operations**

### Financial (Priority 1)
| # | Entity | Impact | Frequency | Dependencies |
|---|--------|--------|-----------|-------------|
| 6 | **Payment** | 🔴 Critical | Every transaction | Customer |
| 7 | **Invoice** | 🔴 Critical | Daily | Customer, Ticket |
| 8 | **InvoiceLineItem** | 🔴 Critical | Per invoice | Invoice |
| 9 | **Estimate** | 🔴 Critical | Daily | Customer, Ticket |
| 10 | **EstimateLineItem** | 🔴 Critical | Per estimate | Estimate |

### Time & Labor (Priority 2)
| # | Entity | Impact | Frequency | Dependencies |
|---|--------|--------|-----------|-------------|
| 11 | **TimeEntry** | 🟠 High | Per ticket | Employee, Ticket |
| 12 | **TimeClockEntry** | 🟠 High | Daily | Employee |
| 13 | **TimeOffRequest** | 🟠 High | Weekly | Employee |

### Inventory Management (Priority 3)
| # | Entity | Impact | Frequency | Dependencies |
|---|--------|--------|-----------|-------------|
| 14 | **PurchaseOrder** | 🟠 High | Weekly | Supplier |
| 15 | **StockAdjustment** | 🟡 Medium | Daily | InventoryItem |

---

## 🟡 TIER 3: Enhanced Features (7 entities)

**Improve customer experience and marketing**

### Loyalty Program
| # | Entity | Status | Table | Action |
|---|--------|--------|-------|--------|
| 16 | **LoyaltyProgram** | ⚠️ Migration pending | `loyalty_programs` | `supabase db push` |
| 17 | **LoyaltyTier** | ⚠️ Migration pending | `loyalty_tiers` | `supabase db push` |
| 18 | **LoyaltyMember** | ⚠️ Migration pending | `loyalty_members` | `supabase db push` |
| 19 | **LoyaltyReward** | ⚠️ Migration pending | `loyalty_rewards` | `supabase db push` |
| 20 | **LoyaltyTransaction** | ⚠️ Migration pending | `loyalty_transactions` | `supabase db push` |

### Marketing
| # | Entity | Impact | Use Case |
|---|--------|--------|----------|
| 21 | **Campaign** | 🟡 Medium | SMS/Email campaigns |
| 22 | **DiscountCode** | 🟡 Medium | Promotions & coupons |

---

## 🟢 TIER 4: Supporting Features (8 entities)

**Nice-to-have for complete functionality**

| # | Entity | Impact | Reason to Sync |
|---|--------|--------|----------------|
| 23 | **FormTemplate** | 🟢 Low | Share custom forms across devices |
| 24 | **FormSubmission** | 🟢 Low | Access submissions anywhere |
| 25 | **Supplier** | 🟢 Low | Vendor management |
| 26 | **EmployeeSchedule** | 🟢 Low | Staff scheduling |
| 27 | **Transaction** | 🟢 Low | Financial reporting |
| 28 | **RecurringInvoice** | 🟢 Low | Subscription billing |
| 29 | **PurchaseHistory** | 🟢 Low | Customer purchase analytics |
| 30 | **PaymentMethod** | 🟢 Low | Stored payment info |

---

## 🔵 TIER 5: Embedded/Child Entities (6 entities)

**Consider embedding in parent vs separate sync**

| # | Entity | Parent | Recommendation |
|---|--------|--------|----------------|
| 31 | RepairProgress | Ticket | Embed as JSONB in `tickets` |
| 32 | RepairStageRecord | Ticket | Embed as JSONB in `tickets` |
| 33 | RepairPartUsage | Ticket | Embed as JSONB in `tickets` |
| 34 | TicketNote | Ticket | Separate table OR embed |
| 35 | SMSMessage | Ticket | Query Twilio API (no sync) |
| 36 | CheckIn | Ticket | Migrate to Ticket fields |

---

## ❌ TIER 6: Local Only - DO NOT SYNC (10 entities)

**Security, config, or technical reasons**

| # | Entity | Reason |
|---|--------|--------|
| 37 | SquareConfiguration | **Security**: API credentials |
| 38 | SquareSyncMapping | **Local**: Sync state tracking |
| 39 | SyncLog | **Local**: Debug logs |
| 40 | NotificationLog | **Local**: Notification history |
| 41 | NotificationRule | **Config**: Local preferences |
| 42 | LineItemData | **Utility**: Helper struct |
| 43 | InventorySupport | **Utility**: Helper functions |
| 44 | SyncSharedTypes | **Utility**: Type definitions |
| 45 | SyncErrors | **Utility**: Error handling |
| 46 | SquareAPIModels | **Utility**: API structures |

---

## 📅 Implementation Timeline

### Week 1: Apply Pending & Test ✅
**Effort**: 4 hours

```bash
# Apply migrations
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase db push
```

- [x] Appointments table created
- [x] Loyalty tables created (5 tables)
- [ ] Test AppointmentSyncer
- [ ] Test LoyaltySyncer
- [ ] Verify real-time updates

**Deliverable**: 11 entities synced (24%)

---

### Week 2-3: Financial Entities (Priority 1) 🔴
**Effort**: 20 hours

#### Payments (4 hours)
- [ ] Create migration: `payments` table
- [ ] Create `PaymentSyncer.swift`
- [ ] Add `cloudSyncStatus` to `Payment.swift`
- [ ] Update `OfflineQueueManager`
- [ ] Add to `RealtimeManager`
- [ ] Create payment views with sync UI

#### Invoices (8 hours)
- [ ] Create migration: `invoices` + `invoice_line_items`
- [ ] Create `InvoiceSyncer.swift`
- [ ] Add `cloudSyncStatus` to `Invoice.swift`
- [ ] Add `cloudSyncStatus` to `InvoiceLineItem.swift`
- [ ] Handle parent-child sync
- [ ] Update managers
- [ ] Update invoice views

#### Estimates (8 hours)
- [ ] Create migration: `estimates` + `estimate_line_items`
- [ ] Create `EstimateSyncer.swift`
- [ ] Add `cloudSyncStatus` to `Estimate.swift`
- [ ] Add `cloudSyncStatus` to `EstimateLineItem.swift`
- [ ] Handle parent-child sync
- [ ] Update managers
- [ ] Update estimate views

**Deliverable**: 16 entities synced (35%)

---

### Week 4: Time & Labor (Priority 2) 🟠
**Effort**: 12 hours

#### Time Tracking (8 hours)
- [ ] Create migrations: `time_entries`, `time_clock_entries`
- [ ] Create `TimeTrackingSyncer.swift`
- [ ] Add `cloudSyncStatus` to both models
- [ ] Update managers
- [ ] Update time tracking views

#### Time Off (4 hours)
- [ ] Create migration: `time_off_requests`
- [ ] Create `TimeOffSyncer.swift`
- [ ] Add `cloudSyncStatus`
- [ ] Update views

**Deliverable**: 19 entities synced (41%)

---

### Week 5: Inventory & Marketing (Priority 3) 🟡
**Effort**: 16 hours

#### Inventory Management (8 hours)
- [ ] Create migrations: `purchase_orders`, `stock_adjustments`, `suppliers`
- [ ] Create `PurchaseOrderSyncer.swift`
- [ ] Create `SupplierSyncer.swift`
- [ ] Add `cloudSyncStatus` to models
- [ ] Update managers

#### Marketing (8 hours)
- [ ] Create migrations: `campaigns`, `discount_codes`
- [ ] Create `MarketingSyncer.swift`
- [ ] Add `cloudSyncStatus` to models
- [ ] Update managers

**Deliverable**: 24 entities synced (52%)

---

### Week 6: Supporting Features (Optional) 🟢
**Effort**: 12 hours

- [ ] Forms sync (templates + submissions)
- [ ] Schedules sync
- [ ] Transactions sync
- [ ] Recurring invoices sync

**Deliverable**: 30 entities synced (65%)

---

## 🎯 Recommended Phases

### Phase 1: Foundation (DONE ✅)
- Customers, Employees, Tickets, Inventory, Appointments

### Phase 2: Financial (Weeks 2-3)
- Payments, Invoices, Estimates
- **Critical for revenue tracking**

### Phase 3: Operations (Week 4)
- Time tracking, Time off
- **Critical for labor management**

### Phase 4: Growth (Week 5)
- Inventory management, Marketing
- **Enables business scaling**

### Phase 5: Polish (Week 6)
- Forms, Schedules, Advanced features
- **Nice-to-have completeness**

---

## 📋 Migration Template

For each new entity, follow this pattern:

### 1. Create Migration File

```sql
-- Example: 20250120000001_payments_table.sql
CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id),
  
  -- Payment details
  amount DECIMAL(10,2) NOT NULL,
  payment_method TEXT,
  payment_date TIMESTAMPTZ DEFAULT NOW(),
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 1
);

-- Indexes
CREATE INDEX idx_payments_shop ON payments(shop_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);

-- Trigger
CREATE TRIGGER payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- RLS
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Payments visible to shop members"
  ON payments FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);
```

### 2. Update Core Data Model

```swift
// Payment.swift
@NSManaged public var cloudSyncStatus: String?
```

### 3. Update Core Data XML

```xml
<!-- ProTech.xcdatamodel/contents -->
<entity name="Payment">
  <attribute name="cloudSyncStatus" optional="YES" attributeType="String"/>
  <!-- ... other attributes ... -->
</entity>
```

### 4. Create Syncer

```swift
// PaymentSyncer.swift
@MainActor
class PaymentSyncer: ObservableObject {
    // Follow pattern from CustomerSyncer.swift
    // - upload() method
    // - download() method
    // - uploadPendingChanges() method
    // - merge logic with conflict resolution
}
```

### 5. Update OfflineQueueManager

```swift
// Add to QueuedSyncOperationType enum
case uploadPayment(UUID)
case downloadPayments

// Add to executeOperation switch
case .uploadPayment(let id):
    guard let payment = try fetchPayment(id: id) else { return }
    try await paymentSyncer.upload(payment)
```

### 6. Update RealtimeManager

```swift
// Add syncer property
private let paymentSyncer = PaymentSyncer()

// Add to performSync()
async let payments = paymentSyncer.download()
```

---

## 🔍 Quick Reference

### Check Current Status

```bash
# List applied migrations
supabase db list-migrations

# Check table count
supabase db execute "SELECT count(*) FROM information_schema.tables 
  WHERE table_schema = 'public';"
```

### Apply Pending Migrations

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase db push
```

### Test Sync

```swift
// In Xcode console
Task {
    try await AppointmentSyncer.shared.download()
    print("Appointments synced!")
}
```

---

## 💡 Best Practices

### 1. Always Add These Fields
```sql
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()
deleted_at TIMESTAMPTZ  -- Soft deletes
sync_version INTEGER DEFAULT 1  -- Optimistic locking
```

### 2. Always Enable RLS
```sql
ALTER TABLE your_table ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Your policy" ON your_table ...;
```

### 3. Always Add Indexes
```sql
CREATE INDEX idx_table_shop ON table(shop_id);
CREATE INDEX idx_table_customer ON table(customer_id);
CREATE INDEX idx_table_date ON table(created_at);
```

### 4. Always Handle Soft Deletes
```sql
WHERE deleted_at IS NULL
```

### 5. Always Track Sync Status
```swift
entity.cloudSyncStatus = "pending"
entity.cloudSyncStatus = "synced"
entity.cloudSyncStatus = "failed"
```

---

## 🎉 Success Metrics

### Current State (11%)
- 5 entities synced
- 2 pending migrations

### Target State (65%)
- 30 entities synced
- All critical business operations
- Full multi-device support
- Real-time collaboration

### Timeline: 6 weeks
- Week 1: Apply pending (11% → 24%)
- Week 2-3: Financial (24% → 35%)
- Week 4: Time/Labor (35% → 41%)
- Week 5: Inventory/Marketing (41% → 52%)
- Week 6: Polish (52% → 65%)

---

## 🚀 Get Started

### Right Now (5 minutes)

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase db push
```

This instantly gives you:
- ✅ Appointments sync
- ✅ Full loyalty program (5 tables)
- ✅ 11 entities total (24% coverage)

### Next Steps

1. Test appointments and loyalty
2. Create Payments migration
3. Build PaymentSyncer
4. Repeat for Invoices & Estimates

**Goal**: 65% coverage in 6 weeks! 🎯
