# Square Environment Switching Guide

**Issue:** "Multiple validation errors occurred" when trying to connect  
**Cause:** Token mismatch between environment selection and access token type  
**Status:** ✅ Fixed with improved validation and error messages

---

## The Problem

When you tried to disconnect from **Production** and switch to **Sandbox**, you likely:
1. Selected "Sandbox (Testing)" environment
2. Pasted your **Production** access token
3. Got error: "Multiple validation errors occurred"

**Root Cause:**  
Production tokens don't work with Sandbox environment, and vice versa!

---

## How Token Matching Works

### **Production Tokens:**
- Used with: **Production (Live)** environment
- Prefix: Usually starts with `EQ...` or `EA...` (not `EAAA`)
- Purpose: Process real transactions with real money
- Get from: https://squareup.com/dashboard

### **Sandbox Tokens:**
- Used with: **Sandbox (Testing)** environment
- Prefix: Usually starts with `EAAA...`
- Purpose: Test transactions with fake money
- Get from: https://developer.squareup.com/apps

---

## What I Fixed

### **1. Pre-Connection Validation** ✅

The app now detects token mismatches BEFORE attempting connection:

**If you select Sandbox but use Production token:**
```
⚠️ Token Mismatch Detected

You selected SANDBOX environment but your access 
token appears to be a PRODUCTION token.

Fix:
• Switch environment to "Production (Live)" OR
• Use a sandbox access token from Square Developer Dashboard

Sandbox tokens typically start with "EAAA..."
Production tokens typically start with "EQ..." or other prefixes
```

**If you select Production but use Sandbox token:**
```
⚠️ Token Mismatch Detected

You selected PRODUCTION environment but your access 
token appears to be a SANDBOX token.

Fix:
• Switch environment to "Sandbox (Testing)" OR
• Use a production access token from Square Dashboard

Sandbox tokens typically start with "EAAA..."
Production tokens typically start with "EQ..." or other prefixes
```

---

### **2. Improved UI Guidance** ✅

The credential entry form now shows **environment-specific instructions**:

**When Sandbox is selected:**
```
┌─────────────────────────────────┐
│ 🧪 Sandbox Mode                 │
│ Use sandbox access token for    │
│ testing. No real transactions   │
│ will be processed.              │
└─────────────────────────────────┘

Access Token:
[Paste your token here...]

Get Sandbox Token:
1. Go to Square Developer Dashboard
2. Select your app → Credentials
3. Copy SANDBOX Access Token
⚠️ Token typically starts with 'EAAA...'
```

**When Production is selected:**
```
┌─────────────────────────────────┐
│ ✅ Production Mode              │
│ Use production access token.    │
│ Real transactions will be       │
│ processed.                      │
└─────────────────────────────────┘

Access Token:
[Paste your token here...]

Get Production Token:
1. Go to Square Dashboard (squareup.com)
2. Apps → Manage → Your App
3. Copy PRODUCTION Access Token
⚠️ Token typically starts with 'EQ...' or other prefix
```

---

### **3. Better Error Messages** ✅

If connection still fails after validation:

```
❌ Connection Failed

Multiple validation errors occurred.

Common Issues:

1️⃣ Wrong Environment
• Sandbox token with Production selected
• Production token with Sandbox selected

2️⃣ Token Issues
• Expired or revoked access token
• Token missing required permissions
• Copied token incorrectly (check for spaces)

3️⃣ How to Fix
• Verify environment matches your token type
• Get fresh token from Square Dashboard
• Ensure token has PAYMENTS, INVENTORY, and MERCHANT permissions

Current Selection: Sandbox (Testing)
```

---

## How to Switch Environments

### **Option A: Switch Environment to Match Token**

If you have a **Production token** currently connected:

1. **Disconnect from Production**
   - Settings → Square
   - Click "Disconnect"

2. **Reconnect with correct environment**
   - Click "Enter Square Credentials"
   - Select **"Production (Live)"**
   - Paste your production token
   - Click "Connect"

---

### **Option B: Get New Token for Sandbox**

