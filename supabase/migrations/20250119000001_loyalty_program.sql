-- ============================================
-- Loyalty Program Schema Migration
-- ============================================

-- ============================================
-- 1. LOYALTY PROGRAMS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_programs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Configuration
  name TEXT NOT NULL DEFAULT 'Rewards Program',
  is_active BOOLEAN DEFAULT true,
  points_per_dollar DECIMAL(10,2) DEFAULT 1.0,
  points_per_visit INTEGER DEFAULT 10,
  enable_tiers BOOLEAN DEFAULT true,
  enable_auto_notifications BOOLEAN DEFAULT true,
  points_expiration_days INTEGER DEFAULT 0, -- 0 = never expire
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- One active program per shop
  UNIQUE(shop_id)
);

-- Indexes
CREATE INDEX idx_loyalty_programs_shop ON loyalty_programs(shop_id);

-- ============================================
-- 2. LOYALTY TIERS TABLE (VIP Levels)
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_tiers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id UUID NOT NULL REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Tier Details
  name TEXT NOT NULL,
  points_required INTEGER DEFAULT 0, -- Minimum lifetime points to reach tier
  points_multiplier DECIMAL(10,2) DEFAULT 1.0, -- 1.5 = 50% bonus, 2.0 = double
  color TEXT, -- Hex color for UI
  sort_order INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(program_id, name)
);

-- Indexes
CREATE INDEX idx_loyalty_tiers_program ON loyalty_tiers(program_id);
CREATE INDEX idx_loyalty_tiers_shop ON loyalty_tiers(shop_id);

-- ============================================
-- 3. LOYALTY MEMBERS TABLE (Customer Enrollments)
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  program_id UUID NOT NULL REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  current_tier_id UUID REFERENCES loyalty_tiers(id),
  
  -- Points Balances
  total_points INTEGER DEFAULT 0, -- Total points ever earned (including redeemed)
  available_points INTEGER DEFAULT 0, -- Current spendable balance
  lifetime_points INTEGER DEFAULT 0, -- All-time points earned (for tier calculation)
  
  -- Activity Metrics
  visit_count INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0.0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  enrolled_at TIMESTAMPTZ DEFAULT NOW(),
  last_activity_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  sync_version INTEGER DEFAULT 1,
  
  -- One membership per customer per program
  UNIQUE(customer_id, program_id)
);

-- Indexes
CREATE INDEX idx_loyalty_members_customer ON loyalty_members(customer_id);
CREATE INDEX idx_loyalty_members_program ON loyalty_members(program_id);
CREATE INDEX idx_loyalty_members_shop ON loyalty_members(shop_id);
CREATE INDEX idx_loyalty_members_tier ON loyalty_members(current_tier_id);
CREATE INDEX idx_loyalty_members_points ON loyalty_members(lifetime_points DESC);

-- ============================================
-- 4. LOYALTY REWARDS TABLE (Redeemable Rewards)
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  program_id UUID NOT NULL REFERENCES loyalty_programs(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Reward Details
  name TEXT NOT NULL,
  description TEXT,
  points_cost INTEGER NOT NULL,
  reward_type TEXT NOT NULL CHECK (reward_type IN ('discount_percent', 'discount_amount', 'free_item', 'custom')),
  reward_value DECIMAL(10,2) DEFAULT 0.0, -- Dollar amount or percentage
  
  -- Restrictions
  is_active BOOLEAN DEFAULT true,
  max_redemptions_per_customer INTEGER, -- NULL = unlimited
  valid_from TIMESTAMPTZ,
  valid_until TIMESTAMPTZ,
  
  -- Display
  sort_order INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_loyalty_rewards_program ON loyalty_rewards(program_id);
CREATE INDEX idx_loyalty_rewards_shop ON loyalty_rewards(shop_id);
CREATE INDEX idx_loyalty_rewards_active ON loyalty_rewards(is_active, points_cost);

-- ============================================
-- 5. LOYALTY TRANSACTIONS TABLE (Points History)
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  member_id UUID NOT NULL REFERENCES loyalty_members(id) ON DELETE CASCADE,
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  
  -- Transaction Details
  type TEXT NOT NULL CHECK (type IN ('earned', 'redeemed', 'expired', 'adjusted')),
  points INTEGER NOT NULL, -- Positive for earned, negative for redeemed/expired
  description TEXT,
  
  -- Related Records
  related_invoice_id UUID REFERENCES tickets(id), -- Link to ticket/invoice
  related_reward_id UUID REFERENCES loyalty_rewards(id),
  
  -- Expiration
  expires_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by UUID REFERENCES employees(id) -- For manual adjustments
);

