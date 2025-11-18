# Supabase Integration Quick Start Guide
## ProTech - Immediate Action Items

> **⚡ Start here to begin Supabase integration**

---

## 🎯 Week 1 Priorities

### Day 1-2: Project Setup & Schema Design

#### 1. Verify Supabase Project
Your existing project:
- **URL:** `https://ucpgsubidqbhxstgykyt.supabase.co`
- **Project:** TechMedics
- **Status:** ⚠️ Needs schema setup

**Actions:**
```bash
# Install Supabase CLI
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link to existing project
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase link --project-ref ucpgsubidqbhxstgykyt

# Pull current schema (if any)
supabase db pull
```

#### 2. Create Base Schema Migration

**File:** `supabase/migrations/20250115000001_initial_schema.sql`

```sql
-- ============================================
-- ProTech Initial Schema Migration
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. SHOPS TABLE (Multi-tenancy)
-- ============================================
CREATE TABLE public.shops (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  address TEXT,
  
  -- Subscription management
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
  subscription_expires_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. EMPLOYEES TABLE
-- ============================================
CREATE TABLE public.employees (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Authentication (Supabase Auth user_id)
  auth_user_id UUID REFERENCES auth.users(id),
  
  -- Profile
  employee_number TEXT,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  phone TEXT,
  
  -- Role & Permissions
  role TEXT NOT NULL DEFAULT 'technician' CHECK (role IN ('admin', 'manager', 'technician', 'receptionist')),
  is_admin BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  
  -- Employment
  hourly_rate DECIMAL(10,2) DEFAULT 25.0,
  hire_date DATE,
  
  -- Quick PIN auth (for kiosk mode)
  pin_code TEXT, -- Hashed
  failed_pin_attempts INTEGER DEFAULT 0,
  pin_locked_until TIMESTAMPTZ,
  
  -- Activity
  last_login_at TIMESTAMPTZ,
  
  -- Sync metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ, -- Soft delete
  sync_version INTEGER DEFAULT 1,
  
  UNIQUE(shop_id, email),
  UNIQUE(shop_id, employee_number)
);

-- Index for quick lookups
CREATE INDEX idx_employees_shop ON employees(shop_id);
CREATE INDEX idx_employees_email ON employees(email);
CREATE INDEX idx_employees_auth_user ON employees(auth_user_id);

-- ============================================
-- 3. CUSTOMERS TABLE
-- ============================================
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Personal Info
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  
  -- Notes
  notes TEXT,
  
  -- External integrations
  square_customer_id TEXT, -- Square sync
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 1
);

-- Indexes
CREATE INDEX idx_customers_shop ON customers(shop_id);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_name ON customers(first_name, last_name);

-- Full-text search
CREATE INDEX idx_customers_search ON customers 
  USING gin(to_tsvector('english', 
    COALESCE(first_name, '') || ' ' || 
    COALESCE(last_name, '') || ' ' || 
    COALESCE(email, '') || ' ' || 
    COALESCE(phone, '')
  ));

-- ============================================
-- 4. TICKETS TABLE (Repair Tickets)
-- ============================================
CREATE TABLE public.tickets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  
  -- Ticket identification
  ticket_number INTEGER NOT NULL,
  
  -- Device info
  device_type TEXT,
  device_model TEXT,
  device_serial_number TEXT,
  device_passcode TEXT, -- Encrypted
  
  -- Repair details
  issue_description TEXT,
  additional_repair_details TEXT,
  notes TEXT,
  
  -- Status & Priority
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'waiting_parts', 'ready', 'completed', 'cancelled')),
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  
  -- Cost estimation
  estimated_cost DECIMAL(10,2) DEFAULT 0,
  actual_cost DECIMAL(10,2) DEFAULT 0,
  estimated_completion TIMESTAMPTZ,
  
  -- Check-in data
  find_my_disabled BOOLEAN DEFAULT false,
  has_data_backup BOOLEAN DEFAULT false,
  alternate_contact_name TEXT,
  alternate_contact_number TEXT,
  
  -- Marketing opt-ins
  marketing_opt_in_email BOOLEAN DEFAULT false,
  marketing_opt_in_sms BOOLEAN DEFAULT false,
  marketing_opt_in_mail BOOLEAN DEFAULT false,
  
  -- Timestamps
  checked_in_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  
  -- Agreement signature (stored in Storage)
  check_in_signature_url TEXT,
  check_in_agreed_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 1,
  
  UNIQUE(shop_id, ticket_number)
);

-- Indexes
CREATE INDEX idx_tickets_shop ON tickets(shop_id);
CREATE INDEX idx_tickets_customer ON tickets(customer_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_number ON tickets(shop_id, ticket_number);
CREATE INDEX idx_tickets_created ON tickets(created_at DESC);

-- ============================================
-- 5. INVENTORY_ITEMS TABLE
-- ============================================
CREATE TABLE public.inventory_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Item identification
  sku TEXT,
  part_number TEXT,
  name TEXT NOT NULL,
  category TEXT,
  
  -- Pricing
  cost DECIMAL(10,2) DEFAULT 0,
  price DECIMAL(10,2) DEFAULT 0,
  
  -- Stock
  quantity INTEGER DEFAULT 0,
  min_quantity INTEGER DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  sync_version INTEGER DEFAULT 1,
  
  UNIQUE(shop_id, sku)
);

-- Indexes
CREATE INDEX idx_inventory_shop ON inventory_items(shop_id);
CREATE INDEX idx_inventory_sku ON inventory_items(sku);
CREATE INDEX idx_inventory_low_stock ON inventory_items(shop_id, quantity) WHERE quantity <= min_quantity;

-- ============================================
-- TRIGGERS: Updated_at auto-update
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  NEW.sync_version = OLD.sync_version + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables
CREATE TRIGGER shops_updated_at BEFORE UPDATE ON shops
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER employees_updated_at BEFORE UPDATE ON employees
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER customers_updated_at BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tickets_updated_at BEFORE UPDATE ON tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER inventory_items_updated_at BEFORE UPDATE ON inventory_items
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;

-- Shops: Users can only see their own shop
CREATE POLICY "Users can view their shop"
  ON shops FOR SELECT
  USING (id = (auth.jwt() ->> 'shop_id')::uuid);

CREATE POLICY "Users can update their shop"
  ON shops FOR UPDATE
  USING (id = (auth.jwt() ->> 'shop_id')::uuid);

-- Employees: Shop isolation
CREATE POLICY "Employees visible to shop members"
  ON employees FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

CREATE POLICY "Admins can insert employees"
  ON employees FOR INSERT
  WITH CHECK (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    AND (auth.jwt() ->> 'role') IN ('admin', 'manager')
  );

CREATE POLICY "Admins can update employees"
  ON employees FOR UPDATE
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    AND (auth.jwt() ->> 'role') IN ('admin', 'manager')
  );

-- Customers: Shop isolation
CREATE POLICY "Customers visible to shop members"
  ON customers FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

CREATE POLICY "Shop members can manage customers"
  ON customers FOR ALL
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Tickets: Shop isolation
CREATE POLICY "Tickets visible to shop members"
  ON tickets FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

CREATE POLICY "Shop members can manage tickets"
  ON tickets FOR ALL
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Inventory: Shop isolation
CREATE POLICY "Inventory visible to shop members"
  ON inventory_items FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

CREATE POLICY "Shop members can manage inventory"
  ON inventory_items FOR ALL
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);
```

