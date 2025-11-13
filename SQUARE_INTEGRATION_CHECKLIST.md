# Square Integration Setup Checklist

## Current Status
✅ Core Data entities added (SquareConfiguration, SquareSyncMapping, SyncLog)
✅ All Swift service files implemented
✅ UI views created
✅ URLSession-based proxy service working
⚠️ **Configuration Required** - Missing Square credentials

---

## Required Setup Steps

### 1. Square Developer Account Setup 🔑

#### A. Create Square Developer Account
1. Go to https://developer.squareup.com
2. Sign up for a developer account
3. Create a new application

#### B. Get Application Credentials
After creating your Square application, you'll receive:

- **Application ID** (Client ID)
- **Application Secret** (Client Secret)
- **Sandbox Access Token** (for testing)
- **Production Access Token** (for live use)

#### C. Configure OAuth Redirect
In your Square application settings:
1. Add redirect URL: `protech://square-oauth-callback`
2. Set required permissions/scopes:
   - `ITEMS_READ`
   - `ITEMS_WRITE`
   - `INVENTORY_READ`
   - `INVENTORY_WRITE`
   - `MERCHANT_PROFILE_READ`

---

### 2. Update Code with Square Credentials 🔧

#### File: `Services/SquareAPIService.swift`

**Lines 18-20** - Replace placeholders:

```swift
// CURRENT (Lines 18-20):
private let clientId = "YOUR_SQUARE_APPLICATION_ID"
private let clientSecret = "YOUR_SQUARE_APPLICATION_SECRET"
private let redirectUri = "protech://square-oauth-callback"

// REPLACE WITH:
private let clientId = "sq0idp-YOUR_ACTUAL_CLIENT_ID"  // From Square Dashboard
private let clientSecret = "sq0csp-YOUR_ACTUAL_SECRET"  // From Square Dashboard
private let redirectUri = "protech://square-oauth-callback"
```

**⚠️ SECURITY**: Store `clientSecret` in macOS Keychain, not in code!

#### Recommended Secure Implementation:

```swift
// Better approach:
private var clientId: String {
    // Read from app configuration or environment
    Bundle.main.object(forInfoPlistKey: "SQUARE_CLIENT_ID") as? String ?? ""
}

private var clientSecret: String {
    // Read from Keychain
    KeychainManager.shared.get(key: "square_client_secret") ?? ""
}
```

---

### 3. Configure Info.plist 📋

Add Square URL scheme for OAuth callback:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>protech</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.nugentic.ProTech.square</string>
    </dict>
</array>
```

---

### 4. Set Up Supabase Edge Function (For Proxy) ☁️

The app uses `SquareProxyService` to call Square API via Supabase Edge Function.

#### A. Create Edge Function

File: `supabase/functions/square-proxy/index.ts`

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
  const { action, data } = await req.json();
  const accessToken = req.headers.get("square-access-token");
  
  // Forward request to Square API
  const squareUrl = `https://connect.squareup.com/v2/${action}`;
  const response = await fetch(squareUrl, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "Square-Version": "2024-10-17"
    },
    body: JSON.stringify(data)
  });
  
  return new Response(
    JSON.stringify(await response.json()),
    { headers: { "Content-Type": "application/json" } }
  );
});
```

#### B. Deploy Edge Function

```bash
cd your-supabase-project
supabase functions deploy square-proxy
```

#### C. Verify Function URL

The function should be available at:
```
https://ucpgsubidqbhxstgykyt.supabase.co/functions/v1/square-proxy
```

This matches the URL in your `SquareProxyService.swift`.

---

### 5. Test Configuration ✅

#### A. Sandbox Testing

1. **Get Sandbox Access Token** from Square Dashboard
2. **Open ProTech app**
3. **Navigate to**: Settings → Integrations → Square Inventory Sync
4. **Click**: "Enter Square Credentials"
5. **Fill in**:
   - Access Token: `[Sandbox Token]`
   - Merchant ID: `[From Square Dashboard]`
   - Location ID: `[From Square Dashboard]`
   - Environment: **Sandbox**
6. **Click**: "Save Configuration"
7. **Test**: Try syncing test inventory

#### B. Verify Connection

The app should display:
```
✅ Connected to Square
Merchant ID: [Your Merchant ID]
```

#### C. Test Inventory Sync

1. Create a test item in ProTech
2. Click "Sync to Square"
3. Verify item appears in Square Dashboard
4. Modify item in Square Dashboard
5. Click "Sync from Square"
6. Verify changes appear in ProTech

---

### 6. Production Setup 🚀

#### A. Get Production Credentials

1. Complete Square Application Review (if required)
2. Get production access token
3. Update configuration in app to use Production environment

#### B. Configure Production

In the app:
1. Settings → Square Inventory Sync
2. Enter **Production** credentials
3. Select Environment: **Production**
4. Test with real inventory

---

## Quick Setup (Minimal Steps)

If you just want to test the integration ASAP:

### 1. Get Sandbox Token (5 minutes)
1. Visit https://developer.squareup.com
2. Sign in / Create account
3. Create test application
4. Copy Sandbox Access Token

### 2. Configure App (2 minutes)
1. Open ProTech
2. Settings → Square Inventory Sync
3. Click "Enter Square Credentials"
4. Paste:
   - **Access Token**: [Your Sandbox Token]
   - **Merchant ID**: Get from Square Dashboard → Locations
   - **Location ID**: Get from Square Dashboard → Locations
   - **Environment**: Sandbox
5. Save

### 3. Test (1 minute)
1. Go to Inventory
2. Click "Square Sync"
3. Try syncing an item

---

## Files That Need Credentials

### Required Changes:
1. ✅ **`SquareAPIService.swift`** (lines 18-20) - Add OAuth credentials
2. ✅ **`Info.plist`** - Add URL scheme
3. ✅ **Supabase Edge Function** - Deploy square-proxy function

### Optional Security Enhancements:
4. ⚠️ **Keychain Storage** - Store secrets securely
5. ⚠️ **Environment Variables** - Use build configurations

---

## Integration Points

### Current Architecture:

```
ProTech App
    ↓