If you want to test in **Sandbox**:

1. **Get Sandbox Token:**
   - Go to https://developer.squareup.com/apps
   - Click your application
   - Go to **Credentials** tab
   - Find **Sandbox Access Token**
   - Click "Show" → Copy token

2. **Disconnect Current Connection:**
   - Settings → Square
   - Click "Disconnect"

3. **Connect with Sandbox Token:**
   - Click "Enter Square Credentials"
   - Select **"Sandbox (Testing)"**
   - Paste sandbox token
   - Click "Connect"

---

## Step-by-Step: Get Sandbox Token

### **1. Open Square Developer Dashboard**
- URL: https://developer.squareup.com/apps
- Sign in with your Square account

### **2. Select Your Application**
- Click on your app name
- If you don't have an app, click "+" to create one

### **3. Go to Credentials Tab**
- Left sidebar → "Credentials"

### **4. Find Sandbox Section**
- Look for **"Sandbox Credentials"** section
- NOT "Production Credentials"

### **5. Copy Sandbox Access Token**
- Find "Sandbox Access Token"
- Click "Show" button
- Copy the entire token (starts with `EAAA...`)

### **6. Verify Token Starts with EAAA**
```
✅ Correct: EAAAXXXXXXXXXXXXxx...
❌ Wrong: EQXXXXXXXXXXXXX...  (This is production!)
```

---

## Step-by-Step: Get Production Token

### **1. Open Square Dashboard**
- URL: https://squareup.com/dashboard
- Sign in with your Square account

### **2. Navigate to Apps**
- Dashboard → Apps → Manage Apps

### **3. Select Your App**
- Click on your app name
- Or create new app if needed

### **4. Go to Credentials**
- Click "Credentials" or "Production Credentials"

### **5. Copy Production Access Token**
- Find "Production Access Token"
- Click "Show" button
- Copy the entire token (starts with `EQ...` or similar)

### **6. Verify Token Does NOT Start with EAAA**
```
✅ Correct: EQXXXXXXXXXXXXX...
✅ Correct: EAXXXXXXXXXXXXX... (not EAAA)
❌ Wrong: EAAAXXXXXXXXXXXX...  (This is sandbox!)
```

---

## Common Token Prefixes

| Prefix | Environment | Valid For |
|--------|-------------|-----------|
| `EAAA` | Sandbox | Testing only |
| `EQ` | Production | Live transactions |
| `EA` (not EAAA) | Production | Live transactions |
| `sq0atp` | Old format | Deprecated |

**Note:** Token prefixes may vary, but `EAAA` is specifically for sandbox.

---

## Troubleshooting

### **"Token Mismatch Detected" Alert**

**Cause:** Environment doesn't match token type

**Fix:**
1. Check what environment you selected
2. Check token prefix (first 4 characters)
3. Either:
   - Switch environment to match token, OR
   - Get correct token for selected environment

---

### **"Multiple validation errors occurred"**

**Causes:**
- Wrong environment selected
- Token expired or revoked
- Token missing permissions
- Copied token has extra spaces/newlines

**Fix:**
1. Verify environment matches token type
2. Get fresh token from Square Dashboard
3. Check token permissions include:
   - `PAYMENTS_WRITE`
   - `PAYMENTS_READ`
   - `ITEMS_READ`
   - `ITEMS_WRITE`
   - `INVENTORY_READ`
   - `INVENTORY_WRITE`
   - `MERCHANT_PROFILE_READ`
   - `DEVICE_CREDENTIAL_MANAGEMENT` (for Terminal)

---

### **"Connection Failed" But Token Looks Right**

