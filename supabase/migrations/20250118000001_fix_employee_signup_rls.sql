-- ============================================
-- Fix Employee Signup RLS Policy
-- ============================================
-- This migration adds an RLS policy that allows users to create
-- their own employee record during the signup process.

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

-- Also ensure users can read their own employee record even without shop_id claim
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
