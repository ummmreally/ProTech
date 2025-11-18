# Quick Fix: Email Confirmation Not Working

## The Problem
✉️ You receive the confirmation email → ✅  
🖱️ You click the link → ✅  
🌐 Browser opens but can't redirect to app → ❌  
🔐 You try to sign in → ❌ "No active session"

## The Solution (5 Minutes)

### 1️⃣ Add URL Scheme in Xcode

Open `ProTech.xcodeproj` and follow these steps:

```
1. Click on ProTech target (left sidebar, blue icon)
2. Click "Info" tab (top)
3. Scroll to bottom → Find "URL Types"
4. Click "+" button
5. Fill in:
   - Identifier: com.protech.auth
   - URL Schemes: protech
   - Role: Editor
6. Press ⌘S to save
```

**Visual Guide:**
```
┌─────────────────────────────────────┐
│ ProTech Target                      │
├─────────────────────────────────────┤
│ General│Info│Build Settings│...     │◄─── Click "Info"
├─────────────────────────────────────┤
│ ...                                 │
│ URL Types                      [+]  │◄─── Click "+"
│ ┌─────────────────────────────────┐│
│ │ Identifier: com.protech.auth    ││
│ │ URL Schemes: protech            ││
│ │ Role: Editor                    ││
│ └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

### 2️⃣ Configure Supabase Dashboard

1. Go to: https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo
2. Click: **Authentication** (left sidebar)
3. Click: **URL Configuration**
4. Under "Redirect URLs", add this line:
   ```
   protech://auth-callback
   ```
5. Click **Save**

**Screenshot locations:**
```
Dashboard
  └─ Authentication
       └─ URL Configuration
            └─ Redirect URLs
                 └─ Add: protech://auth-callback
                      └─ [Save]
```

### 3️⃣ Clean & Rebuild

In Xcode:
```
1. Press: ⇧⌘K (Clean Build Folder)
2. Press: ⌘B (Build)
3. Press: ⌘R (Run)
```

### 4️⃣ Test It

1. **Sign up** with a new email (or use existing unconfirmed account)
2. **Check email** for confirmation link
3. **Click the link**
4. **Watch:** The app should automatically open! 🎉
5. **Look for** these console logs in Xcode:
   ```
   ✅ Handling auth callback: protech://auth-callback?...
   ✅ Successfully authenticated via email confirmation
   ```

## Already Have an Unconfirmed Account?

### Option 1: Manually Confirm (Quickest)

Run this in Supabase SQL Editor:
```sql
-- Replace with YOUR email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'your-email@example.com';
```

Then sign in normally with email/password.

### Option 2: Request New Email

Run this in Supabase SQL Editor:
```sql
-- Replace with YOUR email  
SELECT auth.send_confirmation_email('your-email@example.com');
```

Then click the new confirmation link.

## Still Not Working?

### Check #1: Is the URL scheme registered?
**Test:** In Terminal, run:
```bash
open protech://auth-callback?test=true
```

**Expected:** Your ProTech app should open.  
**If not:** Rebuild the app and try again.

### Check #2: Are the URLs matching?
Verify these three match EXACTLY:
- Xcode URL Scheme: `protech`
- Code (SupabaseConfig.swift): `protech://auth-callback`
- Supabase Dashboard: `protech://auth-callback`

### Check #3: Clean Everything
```bash
# In Xcode
⇧⌘K  # Clean Build Folder
⌘B   # Build
⌘R   # Run

# Completely quit the app first
# Then run again
```

## What Got Changed?

✅ **SupabaseConfig.swift** - Added redirect URL  
✅ **SupabaseAuthService.swift** - Added callback handler  
✅ **ProTechApp.swift** - Added URL interceptor  
✅ **Xcode Project** - Need to add URL scheme (YOU DO THIS)  
✅ **Supabase Dashboard** - Need to whitelist URL (YOU DO THIS)

## Quick Commands Reference

**Clean & Rebuild:**
```
⇧⌘K → ⌘B → ⌘R
```

**Test URL Scheme:**
```bash
open protech://auth-callback?test=true
```

**Check Auth Status (SQL):**
```sql
SELECT email, email_confirmed_at, created_at
FROM auth.users
WHERE email = 'your-email@example.com';
```

**Manually Confirm (SQL):**
```sql
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'your-email@example.com';
```

## Success Indicators

✅ URL scheme shows in Xcode Info tab  
✅ Supabase shows `protech://auth-callback` in redirect URLs  
✅ App builds without errors  
✅ Clicking email link opens app  
✅ Console shows "Successfully authenticated"  
✅ You're signed in automatically  

## Need More Help?

📄 See full documentation: `SUPABASE_EMAIL_CONFIRMATION_FIX.md`

🔍 Check logs:
- Xcode Console (while app is running)
- Supabase Dashboard → Authentication → Logs

💡 Common fixes:
1. Restart Xcode completely
2. Clean derived data: `~/Library/Developer/Xcode/DerivedData/ProTech-*/`
3. Restart your Mac (sometimes needed for URL scheme registration)
