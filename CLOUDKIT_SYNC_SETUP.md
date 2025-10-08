# CloudKit Sync Setup Guide for ProTech

## Overview
Your ProTech app now supports **live data synchronization** across multiple Macs using Apple's CloudKit. All business data (customers, tickets, inventory, employees, etc.) will automatically sync between devices signed into the same iCloud account.

## ✅ What's Already Done
- ✅ CoreDataManager updated to use `NSPersistentCloudKitContainer`
- ✅ CloudKit notifications configured
- ✅ Automatic merge policies enabled
- ✅ Employee PIN authentication preserved (no changes)

## 🔧 Xcode Configuration Required

Follow these steps to enable CloudKit in your Xcode project:

### Step 1: Enable iCloud Capability

1. Open your ProTech project in Xcode
2. Select the **ProTech target** in the project navigator
3. Click on the **Signing & Capabilities** tab
4. Click **+ Capability** button (top left)
5. Search for and add **iCloud**
6. Under iCloud services, check these boxes:
   - ✅ **CloudKit**
   - ✅ **Background fetch** (optional but recommended)

### Step 2: Configure CloudKit Container

1. In the iCloud capability section, you'll see **Containers**
2. Click the **+** button to add a new container
3. Enter the container identifier: `iCloud.com.protech.app`
   - **Note:** If this identifier is already taken, you can use: `iCloud.com.yourcompany.protech`
   - If you change it, update line 105 in `CoreDataManager.swift` to match

### Step 3: Update Container Identifier (if needed)

If you had to use a different container identifier in Step 2:

1. Open `ProTech/Services/CoreDataManager.swift`
2. Find line 105:
   ```swift
   let cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.protech.app")
   ```
3. Replace `"iCloud.com.protech.app"` with your actual container identifier

### Step 4: Enable Background Modes (Optional but Recommended)

For better sync performance:

1. In **Signing & Capabilities**, click **+ Capability**
2. Add **Background Modes**
3. Check these boxes:
   - ✅ **Remote notifications**
   - ✅ **Background fetch**

### Step 5: App Sandbox Configuration

If you see a sandbox warning:

1. In **Signing & Capabilities**, find **App Sandbox**
2. Ensure these are enabled:
   - ✅ **Outgoing Connections (Client)**
   - ✅ **Network Server** (if using)

## 🚀 How It Works

### Data Synchronization
- **Automatic:** Changes sync automatically when devices are online
- **Background:** Syncs continue even when app is in background
- **Bidirectional:** Changes made on any device appear on all devices
- **Conflict Resolution:** Last write wins (configurable in CoreDataManager)

### Employee Authentication
- **Separate logins:** Each employee logs in with their PIN on each device
- **Session persistence:** Login stays active until employee logs out
- **Employee records sync:** Add an employee once, their PIN works on all devices
- **No changes needed:** Your existing PIN system works exactly as before

### What Gets Synced
All CoreData entities automatically sync:
- ✅ Customers
- ✅ Tickets & Repairs
- ✅ Inventory Items
- ✅ Invoices & Estimates
- ✅ Appointments
- ✅ Employees (including PINs)
- ✅ Forms & Submissions
- ✅ Time Clock Entries
- ✅ Loyalty Program Data
- ✅ And all other data in the app

## 📱 Testing Sync

### Test on One Device First

1. **Build and run** the app in Xcode
2. **Sign in to iCloud:** System Settings → iCloud (must be signed in)
3. **Add test data:** Create a customer or ticket
4. **Check Console:** Look for CloudKit sync messages:
   ```
   CloudKit sync event: setup - [timestamp]
   CloudKit sync event: import - [timestamp]
   ```

### Test Across Multiple Devices

1. **Install app** on second Mac (same iCloud account)
2. **Launch app** on both devices
3. **Make changes** on Device A (e.g., add customer)
4. **Wait 5-30 seconds** (sync happens automatically)
5. **Check Device B** - changes should appear

### Troubleshooting Sync Issues

If sync isn't working:

1. **Check iCloud Status:**
   - System Settings → iCloud → iCloud Drive (must be ON)
   - Verify same Apple ID on all devices

2. **Check Network:**
   - Internet connection required for initial sync
   - Offline changes sync when reconnected

3. **Check Console Logs:**
   ```swift
   // Look for these messages in Xcode console:
   "CloudKit sync event: export"
   "CloudKit sync event: import"
   ```

4. **Common Issues:**
   - **"Not authenticated"** → Sign into iCloud in System Settings
   - **"Container not found"** → Verify container ID matches in Xcode
   - **"Quota exceeded"** → Free tier is 1GB (should be plenty)

## 🔒 Security & Privacy

### Data Security
- **End-to-end encryption:** Data encrypted in transit and at rest
- **Apple's infrastructure:** Stored securely in iCloud
- **Access control:** Only devices with same iCloud account can access

### Employee PINs
- **PINs sync across devices** (they're part of Employee records)
- **Each device requires login** (authentication is local)
- **No security concerns:** CloudKit is secure for business data

### IMPORTANT: Same iCloud Account Required
- All devices must be signed into the **same iCloud account**
- This is typically the business owner's account
- If you need different employees with different accounts, you'll need a backend solution instead

## 💡 Tips & Best Practices

### Initial Setup
1. **Start with one device:** Set up your primary Mac first
2. **Add employees:** Create all employee records
3. **Test thoroughly:** Make sure everything works on Device 1
4. **Add Device 2:** Install on second Mac and let it sync

### Daily Use
- **Internet required:** Devices need internet to sync
- **Sync delay:** Changes typically appear in 5-30 seconds
- **Offline mode:** App works offline, syncs when reconnected
- **Delete carefully:** Deletions also sync to all devices

### Monitoring Sync
- Check Console for sync events while testing
- First sync may take longer (all data uploads)
- Subsequent syncs are fast (only changes)

## 🆘 Support & Help

### If Sync Stops Working

1. **Force sync:**
   - Quit app completely
   - Relaunch app
   - Wait 1-2 minutes

2. **Reset CloudKit (last resort):**
   - This will re-upload all data
   - Close app on all devices
   - Delete app data (or uninstall/reinstall)
   - Launch on primary device first
   - Let it fully sync before launching on other devices

### Getting More Devices

The setup process is simple:
1. Sign into same iCloud account on new Mac
2. Install ProTech app
3. Launch app - it will automatically sync all data
4. Employees log in with their existing PINs

## 📊 Storage Limits

**iCloud Free Tier:**
- 1GB storage included with iCloud account
- Your business data (text, numbers) is tiny - you'll likely use <100MB
- Plenty of space for years of customer/ticket data

**If you exceed 1GB:**
- Upgrade iCloud storage plan ($0.99/month for 50GB)
- Or migrate to custom backend solution

## ✅ Checklist

Before deploying to multiple devices:

- [ ] iCloud capability added in Xcode
- [ ] CloudKit container configured
- [ ] Background modes enabled (optional)
- [ ] Tested on primary device
- [ ] Console shows successful sync events
- [ ] Tested adding/editing/deleting data
- [ ] Verified data appears on second device
- [ ] All employees have PINs set up
- [ ] Team trained on how sync works

## 🎉 You're All Set!

Your ProTech app now has live multi-device synchronization. All employees can use their existing PINs on any device, and all business data stays perfectly in sync.

**Questions?** Check the troubleshooting section or review the Console logs for sync events.
