-- ============================================
-- ProTech Initial Schema Migration
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. SHOPS TABLE (Multi-tenancy)
-- ============================================
CREATE TABLE IF NOT EXISTS public.shops (
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
CREATE TABLE IF NOT EXISTS public.employees (
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
CREATE TABLE IF NOT EXISTS public.customers (
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
CREATE TABLE IF NOT EXISTS public.tickets (
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
CREATE TABLE IF NOT EXISTS public.inventory_items (
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
