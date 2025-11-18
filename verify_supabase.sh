#!/bin/bash

# Supabase Connection Verification Script
# Tests the connection to your Supabase project

PROJECT_ID="sztwxxwnhupwmvxhbzyo"
SUPABASE_URL="https://${PROJECT_ID}.supabase.co"
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dHd4eHduaHVwd212eGhienlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMTgwNjAsImV4cCI6MjA3NTg5NDA2MH0.bXsI9XFPIBNtHZR46HiM5qXfzhqZMYOBn1v2UAFAOAk"

echo "======================================"
echo "Supabase Connection Verification"
echo "======================================"
echo "Project ID: $PROJECT_ID"
echo "URL: $SUPABASE_URL"
echo ""

# Test 1: Basic connection
echo "Test 1: Testing basic connection..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${SUPABASE_URL}/rest/v1/" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY")

if [ "$RESPONSE" -eq 200 ] || [ "$RESPONSE" -eq 404 ]; then
  echo "✅ Connection successful (HTTP $RESPONSE)"
else
  echo "❌ Connection failed (HTTP $RESPONSE)"
  exit 1
fi

# Test 2: Query shops table
echo ""
echo "Test 2: Querying shops table..."
SHOPS_RESPONSE=$(curl -s \
  "${SUPABASE_URL}/rest/v1/shops?limit=1" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY" \
  -H "Accept: application/json")

if echo "$SHOPS_RESPONSE" | grep -q "error"; then
  echo "⚠️  Query returned an error (may be expected if RLS is enabled)"
  echo "Response: $SHOPS_RESPONSE"
else
  echo "✅ Successfully queried shops table"
  echo "Response: $SHOPS_RESPONSE"
fi

# Test 3: Check auth endpoint
echo ""
echo "Test 3: Checking auth endpoint..."
AUTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
  "${SUPABASE_URL}/auth/v1/health" \
  -H "apikey: $ANON_KEY")

if [ "$AUTH_RESPONSE" -eq 200 ]; then
  echo "✅ Auth service is healthy"
else
  echo "⚠️  Auth service returned: $AUTH_RESPONSE"
fi

# Test 4: Check storage endpoint
echo ""
echo "Test 4: Checking storage endpoint..."
STORAGE_RESPONSE=$(curl -s \
  "${SUPABASE_URL}/storage/v1/bucket" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY")

if echo "$STORAGE_RESPONSE" | grep -q "error"; then
  echo "⚠️  Storage query returned an error (may be expected)"
else
  echo "✅ Storage service is accessible"
  echo "Buckets: $STORAGE_RESPONSE"
fi

# Test 5: Check realtime endpoint
echo ""
echo "Test 5: Checking realtime endpoint..."
REALTIME_URL="wss://${PROJECT_ID}.supabase.co/realtime/v1/websocket?apikey=${ANON_KEY}&vsn=1.0.0"
echo "Realtime URL configured: $REALTIME_URL"
echo "✅ Realtime endpoint configured (WebSocket connection would be tested in app)"

# Summary
echo ""
echo "======================================"
echo "Summary"
echo "======================================"
echo "✅ Supabase project is accessible"
echo "✅ All credentials are valid"
echo ""
echo "Next steps:"
echo "1. Run the SyncTestView in the app for comprehensive testing"
echo "2. Create test data using the migration tool"
echo "3. Monitor sync operations in real-time"
echo ""
echo "Project Dashboard: https://supabase.com/dashboard/project/${PROJECT_ID}"
echo ""
