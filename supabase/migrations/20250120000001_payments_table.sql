-- ============================================
-- Payments Table Migration
-- ============================================

CREATE TABLE IF NOT EXISTS public.payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
  
  -- Payment details
  payment_number TEXT,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0.0,
  payment_method TEXT CHECK (payment_method IN ('cash', 'card', 'check', 'transfer', 'other')),
  payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reference_number TEXT, -- Check number, transaction ID, etc.
  
  -- Receipt tracking
  receipt_generated BOOLEAN DEFAULT false,
  
  -- Notes
  notes TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ, -- Soft delete
  sync_version INTEGER DEFAULT 1
);

-- ============================================
-- Indexes for Performance
-- ============================================

CREATE INDEX idx_payments_shop ON payments(shop_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_payments_invoice ON payments(invoice_id) WHERE invoice_id IS NOT NULL;
CREATE INDEX idx_payments_date ON payments(payment_date DESC);
CREATE INDEX idx_payments_shop_date ON payments(shop_id, payment_date DESC);
CREATE INDEX idx_payments_method ON payments(payment_method);
CREATE INDEX idx_payments_deleted ON payments(deleted_at) WHERE deleted_at IS NOT NULL;

-- Composite index for financial reports
CREATE INDEX idx_payments_shop_date_method ON payments(shop_id, payment_date, payment_method)
  WHERE deleted_at IS NULL;

-- ============================================
-- Trigger for Updated_at
-- ============================================

CREATE TRIGGER payments_updated_at BEFORE UPDATE ON payments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Row Level Security (RLS)
-- ============================================

ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Shop members can view their shop's payments
CREATE POLICY "Payments visible to shop members"
  ON payments FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Shop members can create payments
CREATE POLICY "Shop members can create payments"
  ON payments FOR INSERT
  WITH CHECK (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Shop members can update their shop's payments
CREATE POLICY "Shop members can update payments"
  ON payments FOR UPDATE
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Only admins/managers can delete payments
CREATE POLICY "Admins can delete payments"
  ON payments FOR DELETE
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    AND (auth.jwt() ->> 'role') IN ('admin', 'manager')
  );

-- ============================================
-- Helper Functions
-- ============================================

-- Function to get payment statistics
CREATE OR REPLACE FUNCTION get_payment_stats(
  p_shop_id UUID,
  p_start_date TIMESTAMPTZ DEFAULT NULL,
  p_end_date TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE(
  total_payments BIGINT,
  total_amount DECIMAL,
  cash_amount DECIMAL,
  card_amount DECIMAL,
  check_amount DECIMAL,
  transfer_amount DECIMAL,
  other_amount DECIMAL
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::BIGINT as total_payments,
    COALESCE(SUM(amount), 0) as total_amount,
    COALESCE(SUM(amount) FILTER (WHERE payment_method = 'cash'), 0) as cash_amount,
    COALESCE(SUM(amount) FILTER (WHERE payment_method = 'card'), 0) as card_amount,
    COALESCE(SUM(amount) FILTER (WHERE payment_method = 'check'), 0) as check_amount,
    COALESCE(SUM(amount) FILTER (WHERE payment_method = 'transfer'), 0) as transfer_amount,
    COALESCE(SUM(amount) FILTER (WHERE payment_method = 'other'), 0) as other_amount
  FROM payments
  WHERE shop_id = p_shop_id
    AND deleted_at IS NULL
    AND (p_start_date IS NULL OR payment_date >= p_start_date)
    AND (p_end_date IS NULL OR payment_date <= p_end_date);
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- Statistics View
-- ============================================

CREATE OR REPLACE VIEW payment_stats AS
SELECT 
  shop_id,
  COUNT(*) as total_payments,
  SUM(amount) as total_amount,
  SUM(amount) FILTER (WHERE payment_date::date = CURRENT_DATE) as today_amount,
  SUM(amount) FILTER (WHERE payment_date >= date_trunc('week', CURRENT_DATE)) as week_amount,
  SUM(amount) FILTER (WHERE payment_date >= date_trunc('month', CURRENT_DATE)) as month_amount,
  SUM(amount) FILTER (WHERE payment_method = 'cash') as cash_total,
  SUM(amount) FILTER (WHERE payment_method = 'card') as card_total,
  SUM(amount) FILTER (WHERE payment_method = 'check') as check_total,
  AVG(amount) as avg_payment_amount,
  MAX(payment_date) as last_payment_date
FROM payments
WHERE deleted_at IS NULL
GROUP BY shop_id;

COMMENT ON TABLE payments IS 'Payment records for invoices and tickets';
COMMENT ON VIEW payment_stats IS 'Real-time payment statistics per shop';
