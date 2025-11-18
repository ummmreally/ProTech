# 📊 Supabase Sync Gap Analysis

**Date**: November 18, 2024  
**Purpose**: Identify entities that need Supabase sync for multi-device support

---

## ✅ Currently Syncing (5/5 Complete)

| Entity | Syncer | Core Data | Supabase Table | Status |
|--------|--------|-----------|----------------|--------|
| Customer | ✅ | ✅ | `customers` | **COMPLETE** |
| Ticket/Repair | ✅ | ✅ | `tickets` | **COMPLETE** |
| InventoryItem | ✅ | ✅ | `inventory_items` | **COMPLETE** |
| Employee | ✅ | ✅ | `employees` | **COMPLETE** |
| Appointment | ✅ | ✅ | ⚠️ **MIGRATION PENDING** | **NEEDS MIGRATION** |

---

## 🔴 HIGH PRIORITY - Business Critical Entities

These need sync for normal business operations across devices:

### 1. **Appointments** 🗓️
- **Status**: Syncer exists, Core Data model ready, **Migration file exists but NOT applied**
- **Impact**: Can't see appointments across devices
- **Migration**: `/supabase/migrations/20250119000002_appointments_table.sql`
- **Action Required**:
  ```bash
  # Apply migration
  supabase db push
  ```

### 2. **Payments** 💰
- **Status**: No syncer, no Supabase table
- **Impact**: Payment records not shared across devices
- **Frequency**: High (every transaction)
- **Needs**:
  - Create migration: `payments` table
  - Create `PaymentSyncer.swift`
  - Add `cloudSyncStatus` to Core Data model

### 3. **Invoices** 📄
- **Status**: No syncer, no Supabase table
- **Impact**: Can't access invoices on different devices
- **Frequency**: High
- **Needs**:
  - Create migration: `invoices` table
  - Create `InvoiceSyncer.swift`
  - Add `cloudSyncStatus` to Core Data model
  - Sync child entity: `InvoiceLineItem`

### 4. **Estimates** 📋
- **Status**: No syncer, no Supabase table
- **Impact**: Can't share quotes across devices
- **Frequency**: High
- **Needs**:
  - Create migration: `estimates` table
  - Create `EstimateSyncer.swift`
  - Add `cloudSyncStatus` to Core Data model
  - Sync child entity: `EstimateLineItem`

### 5. **Time Tracking** ⏱️
- **Entities**: `TimeEntry`, `TimeClockEntry`
- **Status**: No syncer, no Supabase table
- **Impact**: Employee time tracking not visible across devices
- **Frequency**: Daily
- **Needs**:
  - Create migrations: `time_entries`, `time_clock_entries` tables
  - Create `TimeTrackingSyncer.swift`
  - Add `cloudSyncStatus` to both models

---

## 🟡 MEDIUM PRIORITY - Enhanced Features

### 6. **Loyalty Program** 🎁
- **Status**: Syncer exists, **Migration file exists but NOT applied**
- **Entities**: `LoyaltyProgram`, `LoyaltyTier`, `LoyaltyMember`, `LoyaltyReward`, `LoyaltyTransaction`
- **Impact**: Customer loyalty data not synced
- **Migration**: `/supabase/migrations/20250119000001_loyalty_program.sql`
- **Action Required**:
  ```bash
  # Apply migration
  supabase db push
  ```

### 7. **Forms System** 📝
- **Entities**: `FormTemplate`, `FormSubmission`
- **Status**: No syncer, no Supabase table
- **Impact**: Custom forms not shared across devices
- **Needs**:
  - Create migrations
  - Create `FormsSyncer.swift`
  - Add `cloudSyncStatus` to models

### 8. **Purchase Orders** 📦
- **Status**: No syncer, no Supabase table
- **Impact**: Inventory ordering not synced
- **Needs**:
  - Create migration
  - Create `PurchaseOrderSyncer.swift`
  - Add `cloudSyncStatus` to model

### 9. **Check-Ins** 📥
- **Status**: No syncer, no Supabase table (separate from Ticket check-in)
- **Impact**: Queue management not synced
- **Needs**:
  - Evaluate if needed (might be replaced by Tickets)

---

## 🟢 LOW PRIORITY - Supporting/Internal Entities

### 10. **Repair Details**
- **Entities**: `RepairProgress`, `RepairStageRecord`, `RepairPartUsage`
- **Status**: No syncer, no table
- **Impact**: Detailed repair tracking not synced
- **Note**: May be embedded in `Ticket` as JSON for simplicity

### 11. **Ticket Notes**
- **Status**: No syncer, no table
- **Impact**: Technician notes not synced
- **Note**: Consider adding `notes` array to `tickets` table as JSONB

### 12. **SMS Messages**
- **Status**: No syncer, no table
- **Impact**: Message history not synced
- **Note**: May not need sync (can query Twilio API)

### 13. **Notifications**
- **Status**: Table exists in Supabase, but no syncer
- **Impact**: Notification history not in local app
- **Note**: May be push-only (no need for local storage)

---

## ❌ DO NOT SYNC - Local/Config Only

These should stay local:

- **SquareConfiguration** - API credentials (local only)
- **SquareSyncMapping** - Local sync state
- **SyncLog** - Local debugging logs

---

## 📋 Implementation Checklist

