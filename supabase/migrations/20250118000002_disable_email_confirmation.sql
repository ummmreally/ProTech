-- Disable Email Confirmation for Development
-- This allows users to sign up and immediately have employee records created
-- without waiting for email confirmation

-- Note: In production, you may want to keep email confirmation enabled
-- and handle employee record creation via a database trigger or webhook

-- Check current auth settings (for documentation)
-- Email confirmation is controlled in the Supabase Dashboard:
-- Authentication > Providers > Email > Confirm email

-- Alternative: Use a database trigger to create employee record after auth user creation
-- This ensures the employee record is created even if RLS blocks the app

CREATE OR REPLACE FUNCTION public.handle_new_user_signup()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  default_shop_id UUID := '00000000-0000-0000-0000-000000000001'::uuid;
BEGIN
  -- Only create employee if one doesn't exist for this auth user
  IF NOT EXISTS (SELECT 1 FROM public.employees WHERE auth_user_id = NEW.id) THEN
    -- Create employee record for new auth user
    INSERT INTO public.employees (
      id,
      shop_id,
      auth_user_id,
      employee_number,
      email,
      first_name,
      last_name,
      role,
      is_active,
      hourly_rate,
      hire_date,
      created_at,
      updated_at,
      sync_version
    ) VALUES (
      gen_random_uuid(),
      default_shop_id,
      NEW.id,
      'EMP' || LPAD((SELECT COALESCE(MAX(CAST(SUBSTRING(employee_number FROM 4) AS INTEGER)), 0) + 1 FROM employees)::TEXT, 3, '0'),
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'first_name', SPLIT_PART(NEW.raw_user_meta_data->>'full_name', ' ', 1)), -- First name
      COALESCE(NEW.raw_user_meta_data->>'last_name', SPLIT_PART(NEW.raw_user_meta_data->>'full_name', ' ', 2)), -- Last name
      COALESCE(NEW.raw_user_meta_data->>'role', 'technician'), -- Use metadata role or default to technician
      true,
      25.0,
      CURRENT_DATE,
      NOW(),
      NOW(),
      1
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-create employee record when auth user is created
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_signup();

-- Grant necessary permissions
GRANT USAGE ON SCHEMA auth TO postgres, service_role;
GRANT ALL ON auth.users TO postgres, service_role;
