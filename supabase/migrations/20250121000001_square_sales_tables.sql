-- ============================================
-- Square Sales Tables Migration
-- ============================================

CREATE TABLE IF NOT EXISTS public.square_orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  square_order_id TEXT NOT NULL,
  square_location_id TEXT,
  square_customer_id TEXT,

  reference_id TEXT,
  note TEXT,

  state TEXT,
  total_money_amount BIGINT,
  total_money_currency TEXT,

  raw_order JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  sync_version INTEGER DEFAULT 1,

  UNIQUE(shop_id, square_order_id)
);

CREATE INDEX IF NOT EXISTS idx_square_orders_shop_created_at
  ON square_orders(shop_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_square_orders_square_order_id
  ON square_orders(square_order_id);

CREATE TRIGGER square_orders_updated_at BEFORE UPDATE ON square_orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE square_orders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Square orders visible to shop members" ON square_orders;

CREATE POLICY "Square orders visible to shop members"
  ON square_orders FOR SELECT
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );

CREATE POLICY "Square orders insertable by shop members"
  ON square_orders FOR INSERT
  WITH CHECK (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );

CREATE POLICY "Square orders updatable by shop members"
  ON square_orders FOR UPDATE
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  )
  WITH CHECK (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );


CREATE TABLE IF NOT EXISTS public.square_terminal_checkouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,

  square_checkout_id TEXT NOT NULL,
  square_order_id TEXT,

  device_id TEXT,
  reference_id TEXT,
  note TEXT,

  status TEXT,
  payment_ids TEXT[],

  raw_checkout JSONB,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  sync_version INTEGER DEFAULT 1,

  UNIQUE(shop_id, square_checkout_id)
);

CREATE INDEX IF NOT EXISTS idx_square_terminal_checkouts_shop_created_at
  ON square_terminal_checkouts(shop_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_square_terminal_checkouts_square_checkout_id
  ON square_terminal_checkouts(square_checkout_id);

CREATE INDEX IF NOT EXISTS idx_square_terminal_checkouts_square_order_id
  ON square_terminal_checkouts(square_order_id);

CREATE TRIGGER square_terminal_checkouts_updated_at BEFORE UPDATE ON square_terminal_checkouts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE square_terminal_checkouts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Square terminal checkouts visible to shop members" ON square_terminal_checkouts;

CREATE POLICY "Square terminal checkouts visible to shop members"
  ON square_terminal_checkouts FOR SELECT
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );

CREATE POLICY "Square terminal checkouts insertable by shop members"
  ON square_terminal_checkouts FOR INSERT
  WITH CHECK (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );

CREATE POLICY "Square terminal checkouts updatable by shop members"
  ON square_terminal_checkouts FOR UPDATE
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  )
  WITH CHECK (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR shop_id = (
      SELECT shop_id
      FROM employees
      WHERE auth_user_id = auth.uid()
      LIMIT 1
    )
  );
