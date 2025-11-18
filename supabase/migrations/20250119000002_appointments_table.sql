-- ============================================
-- Appointments Table Migration
-- ============================================

-- Create appointments table
CREATE TABLE IF NOT EXISTS public.appointments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
  ticket_id UUID REFERENCES tickets(id) ON DELETE SET NULL,
  
  -- Appointment details
  appointment_type TEXT NOT NULL CHECK (appointment_type IN ('dropoff', 'pickup', 'consultation', 'repair')),
  scheduled_date TIMESTAMPTZ NOT NULL,
  duration INTEGER NOT NULL DEFAULT 30, -- in minutes
  
  -- Status tracking
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'completed', 'cancelled', 'no_show')),
  
  -- Notes and details
  notes TEXT,
  
  -- Notification tracking
  reminder_sent BOOLEAN DEFAULT false,
  confirmation_sent BOOLEAN DEFAULT false,
  
  -- Completion tracking
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ, -- Soft delete
  sync_version INTEGER DEFAULT 1
);

-- ============================================
-- Indexes for Performance
-- ============================================

-- Primary lookups
CREATE INDEX idx_appointments_shop ON appointments(shop_id);
CREATE INDEX idx_appointments_customer ON appointments(customer_id);
CREATE INDEX idx_appointments_ticket ON appointments(ticket_id) WHERE ticket_id IS NOT NULL;

-- Date-based queries (most common)
CREATE INDEX idx_appointments_scheduled_date ON appointments(scheduled_date);
CREATE INDEX idx_appointments_shop_date ON appointments(shop_id, scheduled_date);

-- Status filtering
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_upcoming ON appointments(shop_id, scheduled_date, status) 
  WHERE status IN ('scheduled', 'confirmed') AND deleted_at IS NULL;

-- Today's appointments (dashboard widget optimization)
CREATE INDEX idx_appointments_today ON appointments(shop_id, scheduled_date) 
  WHERE DATE(scheduled_date) = CURRENT_DATE AND status != 'cancelled' AND deleted_at IS NULL;

-- Soft delete support
CREATE INDEX idx_appointments_deleted ON appointments(deleted_at) WHERE deleted_at IS NOT NULL;

-- ============================================
-- Trigger for Updated_at
-- ============================================

CREATE TRIGGER appointments_updated_at BEFORE UPDATE ON appointments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================
-- Row Level Security (RLS)
-- ============================================

ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Shop members can view their shop's appointments
CREATE POLICY "Appointments visible to shop members"
  ON appointments FOR SELECT
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Shop members can create appointments
CREATE POLICY "Shop members can create appointments"
  ON appointments FOR INSERT
  WITH CHECK (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Shop members can update their shop's appointments
CREATE POLICY "Shop members can update appointments"
  ON appointments FOR UPDATE
  USING (shop_id = (auth.jwt() ->> 'shop_id')::uuid);

-- Only admins/managers can delete (soft delete is preferred)
CREATE POLICY "Admins can delete appointments"
  ON appointments FOR DELETE
  USING (
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    AND (auth.jwt() ->> 'role') IN ('admin', 'manager')
  );

-- ============================================
-- Helper Functions
-- ============================================

-- Function to check for appointment conflicts
CREATE OR REPLACE FUNCTION check_appointment_conflict(
  p_shop_id UUID,
  p_scheduled_date TIMESTAMPTZ,
  p_duration INTEGER,
  p_exclude_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_end_time TIMESTAMPTZ;
  v_conflict_count INTEGER;
BEGIN
  v_end_time := p_scheduled_date + (p_duration || ' minutes')::INTERVAL;
  
  SELECT COUNT(*) INTO v_conflict_count
  FROM appointments
  WHERE shop_id = p_shop_id
    AND (id != p_exclude_id OR p_exclude_id IS NULL)
    AND status NOT IN ('cancelled', 'no_show')
    AND deleted_at IS NULL
    AND (
      -- New appointment starts during existing appointment
      (p_scheduled_date >= scheduled_date AND p_scheduled_date < scheduled_date + (duration || ' minutes')::INTERVAL)
      OR
      -- New appointment ends during existing appointment
      (v_end_time > scheduled_date AND v_end_time <= scheduled_date + (duration || ' minutes')::INTERVAL)
      OR
      -- New appointment completely overlaps existing appointment
      (p_scheduled_date <= scheduled_date AND v_end_time >= scheduled_date + (duration || ' minutes')::INTERVAL)
    );
  
  RETURN v_conflict_count > 0;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to get available time slots for a day
CREATE OR REPLACE FUNCTION get_available_time_slots(
  p_shop_id UUID,
  p_date DATE,
  p_duration INTEGER DEFAULT 30,
  p_start_hour INTEGER DEFAULT 9,
  p_end_hour INTEGER DEFAULT 17
)
RETURNS TABLE(time_slot TIMESTAMPTZ) AS $$
DECLARE
  v_current_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
BEGIN
  v_current_time := p_date + (p_start_hour || ' hours')::INTERVAL;
  v_end_time := p_date + (p_end_hour || ' hours')::INTERVAL;
  
  WHILE v_current_time < v_end_time LOOP
    IF NOT check_appointment_conflict(p_shop_id, v_current_time, p_duration) THEN
      time_slot := v_current_time;
      RETURN NEXT;
    END IF;
    v_current_time := v_current_time + (p_duration || ' minutes')::INTERVAL;
  END LOOP;
  
  RETURN;
END;
$$ LANGUAGE plpgsql STABLE;

-- ============================================
-- Statistics View
-- ============================================

CREATE OR REPLACE VIEW appointment_stats AS
SELECT 
  shop_id,
  COUNT(*) FILTER (WHERE status IN ('scheduled', 'confirmed') AND scheduled_date > NOW()) as upcoming_count,
  COUNT(*) FILTER (WHERE DATE(scheduled_date) = CURRENT_DATE AND status != 'cancelled') as today_count,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
  COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled_count,
  COUNT(*) FILTER (WHERE status = 'no_show') as no_show_count,
  AVG(duration) FILTER (WHERE status = 'completed') as avg_duration_minutes,
  MAX(scheduled_date) FILTER (WHERE status IN ('scheduled', 'confirmed')) as next_appointment
FROM appointments
WHERE deleted_at IS NULL
GROUP BY shop_id;

COMMENT ON VIEW appointment_stats IS 'Real-time appointment statistics per shop';