#### 3. Apply Migration

```bash
# Push migration to Supabase
supabase db push

# Verify tables created
supabase db diff
```

---

### Day 3-4: Storage Setup

#### 1. Create Storage Buckets

```sql
-- Create buckets via Supabase Dashboard or SQL
INSERT INTO storage.buckets (id, name, public)
VALUES 
  ('repair-photos', 'repair-photos', true),
  ('receipts', 'receipts', false),
  ('employee-photos', 'employee-photos', false);
```

#### 2. Storage Policies

```sql
-- repair-photos: Shop members can upload/view
CREATE POLICY "Shop members can upload repair photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'repair-photos'
    AND (auth.jwt() ->> 'shop_id') IS NOT NULL
  );

CREATE POLICY "Repair photos are publicly viewable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'repair-photos');
```

---

### Day 5: Authentication Setup

#### 1. Create Auth Hook for JWT Claims

**File:** `supabase/functions/auth-hook/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  try {
    const { user } = await req.json();
    
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );
    
    // Fetch employee data
    const { data: employee } = await supabase
      .from("employees")
      .select("shop_id, role")
      .eq("auth_user_id", user.id)
      .single();
    
    // Add custom claims to JWT
    return new Response(
      JSON.stringify({
        shop_id: employee?.shop_id,
        role: employee?.role,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }
});
```

