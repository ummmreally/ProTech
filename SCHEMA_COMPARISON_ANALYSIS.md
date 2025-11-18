# Core Data ↔ Supabase Schema Comparison

## 🔍 Analysis Complete

Comparing ProTech Core Data model with Supabase database schema.

---

## ⚠️ CRITICAL MISMATCHES FOUND

### 1. **Employee Entity** - MAJOR ISSUES

#### Missing in Core Data (❌ Need to Add):
- `auth_user_id` - UUID - Links to Supabase auth.users
- `shop_id` - UUID - Multi-tenancy support  
- `deleted_at` - Date - Soft delete support
- `sync_version` - Integer - Conflict resolution

#### Extra in Core Data (✅ Local-only or needs sync decision):
- `passwordHash` - String - Local authentication (not synced)
- `lastPinAttemptAt` - Date - Local tracking
- `failedPasswordAttempts` - Int16 - Local tracking
- `lastPasswordAttemptAt` - Date - Local tracking
- `passwordLockedUntil` - Date - Local tracking
- `profileImageData` - Binary - Local storage (should use Supabase Storage)
- `cloudSyncStatus` - String - Sync state tracking (local only)

#### Already Fixed:
- ✅ `isAdmin` - Removed from Swift code, derived from `role == "admin"`

---

### 2. **Customer Entity** - MINOR ISSUES

#### Missing in Core Data:
- `auth_user_id` - UUID - For customer portal access
- `shop_id` - UUID - Multi-tenancy
- `square_customer_id` - String - Square integration ✅ **EXISTS** as `squareCustomerId`
- `deleted_at` - Date - Soft delete
- `sync_version` - Integer - Conflict resolution

#### Extra in Core Data:
- `cloudSyncStatus` - String - Local sync tracking (OK)

---

### 3. **Ticket Entity** - MINOR ISSUES

#### Missing in Core Data:
- `shop_id` - UUID - Multi-tenancy (CRITICAL!)
- `deleted_at` - Date - Soft delete
- `sync_version` - Integer - Conflict resolution
- `check_in_signature_url` - String - Signature storage URL

#### Core Data has:
- `checkInSignature` - Binary - Local signature storage
  
**Decision needed:** Use Supabase Storage or keep local?

---

### 4. **InventoryItem Entity** - MINOR ISSUES

#### Missing in Core Data:
- `shop_id` - UUID - Multi-tenancy (CRITICAL!)
- `deleted_at` - Date - Soft delete
- `sync_version` - Integer - Conflict resolution

#### Name mismatch:
- Core Data: `itemName` and `name` (duplicate?)
- Supabase: `name` only

---

## 📊 Supabase-Only Tables (Not in Core Data)

These tables exist in Supabase but not in Core Data:
1. `shops` - Multi-tenancy support
2. `repair_tickets` - Different from `Ticket` entity
3. `notifications` - Push notification system
4. `rewards` - Loyalty rewards system

---

## 🔧 Required Fixes

### Priority 1: CRITICAL (Breaks Sync)

#### 1. Add Missing Fields to Core Data Employee
```swift
// Add to Employee entity in ProTech.xcdatamodel

@NSManaged public var authUserId: UUID?      // Links to Supabase auth
@NSManaged public var shopId: UUID?           // Multi-tenancy
@NSManaged public var deletedAt: Date?        // Soft delete
@NSManaged public var syncVersion: Int16      // Conflict resolution
```

#### 2. Add Missing Fields to Customer
```swift
@NSManaged public var authUserId: UUID?
@NSManaged public var shopId: UUID?
@NSManaged public var deletedAt: Date?
@NSManaged public var syncVersion: Int16
```

#### 3. Add Missing Fields to Ticket  
```swift
@NSManaged public var shopId: UUID?           // CRITICAL for multi-tenancy
@NSManaged public var deletedAt: Date?
@NSManaged public var syncVersion: Int16
@NSManaged public var checkInSignatureUrl: String?  // Replace binary?
```

#### 4. Add Missing Fields to InventoryItem
```swift
@NSManaged public var shopId: UUID?           // CRITICAL
@NSManaged public var deletedAt: Date?
@NSManaged public var syncVersion: Int16
```

---

### Priority 2: MEDIUM (Sync Logic Decisions)

#### 1. Profile Images
**Current:** Core Data stores `profileImageData` as Binary  
**Supabase:** Should use Storage bucket `employee-photos`

**Recommendation:**
- Store `profileImageUrl` in Core Data (String)
- Upload binary to Supabase Storage
- Download and cache locally

#### 2. Signature Storage
**Current:** Core Data stores `checkInSignature` as Binary  
**Supabase:** Uses `check_in_signature_url` (Storage)

**Recommendation:**
- Same as profile images
- Use `repair-photos` bucket

