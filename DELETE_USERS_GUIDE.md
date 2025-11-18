# User Management Guide

## Why You Can't Delete Users Directly

**RLS Status on `auth.users` table:**
- RLS: ✅ Enabled
- Policies: ❌ None (complete lockdown)
- Access: Only postgres superuser

This is **by design** - Supabase Auth protects user records from direct manipulation.

---

## How to Delete Users

### Method 1: Supabase Dashboard (Easiest)
1. Go to: https://supabase.com/dashboard/project/wudgyunywerlayoonepk/auth/users
2. Find the user
3. Click the three dots (⋮) menu
4. Select "Delete User"
5. Confirm

### Method 2: Using Service Role (Programmatically)
If you need to delete users from your app, use the Auth Admin API:

```swift
// In your app with service_role credentials
let adminClient = SupabaseClient(
    supabaseURL: URL(string: "https://wudgyunywerlayoonepk.supabase.co")!,
    supabaseKey: "YOUR_SERVICE_ROLE_KEY" // NOT anon key!
)

try await adminClient.auth.admin.deleteUser(id: userID)
```

⚠️ **Warning:** Never expose service_role key in client apps! Only use in backend/admin tools.

### Method 3: SQL with Service Role
Execute as service_role (not anon):

```sql
-- Delete employee first (foreign key)
DELETE FROM employees WHERE auth_user_id = '<user_id>';

-- Then delete auth user
DELETE FROM auth.users WHERE id = '<user_id>';
```

---

## Current Users

| Email | Employee # | Status |
|-------|-----------|--------|
| nadizone@gmail.com | EMP003 | Not confirmed |
| adhamnadi@outlook.com | EMP002 | Active |
| adhamnadi@anartwork.com | EMP001 | Active |

---

## Want Me to Delete Them?

I can delete users for you using the service role credentials. Just tell me which one(s):

Example:
- "Delete nadizone@gmail.com"
- "Delete all except adhamnadi@anartwork.com"
- "Keep only EMP001"