Deploy:
```bash
supabase functions deploy auth-hook
```

---

## 🔧 Swift Integration Updates

### 1. Update SupabaseConfig.swift

```swift
enum SupabaseConfig {
    // Keep existing config
    static let supabaseURL = "https://ucpgsubidqbhxstgykyt.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    
    // Add new configs
    static let storageBuckets = (
        repairPhotos: "repair-photos",
        receipts: "receipts",
        employeePhotos: "employee-photos"
    )
    
    // JWT custom claims
    struct UserClaims: Codable {
        let shopId: UUID
        let role: String
        
        enum CodingKeys: String, CodingKey {
            case shopId = "shop_id"
            case role
        }
    }
}
```

### 2. Enhanced SupabaseService.swift

```swift
@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    @Published var currentShopId: UUID?
    @Published var currentRole: String?
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        // Listen for auth changes
        Task {
            await setupAuthListener()
        }
    }
    
    private func setupAuthListener() async {
        for await event in client.auth.authStateChanges {
            switch event {
            case .signedIn(let session):
                await extractClaims(from: session)
            case .signedOut:
                currentShopId = nil
                currentRole = nil
            default:
                break
            }
        }
    }
    
    private func extractClaims(from session: Session) async {
        do {
            let claims = try JSONDecoder().decode(
                SupabaseConfig.UserClaims.self,
                from: session.accessToken.data(using: .utf8)!
            )
            currentShopId = claims.shopId
            currentRole = claims.role
        } catch {
            print("Failed to extract JWT claims: \(error)")
        }
    }
}
```

### 3. Create CustomerSyncer (First Entity)

