# How to Enable CloudKit Sync

## Current Status

✅ **Your app now works!** It's using local Core Data storage.  
⏸️ **CloudKit sync is disabled** until you configure Xcode.

---

## Two-Step Process to Enable CloudKit

### Step 1: Configure Xcode (5 minutes)

Follow the **XCODE_CLOUDKIT_STEPS.md** guide:

1. Open Xcode → ProTech target → **Signing & Capabilities**
2. Click **+ Capability** → Add **iCloud**
3. Check **CloudKit** box
4. Add container: `iCloud.com.protech.app`
5. Build to verify no errors

### Step 2: Enable CloudKit in Code (30 seconds)

Once Xcode is configured:

1. Open `ProTech/Services/CoreDataManager.swift`
2. Find line 16:
   ```swift
   private let useCloudKit = false
   ```
3. Change to:
   ```swift
   private let useCloudKit = true
   ```
4. Save (Cmd+S)
5. Build & Run (Cmd+R)

---

## What You'll See

### Before Enabling (Current State)
```
Console output:
💾 Initializing with local storage only (CloudKit disabled)
✅ Core Data (local only) loaded successfully
```

### After Enabling
```
Console output:
🔄 Initializing with CloudKit sync enabled
✅ Core Data with CloudKit loaded successfully
CloudKit sync event: setup
CloudKit sync event: export
```

---

## Testing CloudKit Sync

Once enabled:

1. **Add test data** on Device A (customer, ticket, etc.)
2. **Wait 30 seconds**
3. **Launch app on Device B** (same iCloud account)
4. **Verify data appears** on Device B

---

## Troubleshooting

### App Crashes After Setting useCloudKit = true

**Problem:** You haven't configured iCloud capability in Xcode yet

**Solution:**
1. Set `useCloudKit = false` again
2. Complete Step 1 (Xcode configuration) first
3. Then try Step 2 again

### "Not signed into iCloud" Error

**Solution:**
- Go to System Settings → iCloud
- Sign in with your Apple ID
- Restart the app

### Data Not Syncing

**Check:**
1. Both devices signed into **same iCloud account**
2. Internet connection active
3. Console shows "CloudKit sync event: export"

---

## Summary

**Current state:**
- ✅ App works with local storage
- ⏸️ CloudKit ready but disabled
- 🔐 Employee PINs work as normal

**To enable sync:**
1. Configure Xcode (XCODE_CLOUDKIT_STEPS.md)
2. Change `useCloudKit = false` → `true` (line 16)
3. Build & test

**Your PIN system:**
- No changes needed
- Works the same with or without CloudKit
- Each employee logs in per device

---

## Quick Reference

| File to Edit | Line | Change |
|--------------|------|--------|
| CoreDataManager.swift | 16 | `false` → `true` |

**When:** After completing Xcode iCloud configuration  
**Takes:** 30 seconds  
**Result:** Live multi-device sync enabled
