-- Performance Optimization Migration
-- Adds indexes, query optimizations, and monitoring for production

-- ============================================
-- PERFORMANCE INDEXES
-- ============================================

-- Customers table indexes
CREATE INDEX IF NOT EXISTS idx_customers_shop_email 
ON customers(shop_id, email) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_customers_shop_phone 
ON customers(shop_id, phone) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_customers_shop_name 
ON customers(shop_id, last_name, first_name) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_customers_created 
ON customers(shop_id, created_at DESC) 
WHERE deleted_at IS NULL;

-- Tickets table indexes
CREATE INDEX IF NOT EXISTS idx_tickets_shop_status 
ON tickets(shop_id, status) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_shop_customer 
ON tickets(shop_id, customer_id) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_shop_created 
ON tickets(shop_id, created_at DESC) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_tickets_shop_number 
ON tickets(shop_id, ticket_number) 
WHERE deleted_at IS NULL;

-- Inventory table indexes
CREATE INDEX IF NOT EXISTS idx_inventory_shop_sku 
ON inventory_items(shop_id, sku) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inventory_shop_category 
ON inventory_items(shop_id, category) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_inventory_low_stock 
ON inventory_items(shop_id, quantity, min_quantity) 
WHERE deleted_at IS NULL AND is_active = true;

-- Employees table indexes
CREATE INDEX IF NOT EXISTS idx_employees_shop_email 
ON employees(shop_id, email) 
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_employees_shop_role 
ON employees(shop_id, role) 
WHERE deleted_at IS NULL AND is_active = true;

CREATE INDEX IF NOT EXISTS idx_employees_auth_user 
ON employees(auth_user_id) 
WHERE deleted_at IS NULL;

-- ============================================
-- MATERIALIZED VIEWS FOR REPORTING
-- ============================================

-- Daily ticket statistics
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_daily_ticket_stats AS
SELECT 
    shop_id,
    DATE(created_at) as date,
    COUNT(*) as total_tickets,
    COUNT(*) FILTER (WHERE status = 'completed') as completed_tickets,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_tickets,
    COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_tickets,
    AVG(CASE 
        WHEN status = 'completed' AND completed_at IS NOT NULL 
        THEN EXTRACT(EPOCH FROM (completed_at - created_at))/3600 
        ELSE NULL 
    END) as avg_completion_hours
FROM tickets
WHERE deleted_at IS NULL
GROUP BY shop_id, DATE(created_at);

CREATE INDEX idx_mv_ticket_stats_shop_date 
ON mv_daily_ticket_stats(shop_id, date DESC);

-- Inventory value view
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_inventory_value AS
SELECT 
    shop_id,
    SUM(quantity * cost) as total_cost_value,
    SUM(quantity * price) as total_retail_value,
    COUNT(*) as total_items,
    COUNT(*) FILTER (WHERE quantity <= min_quantity) as low_stock_items,
    COUNT(*) FILTER (WHERE quantity = 0) as out_of_stock_items
FROM inventory_items
WHERE deleted_at IS NULL AND is_active = true
GROUP BY shop_id;

CREATE UNIQUE INDEX idx_mv_inventory_value_shop 
ON mv_inventory_value(shop_id);

-- Customer activity view
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_customer_activity AS
SELECT 
    c.shop_id,
    c.id as customer_id,
    c.first_name,
    c.last_name,
    c.email,
    COUNT(t.id) as total_tickets,
    MAX(t.created_at) as last_ticket_date,
    SUM(t.total_cost) as lifetime_value
FROM customers c
LEFT JOIN tickets t ON c.id = t.customer_id AND t.deleted_at IS NULL
WHERE c.deleted_at IS NULL
GROUP BY c.shop_id, c.id, c.first_name, c.last_name, c.email;

CREATE INDEX idx_mv_customer_activity_shop 
ON mv_customer_activity(shop_id, lifetime_value DESC);

-- ============================================
-- REFRESH FUNCTIONS
-- ============================================

-- Function to refresh all materialized views
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_ticket_stats;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_inventory_value;
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_customer_activity;
END;
$$ LANGUAGE plpgsql;