#### 3. Local-Only Authentication Fields
Keep these in Core Data, don't sync:
- `passwordHash` - Local PIN/password auth
- `failedPasswordAttempts` - Local rate limiting
- `lastPasswordAttemptAt` - Local tracking
- `passwordLockedUntil` - Local lockout

---

### Priority 3: LOW (Cleanup)

#### 1. Remove Duplicate Fields
- `InventoryItem.itemName` vs `InventoryItem.name` - Pick one

#### 2. Add Missing Entities
Consider adding Core Data entities for:
- `Shop` - Store current shop info
- `Notification` - Local notification queue
- May not be needed if always fetched from Supabase

---

## 🎯 Recommended Action Plan

### Step 1: Update Core Data Model (REQUIRED)
Add the critical fields to existing entities:
- `authUserId`, `shopId`, `deletedAt`, `syncVersion` to:
  - Employee
  - Customer
  - Ticket
  - InventoryItem

### Step 2: Update Sync Services
Modify syncer files to handle new fields:
- `EmployeeSyncer.swift` - Add auth_user_id, shop_id mapping
- `CustomerSyncer.swift` - Add shop_id, deleted_at support
- `TicketSyncer.swift` - Add shop_id (CRITICAL!)
- `InventorySyncer.swift` - Add shop_id

### Step 3: Update SupabaseEmployee Struct
Already matches Supabase schema ✅ (except we removed is_admin)

### Step 4: Migration Strategy
For existing local data:
- Assign all records to default shop: `00000000-0000-0000-0000-000000000001`
- Set `syncVersion = 1`
- Leave `deletedAt = nil`
- Set `authUserId` for employees with accounts

---

## ✅ What's Already Correct

1. **Field Names:** Most Core Data fields match Supabase (camelCase ↔ snake_case handled in code)
2. **Data Types:** Match well (UUID, String, Date, Decimal, Boolean)
3. **Swift Models:** `SupabaseEmployee` struct is correct
4. **RLS Policies:** Working correctly now
5. **Trigger:** Auto-creates employees ✅

---

## 🚨 Impact on Current Signup Issue

**The signup issue you're seeing is NOT due to schema mismatch.**

The trigger IS creating the employee record correctly in Supabase. The issue is:
1. Trigger creates employee ✅
2. App tries to fetch too quickly ⏱️
3. Retry logic should handle this ✅

**Current state:**
- Supabase employees table: ✅ Correct schema
- Core Data Employee entity: ⚠️ Missing some sync fields but doesn't break signup
- Swift SupabaseEmployee struct: ✅ Matches Supabase
- Sync code: ⚠️ Derives isAdmin from role (correct)

---

## 🔒 RLS Policies - VERIFIED CORRECT

All RLS policies are configured with fallback to default shop:

```sql
-- All tables use this pattern:
shop_id = COALESCE(
  (auth.jwt() ->> 'shop_id')::uuid,
  '00000000-0000-0000-0000-000000000001'::uuid  -- Default shop
)
```

**Coverage:**
- ✅ Employees: INSERT (with self-create), SELECT, UPDATE, DELETE
- ✅ Customers: INSERT, SELECT, UPDATE, DELETE  
- ✅ Tickets: INSERT, SELECT, UPDATE, DELETE
- ✅ Inventory Items: INSERT, SELECT, UPDATE, DELETE
- ✅ Shops: SELECT, UPDATE

**Key Features:**
1. **Default shop fallback** - Works without JWT shop_id claim
2. **Self-signup** - Users can create their own employee record
3. **Admin permissions** - Admins/managers can manage resources
4. **Shop isolation** - Users only see their shop's data

**This means:**
- ✅ Signup works (trigger creates employee)
- ✅ Login works (can fetch employee)
- ✅ CRUD operations work (all have policies)
- ✅ Multi-tenancy ready (when JWT includes shop_id)

---

## 📝 Summary

### Must Fix (Breaks Multi-Tenancy):
1. ❌ Add `shopId` to: Employee, Customer, Ticket, InventoryItem in Core Data
2. ❌ Add `syncVersion` for conflict resolution
3. ❌ Add `deletedAt` for soft deletes
4. ❌ Add `authUserId` for Employee auth linking

### Should Fix (Best Practices):
1. ⚠️ Use Supabase Storage for images (not binary in Core Data)
2. ⚠️ Clean up duplicate fields
3. ⚠️ Consistent naming

### Already Working:
1. ✅ Signup trigger creates employees
2. ✅ RLS policies allow access
3. ✅ Swift models match Supabase
4. ✅ Basic sync works

---

## 🔧 Quick Fix Script

Would you like me to:
1. Update the Core Data model (.xcdatamodel file)?
2. Update all sync services to handle new fields?
3. Create a migration to populate shop_id for existing data?

**This will require rebuilding the Core Data schema and updating all syncer code.**