```swift
@MainActor
class CustomerSyncer: ObservableObject {
    private let supabase = SupabaseService.shared
    private let coreData = CoreDataManager.shared
    
    // Upload local customer to Supabase
    func upload(_ customer: Customer) async throws {
        guard let shopId = supabase.currentShopId else {
            throw SyncError.notAuthenticated
        }
        
        let supabaseCustomer = SupabaseCustomer(
            id: customer.id,
            shopId: shopId,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email,
            phone: customer.phone,
            address: customer.address,
            notes: customer.notes,
            squareCustomerId: customer.squareCustomerId,
            createdAt: customer.createdAt,
            updatedAt: customer.updatedAt,
            syncVersion: Int(customer.syncVersion)
        )
        
        try await supabase.client
            .from("customers")
            .upsert(supabaseCustomer)
            .execute()
        
        // Mark as synced
        customer.lastSyncedAt = Date()
        try coreData.viewContext.save()
    }
    
    // Download from Supabase and merge
    func download() async throws {
        guard let shopId = supabase.currentShopId else {
            throw SyncError.notAuthenticated
        }
        
        let remoteCustomers: [SupabaseCustomer] = try await supabase.client
            .from("customers")
            .select()
            .eq("shop_id", value: shopId)
            .execute()
            .value
        
        for remote in remoteCustomers {
            try await mergeOrCreate(remote)
        }
    }
    
    private func mergeOrCreate(_ remote: SupabaseCustomer) async throws {
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", remote.id as CVarArg)
        
        let results = try coreData.viewContext.fetch(request)
        
        if let local = results.first {
            // Conflict resolution: newest wins
            if remote.updatedAt > local.updatedAt ?? Date.distantPast {
                updateLocal(local, from: remote)
            }
        } else {
            // Create new
            createLocal(from: remote)
        }
        
        try coreData.viewContext.save()
    }
    
    private func updateLocal(_ local: Customer, from remote: SupabaseCustomer) {
        local.firstName = remote.firstName
        local.lastName = remote.lastName
        local.email = remote.email
        local.phone = remote.phone
        local.address = remote.address
        local.notes = remote.notes
        local.updatedAt = remote.updatedAt
        local.syncVersion = Int32(remote.syncVersion)
    }
    
    private func createLocal(from remote: SupabaseCustomer) {
        let customer = Customer(context: coreData.viewContext)
        customer.id = remote.id
        updateLocal(customer, from: remote)
        customer.createdAt = remote.createdAt
    }
}

// Supabase model
struct SupabaseCustomer: Codable {
    let id: UUID
    let shopId: UUID
    let firstName: String?
    let lastName: String?
    let email: String?
    let phone: String?
    let address: String?
    let notes: String?
    let squareCustomerId: String?
    let createdAt: Date
    let updatedAt: Date
    let syncVersion: Int
    
    enum CodingKeys: String, CodingKey {
        case id, firstName = "first_name", lastName = "last_name"
        case email, phone, address, notes
        case shopId = "shop_id"
        case squareCustomerId = "square_customer_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncVersion = "sync_version"
    }
}

enum SyncError: Error {
    case notAuthenticated
    case conflict
}
```

---

## 📋 Testing Checklist

### Database Tests
- [ ] Tables created successfully
- [ ] RLS policies prevent cross-shop access
- [ ] Triggers update `updated_at` and `sync_version`
- [ ] Indexes improve query performance

### Auth Tests
- [ ] User signup creates employee record
- [ ] JWT contains `shop_id` and `role` claims
- [ ] Sign out clears session

### Sync Tests
- [ ] Create customer locally → uploads to Supabase
- [ ] Create customer on Supabase → downloads to Core Data
- [ ] Update customer on both sides → resolves to newest
- [ ] Delete customer locally → soft deletes on Supabase

---

## 🚀 Quick Commands Reference

```bash
# Supabase CLI
supabase init                    # Initialize project
supabase start                   # Start local dev environment
supabase db push                 # Push migrations
supabase db reset                # Reset local database
supabase gen types swift         # Generate Swift types

# Database
supabase db diff                 # Show schema differences
supabase migration new <name>    # Create new migration
supabase db branches             # Manage branches

# Functions
supabase functions new <name>    # Create edge function
supabase functions deploy <name> # Deploy function
supabase functions logs <name>   # View logs

# Storage
supabase storage list            # List buckets
```

---

## 📚 Resources

- **Strategic Plan:** `SUPABASE_STRATEGIC_PLAN.md` (comprehensive roadmap)
- **Supabase Docs:** https://supabase.com/docs
- **Swift SDK:** https://github.com/supabase-community/supabase-swift
- **SQL Guide:** https://supabase.com/docs/guides/database

---

## ✅ Week 1 Success Criteria

By end of week, you should have:
- [x] Supabase project set up and linked
- [x] Base schema deployed (shops, employees, customers, tickets, inventory)
- [x] RLS policies configured
- [x] Storage buckets created
- [x] Auth hook deployed
- [x] `CustomerSyncer` implemented and tested
- [x] First successful sync: macOS → Supabase → macOS

**Next Week:** Implement remaining entity syncers (Tickets, Inventory, etc.)

---

*Created: January 2025*
*For: ProTech Mass Market Deployment*
