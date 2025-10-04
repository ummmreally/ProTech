# How to Get Your Square Credentials & Fix "notConfigured" Error

**Date:** 2025-10-02  
**Issue:** Sync failed with "notConfigured" error  
**Solution:** Enter real Square credentials

---

## The Problem

You're seeing this error:
```
Sync failed: notConfigured
Import failed: notConfigured
```

**Why?** You need to enter your actual Square API credentials. The app can't sync without a valid Square access token.

---

## Quick Fix: Enter Your Square Credentials

### Step 1: Open Square Settings
1. In ProTech, go to **Settings → Square Integration**
2. Click **"Enter Square Credentials"** button (blue button with key icon)

### Step 2: Choose Your Environment

**For Testing (Recommended First):**
- Select **"Sandbox (Testing)"**
- Use sandbox credentials (see below)
- Test without affecting real data

**For Production:**
- Select **"Production (Live)"**
- Use production credentials
- Real inventory will be affected

---

## How to Get Square Credentials

### Option 1: Square Sandbox (For Testing) ⭐️ RECOMMENDED

1. **Visit Square Developer Dashboard**
   - Go to: https://developer.squareup.com/apps
   - Sign in with your Square account (or create one)

2. **Create a Test Application**
   - Click **"+ Create App"**
   - Name it: "ProTech Test"
   - Click **"Create App"**

3. **Get Your Sandbox Token**
   - Click on your new app
   - Go to **"Credentials"** tab
   - Find **"Sandbox Access Token"** section
   - Click **"Show"** and copy the token
   - It looks like: `EAAAl...` (long string)

4. **Enter in ProTech**
   - Paste token in **"Access Token"** field
   - Leave **"Location ID"** empty (auto-detected)
   - Select **"Sandbox (Testing)"**
   - Click **"Connect"**

### Option 2: Square Production (For Live Data)

⚠️ **WARNING:** This will sync with your real Square account!

1. **Visit Square Developer Dashboard**
   - Go to: https://developer.squareup.com/apps

2. **Create Production Application**
   - Click **"+ Create App"**
   - Name it: "ProTech Production"
   - Click **"Create App"**

3. **Get Production Token**
   - Click on your app
   - Go to **"Credentials"** tab
   - Find **"Production Access Token"** section
   - Click **"Show"** and copy
   - ⚠️ Keep this secret!

4. **Enter in ProTech**
   - Paste token in **"Access Token"** field
   - Leave **"Location ID"** empty
   - Select **"Production (Live)"**
   - Click **"Connect"**

---

## After Connecting

### ✅ Success Indicators

You'll see:
- ✅ **"Successfully connected to Square!"** message
- ✅ Green checkmark next to "Connected to Square"
- ✅ Your merchant/location info displayed
- ✅ Sync buttons become active

### Test Your Connection

1. Click **"Test Connection"** button
2. Should show: "Connection successful!"

### Start Syncing

Now you can:
- **Import from Square** - Pull catalog items into ProTech
- **Export to Square** - Push ProTech items to Square
- **Sync All** - Bidirectional sync

---

## Troubleshooting

### "Failed to connect" Error

**Possible causes:**
1. **Invalid token** - Double-check you copied the entire token
2. **Wrong environment** - Using sandbox token with production environment (or vice versa)
3. **Expired token** - Regenerate in Square dashboard
4. **Network issue** - Check internet connection

**Solutions:**
- Copy token again carefully (no spaces)
- Match environment to token type
- Generate a new token
- Test with sandbox first

### "Connection successful" but sync still fails

**Check these:**
1. Location ID is set (should auto-populate)
2. Token has correct permissions (ITEMS_READ, ITEMS_WRITE, INVENTORY_READ, INVENTORY_WRITE)
3. Try "Test Connection" again

### Permissions Errors

If you see permission-related errors:

1. Go to Square Developer Dashboard
2. Select your app
3. Go to **"OAuth"** tab
4. Ensure these permissions are enabled:
   - ✅ Items Read
   - ✅ Items Write
   - ✅ Inventory Read
   - ✅ Inventory Write
   - ✅ Merchant Profile Read

---

## Step-by-Step First Sync

### Starting Fresh (No Items in Either System)

Skip to next section if you have existing items.

### You Have Items in Square Only

**Recommended: Import from Square**