-- Indexes
CREATE INDEX idx_loyalty_transactions_member ON loyalty_transactions(member_id);
CREATE INDEX idx_loyalty_transactions_shop ON loyalty_transactions(shop_id);
CREATE INDEX idx_loyalty_transactions_type ON loyalty_transactions(type);
CREATE INDEX idx_loyalty_transactions_date ON loyalty_transactions(created_at DESC);

-- ============================================
-- 6. LOYALTY REFERRALS TABLE (New Feature)
-- ============================================
CREATE TABLE IF NOT EXISTS public.loyalty_referrals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  referrer_member_id UUID NOT NULL REFERENCES loyalty_members(id) ON DELETE CASCADE,
  referred_customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
  
  -- Referral Details
  referral_code TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired')),
  points_awarded INTEGER DEFAULT 0,
  
  -- Dates
  referred_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ, -- When referred customer makes first purchase
  
  UNIQUE(shop_id, referral_code),
  UNIQUE(shop_id, referred_customer_id) -- One referral per customer
);

-- Indexes
CREATE INDEX idx_loyalty_referrals_referrer ON loyalty_referrals(referrer_member_id);
CREATE INDEX idx_loyalty_referrals_code ON loyalty_referrals(referral_code);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

ALTER TABLE loyalty_programs ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_referrals ENABLE ROW LEVEL SECURITY;

-- Programs: Shop isolation
CREATE POLICY loyalty_programs_shop_isolation ON loyalty_programs
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- Tiers: Shop isolation
CREATE POLICY loyalty_tiers_shop_isolation ON loyalty_tiers
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- Members: Shop isolation
CREATE POLICY loyalty_members_shop_isolation ON loyalty_members
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- Rewards: Shop isolation
CREATE POLICY loyalty_rewards_shop_isolation ON loyalty_rewards
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- Transactions: Shop isolation
CREATE POLICY loyalty_transactions_shop_isolation ON loyalty_transactions
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- Referrals: Shop isolation
CREATE POLICY loyalty_referrals_shop_isolation ON loyalty_referrals
  FOR ALL USING (shop_id = (auth.jwt() -> 'user_metadata' ->> 'shop_id')::uuid);

-- ============================================
-- TRIGGERS: Auto-update timestamps
-- ============================================

CREATE TRIGGER update_loyalty_programs_updated_at
  BEFORE UPDATE ON loyalty_programs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_loyalty_rewards_updated_at
  BEFORE UPDATE ON loyalty_rewards
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_loyalty_members_updated_at
  BEFORE UPDATE ON loyalty_members
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- FUNCTIONS: Points expiration cleanup
-- ============================================

CREATE OR REPLACE FUNCTION expire_loyalty_points()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Find expired transactions
  INSERT INTO loyalty_transactions (member_id, shop_id, type, points, description, created_at)
  SELECT 
    lt.member_id,
    lm.shop_id,
    'expired',
    -lt.points, -- Negative to deduct
    'Points expired',
    NOW()
  FROM loyalty_transactions lt
  JOIN loyalty_members lm ON lm.id = lt.member_id
  WHERE lt.type = 'earned'
    AND lt.expires_at IS NOT NULL
    AND lt.expires_at < NOW()
    AND NOT EXISTS (
      -- Check if already expired
      SELECT 1 FROM loyalty_transactions
      WHERE member_id = lt.member_id
        AND type = 'expired'
        AND related_invoice_id = lt.related_invoice_id
    );
  
  -- Update member available points
  UPDATE loyalty_members lm
  SET available_points = (
    SELECT COALESCE(SUM(points), 0)
    FROM loyalty_transactions
    WHERE member_id = lm.id
  );
