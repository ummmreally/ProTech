# Xcode CloudKit Configuration - Step by Step

## 📋 Prerequisites
- [ ] Xcode installed
- [ ] ProTech project opened
- [ ] Valid Apple Developer account (free or paid)

---

## Step 1: Open Project Settings

1. Open **ProTech.xcodeproj** in Xcode
2. In the Project Navigator (left sidebar), click on **ProTech** (blue icon at top)
3. In the main editor, you'll see TARGETS section
4. Select the **ProTech** target (under TARGETS, not PROJECT)

---

## Step 2: Navigate to Signing & Capabilities

1. At the top of the main editor, you'll see tabs: **General**, **Signing & Capabilities**, **Resource Tags**, etc.
2. Click on **Signing & Capabilities** tab
3. You should see your current signing configuration

---

## Step 3: Add iCloud Capability

1. Look for **+ Capability** button (top left of the editor, below tabs)
2. Click **+ Capability**
3. A dropdown list appears - scroll to find **iCloud**
4. Double-click **iCloud** to add it
5. The iCloud section now appears in your capabilities list

---

## Step 4: Configure iCloud Services

In the newly added iCloud section:

1. You'll see **Services** with checkboxes
2. **Check the box** next to **CloudKit**
3. Leave other services unchecked (unless you need them)

Your configuration should look like:
```
☑️ CloudKit
☐ Key-value storage
☐ iCloud Documents
```

---

## Step 5: Add CloudKit Container

Still in the iCloud section:

1. Find the **Containers** area (below Services)
2. You'll see a table with container identifiers
3. Click the **+ button** (small plus icon)
4. A dropdown appears with two options:
   - "Use Default Container"
   - "Specify Custom Container"
5. Select **"Specify Custom Container"**
6. Enter: `iCloud.com.protech.app`
7. Press Enter

**⚠️ If you get an error** that the identifier is taken:
- Try: `iCloud.com.yourcompany.protech`
- Or: `iCloud.com.yourbusinessname.protech`
- **Remember what you used!** You'll need to update the code

---

## Step 6: Update Code (If You Changed Container ID)

**Only if you used a different container identifier in Step 5:**

1. In Xcode, press **Cmd + Shift + O** (Open Quickly)
2. Type: `CoreDataManager.swift`
3. Press Enter to open the file
4. Press **Cmd + F** to find
5. Search for: `iCloud.com.protech.app`
6. Replace with your actual container identifier
7. Press **Cmd + S** to save

---

## Step 7: Add Background Modes (Optional but Recommended)

For better sync performance:

1. Still in **Signing & Capabilities** tab
2. Click **+ Capability** again
3. Find and add **Background Modes**
4. In the Background Modes section, check:
   - ☑️ **Remote notifications**
   - ☑️ **Background fetch**

---

## Step 8: Verify App Sandbox

If you see **App Sandbox** in your capabilities:

1. Expand the App Sandbox section
2. Make sure these are enabled:
   - ☑️ **Outgoing Connections (Client)**
   - ☑️ **Incoming Connections (Server)** - if you use local servers

---

## Step 9: Build and Test

1. Press **Cmd + B** to build the project
2. Fix any build errors (should be none if steps followed correctly)
3. Press **Cmd + R** to run the app
4. Check Xcode Console for CloudKit messages:

Expected output:
```
CloudKit sync event: setup - [timestamp]
CoreData: CloudKit: CoreData+CloudKit: successfully initialized CloudKit
```

---

## ✅ Configuration Complete!

Your Xcode project is now configured for CloudKit sync.

### What You Should See in Xcode:

In **Signing & Capabilities** tab:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔵 Signing
   Team: [Your Team]
   Bundle Identifier: com.protech.app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
☁️ iCloud
   Services:
   ☑️ CloudKit
   
   Containers:
   ☑️ iCloud.com.protech.app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Background Modes
   ☑️ Remote notifications
   ☑️ Background fetch
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 🐛 Common Issues

### "No such container" Error
**Solution:** Your Apple ID doesn't have access to that container yet
- Wait 5 minutes after adding capability
- Or use a different container ID

### "CloudKit not available" Error
**Solution:** iCloud not signed in
- Go to System Settings → iCloud
- Sign in with your Apple ID

### Build Errors
**Solution:** Clean build folder
- In Xcode: **Product → Clean Build Folder** (Shift+Cmd+K)
- Build again (Cmd+B)

### Container ID Taken
**Solution:** Use a unique identifier
- Try: `iCloud.com.yourname.protech`
- Update CoreDataManager.swift line 105

---

## 🎯 Next Steps

1. **Run the app** on your primary device
2. **Add some test data** (customer, ticket, etc.)
3. **Check Console** for sync messages
4. **Install on second device** (same iCloud account)
5. **Verify data syncs** between devices

---

## 📞 Verification Checklist

Before deploying to production:

- [ ] iCloud capability added in Xcode
- [ ] CloudKit container configured with correct ID
- [ ] Code updated if container ID changed
- [ ] Background modes added (optional)
- [ ] App builds without errors
- [ ] Console shows CloudKit sync events
- [ ] Test data syncs between two devices
- [ ] Employee PINs work on all devices

---

## 🎉 Done!

Your ProTech app is now configured for multi-device sync. Proceed to testing on multiple Macs.

See **CLOUDKIT_SYNC_SETUP.md** for full documentation.