SquareProxyService (calls Supabase Edge Function)
    ↓
Supabase Edge Function
    ↓
Square API
```

**Why this architecture?**
- Keeps API secrets secure on server
- Prevents exposing Square credentials in app
- Allows rate limiting and monitoring
- Enables webhook processing

---

## What's Already Complete ✅

1. ✅ **Core Data Models** - All entities defined
2. ✅ **Service Layer** - Full CRUD operations implemented
3. ✅ **UI Views** - Settings and dashboard created
4. ✅ **Sync Logic** - Bidirectional sync with conflict resolution
5. ✅ **Webhook Support** - Handler implemented (needs deployment)
6. ✅ **Scheduler** - Auto-sync timer implemented
7. ✅ **Error Handling** - Comprehensive error types
8. ✅ **Proxy Service** - URLSession-based edge function caller

---

## What's Missing ⚠️

1. ⚠️ **Square OAuth Credentials** - Need to add from Square Dashboard
2. ⚠️ **Info.plist Configuration** - URL scheme for OAuth
3. ⚠️ **Supabase Edge Function** - Deploy square-proxy function
4. ⚠️ **Initial Configuration** - First-time setup in app

---

## Security Best Practices

### DO ✅
- Store `clientSecret` in Keychain
- Use environment-specific tokens (sandbox/production)
- Validate webhook signatures
- Encrypt sensitive data in Core Data
- Use HTTPS for all API calls

### DON'T ❌
- Commit OAuth secrets to git
- Hardcode production tokens in code
- Store unencrypted credentials
- Share access tokens publicly

---

## Testing Checklist

### Basic Integration Test
- [ ] App launches without crash
- [ ] Square settings page opens
- [ ] Can enter credentials
- [ ] Credentials save successfully
- [ ] "Connected" status shows after save

### Sync Test
- [ ] Can create item in ProTech
- [ ] Item syncs to Square
- [ ] Item appears in Square Dashboard
- [ ] Can modify item in Square
- [ ] Changes sync back to ProTech
- [ ] Conflict resolution works

### Error Handling
- [ ] Invalid token shows error
- [ ] Network errors handled gracefully
- [ ] Sync failures logged
- [ ] User sees helpful error messages

---

## Support & Documentation

### Square API Docs
- Main: https://developer.squareup.com/docs
- OAuth: https://developer.squareup.com/docs/oauth-api/overview
- Catalog API: https://developer.squareup.com/docs/catalog-api/what-it-does
- Inventory API: https://developer.squareup.com/docs/inventory-api/what-it-does

### ProTech Docs
- Integration Guide: `SQUARE_INTEGRATION_FILES.md`
- Entity Setup: `ALL_ENTITIES_ADDED_COMPLETE.md`
- Proxy Service: `SQUARE_PROXY_FIX.md`

---

## Estimated Setup Time

- **Quick Test (Sandbox)**: 10 minutes
- **Full Setup with OAuth**: 30 minutes
- **Production Configuration**: 1 hour (includes Square app review)

---

## Next Steps

1. **Immediate** (5 min): Get Square Developer account
2. **Next** (10 min): Get sandbox access token and test credentials
3. **Then** (15 min): Configure app with credentials
4. **Finally** (30 min): Deploy Supabase edge function and test full flow

---

**Ready to start?** Begin with Step 1: Create Square Developer Account! 🚀