END;
$$;

-- ============================================
-- FUNCTIONS: Tier auto-upgrade
-- ============================================

CREATE OR REPLACE FUNCTION check_tier_upgrade()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_new_tier_id UUID;
  v_program_id UUID;
BEGIN
  -- Get member's program
  SELECT program_id INTO v_program_id
  FROM loyalty_members
  WHERE id = NEW.member_id;
  
  -- Find highest tier member qualifies for
  SELECT id INTO v_new_tier_id
  FROM loyalty_tiers
  WHERE program_id = v_program_id
    AND points_required <= (
      SELECT lifetime_points
      FROM loyalty_members
      WHERE id = NEW.member_id
    )
  ORDER BY points_required DESC
  LIMIT 1;
  
  -- Update member's tier if changed
  IF v_new_tier_id IS NOT NULL THEN
    UPDATE loyalty_members
    SET current_tier_id = v_new_tier_id,
        updated_at = NOW()
    WHERE id = NEW.member_id
      AND (current_tier_id IS NULL OR current_tier_id != v_new_tier_id);
  END IF;
  
  RETURN NEW;
END;
$$;

-- Trigger tier check after points transaction
CREATE TRIGGER loyalty_transaction_tier_check
  AFTER INSERT ON loyalty_transactions
  FOR EACH ROW
  WHEN (NEW.type = 'earned')
  EXECUTE FUNCTION check_tier_upgrade();

-- ============================================
-- FUNCTIONS: Update member points
-- ============================================

CREATE OR REPLACE FUNCTION update_member_points()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  -- Update member's points balances
  UPDATE loyalty_members
  SET 
    total_points = total_points + NEW.points,
    available_points = CASE
      WHEN NEW.type IN ('earned', 'adjusted') AND NEW.points > 0 
        THEN available_points + NEW.points
      WHEN NEW.type IN ('redeemed', 'expired', 'adjusted') AND NEW.points < 0
        THEN available_points + NEW.points -- Adding negative = subtracting
      ELSE available_points
    END,
    lifetime_points = CASE
      WHEN NEW.type = 'earned' OR (NEW.type = 'adjusted' AND NEW.points > 0)
        THEN lifetime_points + NEW.points
      ELSE lifetime_points
    END,
    last_activity_at = NOW(),
    updated_at = NOW()
  WHERE id = NEW.member_id;
  
  RETURN NEW;
END;
$$;

-- Trigger to update member points after transaction
CREATE TRIGGER loyalty_transaction_update_points
  AFTER INSERT ON loyalty_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_member_points();

-- ============================================
-- INDEXES for Performance
-- ============================================

-- Composite index for common member queries
CREATE INDEX idx_loyalty_members_active_points 
  ON loyalty_members(shop_id, is_active, lifetime_points DESC)
  WHERE is_active = true;

-- Index for transaction history lookups
CREATE INDEX idx_loyalty_transactions_member_date
  ON loyalty_transactions(member_id, created_at DESC);

-- Index for reward redemption queries
CREATE INDEX idx_loyalty_rewards_available
  ON loyalty_rewards(program_id, is_active, points_cost)
  WHERE is_active = true;

COMMENT ON TABLE loyalty_programs IS 'Loyalty program configuration per shop';
COMMENT ON TABLE loyalty_tiers IS 'VIP tier levels with point multipliers';
COMMENT ON TABLE loyalty_members IS 'Customer enrollments in loyalty programs';
COMMENT ON TABLE loyalty_rewards IS 'Redeemable rewards catalog';
COMMENT ON TABLE loyalty_transactions IS 'Points earning and redemption history';
COMMENT ON TABLE loyalty_referrals IS 'Customer referral tracking';
