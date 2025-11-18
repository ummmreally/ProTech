# Supabase Email Confirmation Fix

## Problem
After signing up with email/password, users receive a confirmation email but cannot successfully sign in after clicking the confirmation link. This is because the macOS app needs a custom URL scheme to receive the authentication callback from the browser.

## Solution Overview
1. Add a custom URL scheme (`protech://`) to the app
2. Configure Supabase to redirect to this URL after email confirmation
3. Handle the deep link callback in the app

## Step 1: Add URL Scheme in Xcode

### Option A: Using Xcode UI (Recommended)
1. Open `ProTech.xcodeproj` in Xcode
2. Select the **ProTech** target in the project navigator
3. Go to the **Info** tab
4. Expand **URL Types** section (at the bottom)
5. Click **+** to add a new URL Type
6. Configure as follows:
   - **Identifier**: `com.protech.auth`
   - **URL Schemes**: `protech`
   - **Role**: Editor
7. Save the changes (⌘S)

### Option B: Manually Edit Info.plist
If you have an `Info.plist` file, add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.protech.auth</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>protech</string>
        </array>
    </dict>
</array>
```

## Step 2: Configure Supabase Redirect URLs

1. Go to your Supabase Dashboard: https://supabase.com/dashboard/project/sztwxxwnhupwmvxhbzyo
2. Navigate to **Authentication** → **URL Configuration**
3. Under **Redirect URLs**, add:
   ```
   protech://auth-callback
   ```
4. Click **Save**

**Important:** The redirect URL MUST match exactly what's in `SupabaseConfig.redirectURL`

## Step 3: Update Site URL (Optional)

In the same **URL Configuration** section:
1. Set **Site URL** to: `protech://auth-callback`
   - OR keep it as your website if you have one
2. Click **Save**

## Step 4: Test the Flow

### Testing Signup & Email Confirmation

1. **Build and run** the app in Xcode (⌘R)
2. Click **Create Account** or navigate to SignupView
3. Fill in the form:
   - Email: `test@example.com`
   - Password: `Test1234!@#`
   - First Name: `Test`
   - Last Name: `User`
   - PIN: `123456`
   - Role: `Technician`
4. Click **Create Account**
5. Check your email inbox for confirmation link
6. Click the confirmation link in the email
7. The link should automatically open your ProTech app
8. You should see console logs:
   ```
   ✅ Handling auth callback: protech://auth-callback?...
   ✅ Successfully authenticated via email confirmation
   ```
9. The app should automatically sign you in

### If the App Doesn't Open

**Symptoms:**
- Browser shows "This site can't be reached" or similar
- URL scheme error

**Solutions:**
1. Verify URL scheme is correctly configured in Xcode (Step 1)
2. Clean build folder: Product → Clean Build Folder (⇧⌘K)
3. Rebuild: Product → Build (⌘B)
4. Quit and restart the app
5. Try the confirmation link again

### Debugging Console Logs

Watch for these logs in Xcode Console:

**Success:**
```
✅ Handling auth callback: protech://auth-callback?access_token=...
✅ Successfully authenticated via email confirmation
```

**Errors:**
```
⚠️ Unhandled URL scheme: <url>
❌ Error handling auth callback: <error>
```

## Step 5: Handle Existing Unconfirmed Users

If you created an account but couldn't confirm it:

### Option 1: Request New Confirmation Email
```sql
-- Run this in Supabase SQL Editor
-- Replace with your email
SELECT auth.send_confirmation_email('test@example.com');
```

### Option 2: Manually Confirm Email (Development Only)
```sql
-- Run this in Supabase SQL Editor
-- Replace with your email
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email = 'test@example.com';
```

Then try signing in with email/password in the app.

## Troubleshooting

### Issue: "No active session: sessionMissing"
**Cause:** Email not confirmed yet
**Fix:** 
1. Check email for confirmation link
2. Click the link (should open the app)
3. OR manually confirm email using SQL above

### Issue: "Invalid email or password"
**Cause:** Either wrong credentials or email not confirmed
**Fix:**
1. Double-check password
2. Ensure email is confirmed (check `auth.users` table)
3. Try password reset if needed

### Issue: "Invalid authentication callback URL"
**Cause:** URL scheme mismatch
**Fix:**
1. Verify Xcode URL scheme matches `SupabaseConfig.redirectURL`
2. Verify Supabase redirect URL whitelist includes `protech://auth-callback`
3. Rebuild app

### Issue: Browser doesn't redirect back to app
**Cause:** URL scheme not registered with macOS
**Fix:**
1. Quit the app completely
2. Clean build folder in Xcode
3. Rebuild and run
4. First run will register the URL scheme
5. Try confirmation link again

## Code Changes Summary

### Files Modified:
1. **SupabaseConfig.swift**
   - Added `redirectURL` constant

2. **SupabaseAuthService.swift**
   - Updated `signUp()` to include `redirectTo` parameter
   - Added `handleAuthCallback()` method
   - Added `invalidCallback` error case

3. **ProTechApp.swift**
   - Added `supabaseAuth` state object
   - Added `.onOpenURL` handler
   - Added `handleDeepLink()` method

## Testing Checklist

- [ ] URL scheme added to Xcode project
- [ ] App builds successfully
- [ ] Supabase redirect URL configured
- [ ] New signup creates account
- [ ] Confirmation email received
- [ ] Clicking email link opens app
- [ ] Console shows success logs
- [ ] User is automatically signed in
- [ ] Can sign out and sign back in

## Additional Notes

### Security
- The URL scheme `protech://` is app-specific and secure
- Tokens are passed in the URL but handled immediately and not persisted
- Session tokens are securely stored by Supabase SDK

### Production Considerations
- Consider adding universal links (https://) as fallback
- Monitor auth logs in Supabase dashboard
- Set up proper email domain verification
- Configure custom SMTP for branded emails

### Multiple Environments
If you have separate dev/staging/production Supabase projects:

1. Use environment-specific redirect URLs:
   ```swift
   static let redirectURL = {
       #if DEBUG
       return "protech-dev://auth-callback"
       #else
       return "protech://auth-callback"
       #endif
   }()
   ```

2. Register both URL schemes in Xcode

## Support

If you continue experiencing issues:
1. Check Supabase Auth logs: Dashboard → Authentication → Logs
2. Review Xcode console logs
3. Verify email delivery in your email provider
4. Check spam folder for confirmation emails

## References
- [Supabase Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates)
- [iOS Deep Linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Apple URL Scheme Documentation](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