**Check:**
1. **Whitespace:** Token has no spaces or newlines
2. **Complete:** Entire token copied (they're long!)
3. **Recent:** Token not revoked in Square Dashboard
4. **Permissions:** App has all required scopes
5. **Internet:** Network connection working

**Try:**
- Copy token again (avoid partial copy)
- Regenerate token in Square Dashboard
- Check Square Dashboard → Apps → Your App → Status

---

### **Connected But Features Don't Work**

**If connected to wrong environment:**

**Problem:** Connected to Sandbox but expecting Production data
- **Sandbox** has separate test data
- **Production** has your real business data
- They don't share locations, inventory, or customers

**Solution:**
- Disconnect and reconnect to correct environment
- Use Production for real business operations
- Use Sandbox only for testing new features

---

## Environment Comparison

| Feature | Sandbox (Testing) | Production (Live) |
|---------|-------------------|-------------------|
| **Real Money** | ❌ No | ✅ Yes |
| **Test Cards** | ✅ Yes | ❌ No |
| **Real Data** | ❌ Separate | ✅ Yes |
| **Locations** | Test locations | Real locations |
| **Inventory** | Test items | Real items |
| **Terminal** | Simulated | Real device |
| **Reports** | Test data | Real data |
| **Customers** | Test customers | Real customers |

---

## Best Practices

### **For Development/Testing:**
✅ Use **Sandbox** environment  
✅ Use sandbox access token  
✅ Test all features thoroughly  
✅ Use Square's test card numbers  
✅ Verify everything works before production  

### **For Live Business:**
✅ Use **Production** environment  
✅ Use production access token  
✅ Double-check before processing real payments  
✅ Monitor Square Dashboard for transactions  
✅ Keep token secure (never share or commit to git)  

### **When Switching:**
✅ Disconnect current connection first  
✅ Verify token type matches environment  
✅ Test connection before using features  
✅ Remember: Sandbox and Production have separate data  

---

## Quick Reference

### **I Want to Test Features:**
1. Get **Sandbox** token from developer.squareup.com
2. Settings → Square → Disconnect (if connected)
3. Enter Square Credentials
4. Select **"Sandbox (Testing)"**
5. Paste sandbox token
6. Connect ✅

### **I Want to Process Real Transactions:**
1. Get **Production** token from squareup.com/dashboard
2. Settings → Square → Disconnect (if connected)
3. Enter Square Credentials
4. Select **"Production (Live)"**
5. Paste production token
6. Connect ✅

### **I'm Getting Token Mismatch Error:**
1. Check token prefix (first 4 characters)
2. If starts with `EAAA` → Must use **Sandbox**
3. If starts with `EQ` or other → Must use **Production**
4. Switch environment or get correct token

---

## What Changed in the App

### **New Validation:**
- Pre-connection token format check
- Environment mismatch detection
- Early error prevention

### **Improved UI:**
- Environment selector moved to top
- Visual indicators (🧪 for Sandbox, ✅ for Production)
- Context-specific instructions
- Token prefix warnings

### **Better Errors:**
- Specific mismatch messages
- Troubleshooting steps included
- Shows current environment selection
- Links to correct dashboards

---

## Testing Your Connection

### **After Connecting:**

1. **Check Status:**
   - Should show "Connected" with checkmark
   - Shows environment (Sandbox or Production)
   - Shows number of locations found

2. **Test Connection:**
   - Click "Test Connection" button
   - Should show success message
   - If fails, check error details

3. **Verify Locations:**
   - Should see your Square locations listed
   - Location dropdown populated
   - Can select location

4. **Try a Feature:**
   - **Sandbox:** Try importing test items
   - **Production:** View real inventory

---

## Summary

### **The Issue:**
- You tried to use a **Production** token with **Sandbox** environment
- Square API rejected it with validation errors
- Error message wasn't helpful

### **The Fix:**
- ✅ App now detects mismatches before connecting
- ✅ Shows clear error with fix instructions
- ✅ UI guides you to correct token for each environment
- ✅ Better error messages explain what went wrong

### **How to Use:**
1. Choose environment first (Sandbox or Production)
2. Get matching token from correct Square dashboard
3. Verify token prefix matches environment
4. Paste and connect

---

**Build Status:** ✅ **SUCCESS**  
**Validation:** ✅ **ADDED**  
**Error Messages:** ✅ **IMPROVED**

**Try connecting again with the correct token for your selected environment!** 🎯
