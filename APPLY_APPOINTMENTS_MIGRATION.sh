#!/bin/bash
# Apply Appointments Supabase Migration
# This script applies the new appointments table to your Supabase project

set -e

echo "🚀 Applying Appointments Migration to Supabase..."
echo ""

# Check if we're in the right directory
if [ ! -f "supabase/migrations/20250119000002_appointments_table.sql" ]; then
    echo "❌ Error: Migration file not found!"
    echo "Please run this script from the ProTech directory."
    exit 1
fi

echo "📋 Migration file found: supabase/migrations/20250119000002_appointments_table.sql"
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found!"
    echo ""
    echo "Install with: brew install supabase/tap/supabase"
    echo "Or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

echo "✅ Supabase CLI found"
echo ""

# Check if we're linked to a project
if [ ! -f ".supabase/config.toml" ]; then
    echo "⚠️  Not linked to a Supabase project"
    echo ""
    echo "Link your project with:"
    echo "  supabase link --project-ref your-project-ref"
    exit 1
fi

echo "✅ Linked to Supabase project"
echo ""

# Apply the migration
echo "🔄 Pushing migration to Supabase..."
echo ""

supabase db push

echo ""
echo "✅ Migration applied successfully!"
echo ""
echo "📊 Verifying appointments table..."

# Quick verification query
supabase db execute "SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'appointments';" 2>/dev/null && echo "✅ Appointments table created" || echo "⚠️  Please verify manually"

echo ""
echo "🎉 Appointments feature is now connected to Supabase!"
echo ""
echo "Next steps:"
echo "  1. Open Supabase dashboard to verify table"
echo "  2. Check RLS policies are active"
echo "  3. Launch ProTech app to test sync"
echo "  4. Create a test appointment"
echo "  5. Verify it appears in Supabase dashboard"
echo ""
echo "📖 See APPOINTMENTS_SUPABASE_INTEGRATION.md for full guide"
echo ""