-- Schedule periodic refresh (requires pg_cron extension)
-- This would be set up in Supabase dashboard or via SQL if pg_cron is available
-- SELECT cron.schedule('refresh-views', '0 */2 * * *', 'SELECT refresh_materialized_views();');

-- ============================================
-- QUERY PERFORMANCE MONITORING
-- ============================================

-- Table for tracking slow queries
CREATE TABLE IF NOT EXISTS query_performance_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    query_fingerprint TEXT NOT NULL,
    query_text TEXT,
    execution_time_ms NUMERIC NOT NULL,
    rows_returned INTEGER,
    shop_id UUID,
    user_id UUID,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_query_perf_time ON query_performance_log(execution_time_ms DESC);
CREATE INDEX idx_query_perf_created ON query_performance_log(created_at DESC);

-- Function to log slow queries
CREATE OR REPLACE FUNCTION log_slow_query(
    p_query TEXT,
    p_execution_time_ms NUMERIC,
    p_rows INTEGER DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Only log queries slower than 100ms
    IF p_execution_time_ms > 100 THEN
        INSERT INTO query_performance_log (
            query_fingerprint,
            query_text,
            execution_time_ms,
            rows_returned,
            shop_id,
            user_id
        ) VALUES (
            MD5(p_query),
            p_query,
            p_execution_time_ms,
            p_rows,
            auth.jwt() ->> 'shop_id',
            auth.uid()
        );
    END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PARTITIONING FOR LARGE TABLES
-- ============================================

-- Prepare tickets table for partitioning by date (for future use)
-- This would be implemented when ticket volume grows large

-- Example partition for tickets by month (commented out for now)
-- CREATE TABLE tickets_2025_01 PARTITION OF tickets
-- FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- ============================================
-- VACUUM AND ANALYZE SETTINGS
-- ============================================

-- Set autovacuum parameters for high-activity tables
ALTER TABLE customers SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE tickets SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

ALTER TABLE inventory_items SET (
    autovacuum_vacuum_scale_factor = 0.1,
    autovacuum_analyze_scale_factor = 0.05
);

-- ============================================
-- CONNECTION POOLING CONFIGURATION
-- ============================================

-- Note: Connection pooling is configured in Supabase dashboard
-- Recommended settings for production:
-- - Pool mode: Transaction
-- - Pool size: 15
-- - Max client connections: 100

-- ============================================
-- PERFORMANCE HELPER FUNCTIONS
-- ============================================

-- Function to get table statistics
CREATE OR REPLACE FUNCTION get_table_stats(p_table_name TEXT)
RETURNS TABLE (
    table_size TEXT,
    index_size TEXT,
    total_size TEXT,
    row_estimate BIGINT,
    dead_tuples BIGINT,
    last_vacuum TIMESTAMPTZ,
    last_analyze TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pg_size_pretty(pg_relation_size(c.oid)) as table_size,
        pg_size_pretty(pg_indexes_size(c.oid)) as index_size,
        pg_size_pretty(pg_total_relation_size(c.oid)) as total_size,
        c.reltuples::BIGINT as row_estimate,
        s.n_dead_tup as dead_tuples,
        s.last_vacuum,
        s.last_analyze
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
    WHERE c.relname = p_table_name
    AND n.nspname = 'public';
END;
$$ LANGUAGE plpgsql;

-- Function to find missing indexes
CREATE OR REPLACE FUNCTION suggest_missing_indexes()
RETURNS TABLE (
    table_name TEXT,
    column_name TEXT,
    index_type TEXT,
    estimated_benefit TEXT
) AS $$
BEGIN
    -- This is a simplified version
    -- In production, you'd use pg_stat_user_tables and query patterns
    RETURN QUERY
    SELECT 
        'tickets'::TEXT,
        'device_model'::TEXT,
        'btree'::TEXT,
        'Medium'::TEXT
    WHERE NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'tickets' 
        AND indexdef LIKE '%device_model%'
    );
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- CACHE TABLES FOR FREQUENT QUERIES
-- ============================================

-- Cache table for shop statistics
CREATE TABLE IF NOT EXISTS shop_stats_cache (
    shop_id UUID PRIMARY KEY,
    total_customers INTEGER DEFAULT 0,
    total_tickets INTEGER DEFAULT 0,
    total_inventory_items INTEGER DEFAULT 0,
    total_employees INTEGER DEFAULT 0,
    last_updated TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Function to update shop stats cache
CREATE OR REPLACE FUNCTION update_shop_stats(p_shop_id UUID)
RETURNS void AS $$
BEGIN
    INSERT INTO shop_stats_cache (
        shop_id,
        total_customers,
        total_tickets,
        total_inventory_items,
        total_employees,
        last_updated
    ) VALUES (
        p_shop_id,
        (SELECT COUNT(*) FROM customers WHERE shop_id = p_shop_id AND deleted_at IS NULL),
        (SELECT COUNT(*) FROM tickets WHERE shop_id = p_shop_id AND deleted_at IS NULL),
        (SELECT COUNT(*) FROM inventory_items WHERE shop_id = p_shop_id AND deleted_at IS NULL),
        (SELECT COUNT(*) FROM employees WHERE shop_id = p_shop_id AND deleted_at IS NULL),
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (shop_id) DO UPDATE SET
        total_customers = EXCLUDED.total_customers,
        total_tickets = EXCLUDED.total_tickets,
        total_inventory_items = EXCLUDED.total_inventory_items,
        total_employees = EXCLUDED.total_employees,
        last_updated = CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- CLEANUP AND MAINTENANCE
-- ============================================

-- Function to clean up old deleted records
CREATE OR REPLACE FUNCTION cleanup_deleted_records(p_days_old INTEGER DEFAULT 90)
RETURNS void AS $$
BEGIN
    -- Delete old soft-deleted records
    DELETE FROM customers 
    WHERE deleted_at IS NOT NULL 
    AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old;
    
    DELETE FROM tickets 
    WHERE deleted_at IS NOT NULL 
    AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old;
    
    DELETE FROM inventory_items 
    WHERE deleted_at IS NOT NULL 
    AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old;
    
    DELETE FROM employees 
    WHERE deleted_at IS NOT NULL 
    AND deleted_at < CURRENT_TIMESTAMP - INTERVAL '1 day' * p_days_old;
    
    -- Clean up old performance logs
    DELETE FROM query_performance_log 
    WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- MONITORING VIEWS
-- ============================================

-- View for monitoring database health
CREATE OR REPLACE VIEW v_database_health AS
SELECT 
    'Connections' as metric,
    COUNT(*) as current_value,
    100 as max_value,
    CASE 
        WHEN COUNT(*) > 80 THEN 'critical'
        WHEN COUNT(*) > 60 THEN 'warning'
        ELSE 'healthy'
    END as status
FROM pg_stat_activity
WHERE datname = current_database()
UNION ALL
SELECT 
    'Cache Hit Ratio' as metric,
    ROUND(100.0 * SUM(blks_hit) / NULLIF(SUM(blks_hit + blks_read), 0), 2) as current_value,
    100 as max_value,
    CASE 
        WHEN ROUND(100.0 * SUM(blks_hit) / NULLIF(SUM(blks_hit + blks_read), 0), 2) < 90 THEN 'warning'
        ELSE 'healthy'
    END as status
FROM pg_stat_database
WHERE datname = current_database();

-- Grant appropriate permissions
GRANT SELECT ON v_database_health TO authenticated;
GRANT SELECT ON mv_daily_ticket_stats TO authenticated;
GRANT SELECT ON mv_inventory_value TO authenticated;
GRANT SELECT ON mv_customer_activity TO authenticated;
GRANT SELECT ON shop_stats_cache TO authenticated;

-- ============================================
-- MIGRATION COMPLETION
-- ============================================

-- Add migration record
INSERT INTO migrations_history (version, description, applied_at)
VALUES ('20250117000001', 'Performance optimizations for production', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;