1. ✅ Connect with credentials (as above)
2. ✅ Click **"Import from Square"**
3. ⏱️ Wait for import (progress shown)
4. ✅ Check **Inventory → Manage Inventory**
5. ✅ Verify items imported correctly

### You Have Items in ProTech Only

**Recommended: Export to Square**

1. ✅ Connect with credentials
2. ✅ Click **"Export to Square"**
3. ⏱️ Wait for export
4. ✅ Check Square POS or Dashboard
5. ✅ Verify items appear in Square

### You Have Items in Both Systems

**Recommended: Review First**

1. ✅ Connect with credentials
2. ⚠️ **DON'T sync yet**
3. ✅ Manually check for duplicates
4. ✅ Decide on conflict strategy:
   - **Square Wins** - Overwrite ProTech data
   - **ProTech Wins** - Overwrite Square data
   - **Most Recent** - Use newest data
5. ✅ Set in: Settings → Square Integration → Conflict Resolution
6. ✅ Then click **"Sync All"**

---

## Testing Checklist

Use this checklist with **Sandbox** credentials:

- [ ] Enter sandbox access token
- [ ] Select "Sandbox (Testing)" environment
- [ ] Click "Connect" - success message appears
- [ ] Click "Test Connection" - shows "successful"
- [ ] Click "Import from Square" - imports test items
- [ ] Check Inventory - see imported items
- [ ] Create a test item in ProTech
- [ ] Click "Export to Square" - exports successfully
- [ ] Check Square Dashboard - see exported item
- [ ] Click "Sync All" - completes without errors
- [ ] Check sync logs - see successful operations

**All checkmarks?** You're ready for production! 🎉

---

## Production Deployment

### Before Going Live

1. ✅ Test thoroughly with sandbox
2. ✅ Backup your ProTech database
3. ✅ Backup Square catalog (export from Square)
4. ✅ Plan your sync strategy
5. ✅ Choose off-peak time

### Going Live

1. **Disconnect sandbox**
   - Settings → Square Integration
   - Click "Disconnect"

2. **Connect production**
   - Click "Enter Square Credentials"
   - Paste **production** token
   - Select **"Production (Live)"**
   - Click "Connect"

3. **Initial sync**
   - Choose import OR export (not both)
   - Monitor progress
   - Check logs for errors

4. **Enable auto-sync** (optional)
   - Settings → Square Integration
   - Toggle "Enable Auto-Sync"
   - Set interval (recommended: 30 minutes)

---

## Security Best Practices

### Keep Your Token Safe

❌ **DON'T:**
- Share your access token
- Commit token to version control
- Store in plain text files
- Use production token for testing

✅ **DO:**
- Use sandbox for all testing
- Keep production token secret
- Regenerate if compromised
- Use separate tokens for dev/production

### Token Security in ProTech

ProTech stores your token securely using:
- macOS Keychain (encrypted)
- Secure storage APIs
- Never logged or displayed

---

## Common Questions

**Q: Do I need a paid Square account?**  
A: No! You can use a free Square developer account with sandbox credentials for testing. For production sync with real data, you need an active Square seller account.

**Q: Will this delete my existing inventory?**  
A: No. Sync operations:
- **Import** - Adds items, doesn't delete
- **Export** - Adds items, doesn't delete
- **Sync** - Updates existing, adds new, based on your conflict strategy

**Q: Can I undo a sync?**  
A: Not automatically. Always backup before major syncs.

**Q: How often should I sync?**  
A: 
- Auto-sync: Every 30-60 minutes
- Manual: After bulk changes
- Real-time: Enable webhooks (advanced)

**Q: What if I have items in both systems with same name?**  
A: The system matches by SKU first, then creates mapping. Items with same name but different SKUs are treated as separate items.

**Q: Can I sync only some items?**  
A: Currently, sync operations are all-or-nothing. Category/filtered sync is planned for future release.

---

## Need Help?

### Check These First
1. Sync logs (Settings → Square Integration → Open Sync Dashboard)
2. Connection status (green checkmark = good)
3. Square API dashboard for rate limits
4. This guide's troubleshooting section

### Still Stuck?
- Test with fresh sandbox credentials
- Try disconnecting and reconnecting
- Check Square API status page
- Review sync logs for specific error messages

---

**Remember:** Always test with Sandbox first! 🧪

**Status:** ✅ Setup guide complete  
**Next Step:** Get your Square credentials and connect!
