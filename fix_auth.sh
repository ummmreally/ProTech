#!/bin/bash

# ProTech Authentication Fix Script
# Checks Supabase connection and guides through fixes

set -e

echo "🔧 ProTech Authentication Fix"
echo "=============================="
echo ""

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found"
    echo "📦 Install with: brew install supabase/tap/supabase"
    echo ""
    exit 1
fi

echo "✅ Supabase CLI found"
echo ""

# Project details
PROJECT_REF="sztwxxwnhupwmvxhbzyo"
PROJECT_URL="https://$PROJECT_REF.supabase.co"

echo "📡 Testing connection to: $PROJECT_URL"
echo ""

# Try to link project
if supabase link --project-ref $PROJECT_REF 2>/dev/null; then
    echo "✅ Connected to Supabase project"
    echo ""
    
    # Check if migrations need to be applied
    echo "📋 Checking migration status..."
    echo ""
    
    if supabase db diff; then
        echo ""
        echo "✅ Database is up to date"
    else
        echo ""
        echo "⚠️  Pending migrations found"
        echo ""
        read -p "Apply migrations now? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "🚀 Applying migrations..."
            supabase db push
            echo "✅ Migrations applied"
        fi
    fi
    
    echo ""
    echo "📊 Current status:"
    supabase status
    
    echo ""
    echo "✅ Next steps:"
    echo "1. Open Supabase dashboard: https://supabase.com/dashboard/project/$PROJECT_REF"
    echo "2. Run the SQL from AUTH_FIX_GUIDE.md (Step 2) in SQL Editor"
    echo "3. Create a test shop (Step 3 in guide)"
    echo "4. Test signup in ProTech app"
    
else
    echo "❌ Failed to connect to Supabase project"
    echo ""
    echo "Possible causes:"
    echo "1. Project is paused - Restore at: https://supabase.com/dashboard"
    echo "2. Not authenticated - Run: supabase login"
    echo "3. Project doesn't exist or wrong ID"
    echo ""
    echo "🔍 Troubleshooting:"
    echo "1. Visit: https://supabase.com/dashboard/projects"
    echo "2. Find project: tech medics ($PROJECT_REF)"
    echo "3. Click 'Restore' if paused"
    echo "4. Try running this script again"
    echo ""
fi

echo ""
echo "📖 Full guide: AUTH_FIX_GUIDE.md"
echo ""
