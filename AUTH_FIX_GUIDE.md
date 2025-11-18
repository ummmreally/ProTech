# Authentication Fix Guide
**Date:** November 16, 2025  
**Issue:** Cannot login or create users - PGRST116 error and RLS blocking signup

---

## ✅ Fixed in Code

1. **SupabaseAuthService.swift** - Fixed PGRST116 error by:
   - Changed `.single()` to array query in `fetchEmployeeByAuthId()`
   - Added graceful handling when employee record doesn't exist yet
   - Updated `checkCurrentSession()` to not fail if no employee exists

---

## 🔧 Required Manual Steps

### Step 1: Restore Your Supabase Project

Your Supabase project appears to be paused or having connection issues.

**Check project status:**
```bash
# Navigate to: https://supabase.com/dashboard/projects
# Find project: sztwxxwnhupwmvxhbzyo (tech medics)
# Click "Restore" if paused
```

**Or use CLI:**
```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
# Install Supabase CLI if needed: brew install supabase/tap/supabase
supabase link --project-ref sztwxxwnhupwmvxhbzyo
```

---

### Step 2: Apply RLS Policy Fix

The current RLS policies block employee creation during signup because new users don't have `shop_id` in their JWT yet.

**Apply this SQL migration manually:**

1. Go to: https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo/editor
2. Click "New Query"
3. Paste and run:

```sql
-- ============================================
-- Fix Employee Signup RLS Policy
-- ============================================

-- Drop the existing restrictive insert policy
DROP POLICY IF EXISTS "Admins can insert employees" ON employees;

-- Create a new policy that allows both signup and admin creation
CREATE POLICY "Users can create their own employee record OR admins can create"
  ON employees FOR INSERT
  WITH CHECK (
    -- Allow users to create their own record during signup
    (auth.uid() = auth_user_id AND auth_user_id IS NOT NULL)
    OR
    -- OR allow admins/managers to create records for their shop
    (
      shop_id = (auth.jwt() ->> 'shop_id')::uuid
      AND (auth.jwt() ->> 'role') IN ('admin', 'manager')
    )
  );

-- Also ensure users can read their own employee record
DROP POLICY IF EXISTS "Employees visible to shop members" ON employees;

CREATE POLICY "Employees visible to shop members or themselves"
  ON employees FOR SELECT
  USING (
    -- Users can see employees in their shop
    shop_id = (auth.jwt() ->> 'shop_id')::uuid
    OR
    -- OR users can see their own employee record
    auth.uid() = auth_user_id
  );
```

---

### Step 3: Create Test Shop

You need at least one shop in the database before creating employees:

```sql
-- Insert a test shop
INSERT INTO shops (id, name, email, phone, subscription_tier)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  'Test Repair Shop',
  'admin@testshop.com',
  '555-0100',
  'pro'
);
```

---

### Step 4: Test Signup Flow

Now try creating a user in your ProTech app:

**Signup Test:**
1. Open ProTech app
2. Go to Signup screen
3. Enter:
   - Email: test@yourshop.com
   - Password: TestPass123!
   - First Name: Test
   - Last Name: User
   - Shop ID: `00000000-0000-0000-0000-000000000001`
   - Role: technician
   - PIN: 1234

**Expected behavior:**
- ✅ Auth user created in Supabase
- ✅ Employee record created successfully
- ✅ No PGRST116 error
- ✅ Login should work immediately

---

### Step 5: Test Login Flow

**Email Login:**
```
Email: test@yourshop.com
Password: TestPass123!
```

**PIN Login:**
```
Employee Number: (check database for generated number)
PIN: 1234
```

---

## 🐛 Troubleshooting

### Error: "Connection timeout"
**Cause:** Supabase project is paused  
**Fix:** Restore project in dashboard (Step 1)

### Error: "new row violates row-level security policy"
**Cause:** RLS policy still blocking signup  
**Fix:** Apply SQL from Step 2

### Error: "Employee record not found"
**Cause:** No shop exists yet  
**Fix:** Create test shop (Step 3)

### Error: "Cannot coerce result to single JSON object" (PGRST116)
**Cause:** Old code using `.single()` (already fixed in code)  
**Fix:** Already fixed in SupabaseAuthService.swift

---

## 📝 Migration File

The SQL migration is also saved at:
```
/Users/swiezytv/Documents/Unknown/ProTech/supabase/migrations/20250118000001_fix_employee_signup_rls.sql
```

You can apply it via Supabase CLI once your project is restored:
```bash
cd /Users/swiezytv/Documents/Unknown/ProTech
supabase db push
```

---

## 🎯 What Changed

### Code Fixes
1. **SupabaseAuthService.swift** line 263-278:
   - Removed `.single()` to prevent PGRST116 error
   - Returns array and checks if empty

2. **SupabaseAuthService.swift** line 194-220:
   - Added graceful handling for missing employee records
   - Doesn't throw error during session check

### Database Fixes
1. **RLS Policy for INSERT on employees:**
   - Now allows users to create their own record during signup
   - Still requires admin role for creating other employees

2. **RLS Policy for SELECT on employees:**
   - Users can see their own record even without shop_id claim
   - Required for post-signup session establishment

---

## ✅ Success Indicators

After applying all fixes, you should see:
- ✅ No PGRST116 errors in console
- ✅ Signup creates employee record successfully
- ✅ Login works with email/password
- ✅ Session persists across app restarts
- ✅ No RLS policy violations

---

## 📞 Next Steps

1. **Restore Supabase Project** (if paused)
2. **Apply RLS migration** (Step 2)
3. **Create test shop** (Step 3)
4. **Test signup/login** (Steps 4-5)
5. **Deploy to production** once testing passes

If you continue to have issues, check:
- Supabase project logs in dashboard
- ProTech app console for detailed error messages
- Database RLS policies in Supabase SQL editor