### Immediate Actions (Required for Basic Multi-Device)

- [ ] **Apply Appointments Migration**
  ```bash
  cd /Users/swiezytv/Documents/Unknown/ProTech
  supabase db push
  ```
  
- [ ] **Apply Loyalty Migration**
  ```bash
  # Same command - will apply all pending migrations
  supabase db push
  ```

### High Priority (Phase 1 - Financial)

- [ ] **Payments Sync**
  - [ ] Create migration
  - [ ] Create `PaymentSyncer.swift`
  - [ ] Add `cloudSyncStatus` to model
  - [ ] Update `OfflineQueueManager`
  - [ ] Add to `RealtimeManager`

- [ ] **Invoices Sync**
  - [ ] Create migration (with `invoice_line_items`)
  - [ ] Create `InvoiceSyncer.swift`
  - [ ] Add `cloudSyncStatus` to model
  - [ ] Update `OfflineQueueManager`
  - [ ] Add to `RealtimeManager`

- [ ] **Estimates Sync**
  - [ ] Create migration (with `estimate_line_items`)
  - [ ] Create `EstimateSyncer.swift`
  - [ ] Add `cloudSyncStatus` to model
  - [ ] Update `OfflineQueueManager`
  - [ ] Add to `RealtimeManager`

### Medium Priority (Phase 2 - Operations)

- [ ] **Time Tracking Sync**
  - [ ] Create migrations
  - [ ] Create `TimeTrackingSyncer.swift`
  - [ ] Add `cloudSyncStatus` to models
  - [ ] Update managers

- [ ] **Forms Sync**
  - [ ] Create migrations
  - [ ] Create `FormsSyncer.swift`
  - [ ] Add `cloudSyncStatus` to models

- [ ] **Purchase Orders Sync**
  - [ ] Create migration
  - [ ] Create `PurchaseOrderSyncer.swift`
  - [ ] Add `cloudSyncStatus` to model

### Low Priority (Phase 3 - Nice-to-Have)

- [ ] Evaluate: RepairProgress, Notes, SMS history
- [ ] Consider: Embed in parent entities vs separate sync

---

## 🎯 Recommended Implementation Order

### Week 1: Apply Pending Migrations
1. Run `supabase db push` to apply:
   - Appointments table ✅
   - Loyalty program tables ✅
2. Test existing AppointmentSyncer
3. Test existing LoyaltySyncer

### Week 2: Financial Entities
1. Payments (highest financial impact)
2. Invoices (with line items)
3. Estimates (with line items)

### Week 3: Time & Forms
1. Time tracking (employee feature request)
2. Forms system (custom workflows)

### Week 4: Polish & Optimize
1. Purchase orders
2. Performance optimization
3. Conflict resolution testing

---

## 📊 Migration Status Summary

| Migration File | Status | Action |
|---------------|--------|--------|
| `20250116000001_initial_schema.sql` | ✅ Applied | - |
| `20250117000001_performance_optimizations.sql` | ✅ Applied | - |
| `20250118000001_fix_employee_signup_rls.sql` | ✅ Applied | - |
| `20250118000002_disable_email_confirmation.sql` | ✅ Applied | - |
| `20250119000001_loyalty_program.sql` | ⚠️ **PENDING** | **RUN NOW** |
| `20250119000002_appointments_table.sql` | ⚠️ **PENDING** | **RUN NOW** |

---

## 🚀 Quick Start Command

To apply all pending migrations:

```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase db push
```

This will apply:
- ✅ Appointments table
- ✅ Loyalty program tables (programs, tiers, members, rewards, transactions)

Then test:
```bash
# In Xcode, restart the app
# Verify appointments sync
# Verify loyalty features work
```

---

## 💡 Architecture Notes

### Parent-Child Relationships

**Invoices → InvoiceLineItems**
- Sync parent first
- Then sync children with `invoice_id` foreign key
- Delete children when parent deleted

**Estimates → EstimateLineItems**
- Same pattern as Invoices

**Tickets → RepairProgress/Notes**
- Consider: Embed as JSONB in ticket
- Or: Separate tables with sync

### Conflict Resolution

All new entities should follow the same pattern:
1. `cloudSyncStatus` field (local, pending, synced, failed)
2. `sync_version` field in Supabase (optimistic locking)
3. `updated_at` timestamp (last-write-wins)
4. Offline queue support
5. Real-time subscription

---

## 📈 Impact Analysis

### Current Coverage: 5/24 entities (21%)

**Synced**: Customer, Ticket, Inventory, Employee, Appointment (with migration)

**Missing Critical**: Payments, Invoices, Estimates, Time Tracking (17% of critical features)

**Total Potential**: 24 entities (some should stay local)

**Realistic Target**: 15 entities (63% coverage)

---

## ✅ Next Steps

1. **Immediate (Today)**:
   ```bash
   supabase db push  # Apply appointments & loyalty
   ```

2. **This Week**:
   - Create Payments migration & syncer
   - Create Invoices migration & syncer

3. **Next Week**:
   - Estimates sync
   - Time tracking sync

4. **Future**:
   - Forms, Purchase Orders, polish

---

**Priority**: Apply pending migrations FIRST, then implement financial entity sync.

**Goal**: 80% of business operations synced within 2 weeks.
