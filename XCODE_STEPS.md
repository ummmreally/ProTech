# Complete Xcode Setup - Step by Step

## ✅ Good News!

Your Xcode project uses **File System Synchronized Groups** (Xcode 15+), which means:
- Files in the ProTech folder are **automatically detected**
- No need to manually add files to the project
- Just need to configure Core Data and build!

---

## 🎯 Step-by-Step Instructions

### Step 1: Open Xcode Project (30 seconds)

```bash
open /Users/swiezytv/Documents/Unknown/ProTech/ProTech.xcodeproj
```

Or double-click `ProTech.xcodeproj` in Finder.

---

### Step 2: Clean Up Old Files (2 minutes)

You need to delete 2 old files that conflict with our new implementation:

1. In Xcode's Project Navigator (left sidebar), find and **DELETE**:
   - ❌ `ContentView.swift` (the old one in root, not in Views/Main/)
   - ❌ `Persistence.swift` (we use CoreDataManager.swift now)

2. When prompted, choose **"Move to Trash"** (not just remove reference)

---

### Step 3: Configure Core Data Model (10 minutes)

This is the most important step!

1. **Open the data model:**
   - In Project Navigator, click `ProTech.xcdatamodeld`
   - You'll see the Core Data model editor

2. **Create Entity 1: Customer**
   - Click **"Add Entity"** button (bottom left, looks like +)
   - Double-click "Entity" and rename to: **Customer**
   - Click **"+"** under Attributes section
   - Add these 13 attributes:

   | Attribute Name | Type | Optional | Notes |
   |----------------|------|----------|-------|
   | id | UUID | ☐ NO | Uncheck optional |
   | firstName | String | ☐ NO | Uncheck optional |
   | lastName | String | ☐ NO | Uncheck optional |
   | email | String | ☑️ YES | Check optional |
   | phone | String | ☑️ YES | Check optional |
   | address | String | ☑️ YES | Check optional |
   | notes | String | ☑️ YES | Check optional |
   | createdAt | Date | ☐ NO | Uncheck optional |
   | updatedAt | Date | ☐ NO | Uncheck optional |
   | locationId | UUID | ☑️ YES | Check optional |
   | customFields | String | ☑️ YES | Check optional |
   | cloudSyncStatus | String | ☑️ YES | Check optional |
   | cloudRecordID | String | ☑️ YES | Check optional |

   **IMPORTANT:** After adding all attributes:
   - Select **Customer** entity (click on it in left panel)
   - Open **Data Model Inspector** (right sidebar, ⌥⌘3)
   - Find **Codegen** dropdown
   - Set to: **Class Definition**

3. **Create Entity 2: FormTemplate**
   - Click **"Add Entity"** again
   - Rename to: **FormTemplate**
   - Add these 7 attributes:

   | Attribute Name | Type | Optional |
   |----------------|------|----------|
   | id | UUID | ☐ NO |
   | name | String | ☑️ YES |
   | type | String | ☑️ YES |
   | templateJSON | String | ☑️ YES |
   | isDefault | Boolean | ☐ NO |
   | createdAt | Date | ☐ NO |
   | updatedAt | Date | ☐ NO |

   - Select **FormTemplate** entity
   - Data Model Inspector → **Codegen** → **Class Definition**

4. **Create Entity 3: FormSubmission**
   - Click **"Add Entity"**
   - Rename to: **FormSubmission**
   - Add these 7 attributes:

   | Attribute Name | Type | Optional |
   |----------------|------|----------|
   | id | UUID | ☐ NO |
   | templateId | UUID | ☐ NO |
   | customerId | UUID | ☐ NO |
   | ticketId | UUID | ☑️ YES |
   | dataJSON | String | ☑️ YES |
   | submittedAt | Date | ☑️ YES |
   | signatureData | Binary Data | ☑️ YES |

   - Select **FormSubmission** entity
   - Data Model Inspector → **Codegen** → **Class Definition**

5. **Create Entity 4: SMSMessage**
   - Click **"Add Entity"**
   - Rename to: **SMSMessage**
   - Add these 8 attributes:

   | Attribute Name | Type | Optional |
   |----------------|------|----------|
   | id | UUID | ☐ NO |
   | customerId | UUID | ☑️ YES |
   | direction | String | ☑️ YES |
   | body | String | ☑️ YES |
   | status | String | ☑️ YES |
   | twilioSid | String | ☑️ YES |
   | sentAt | Date | ☐ NO |
   | deliveredAt | Date | ☑️ YES |

   - Select **SMSMessage** entity
   - Data Model Inspector → **Codegen** → **Class Definition**

6. **Save the model:**
   - Press **⌘S** to save
   - You should see all 4 entities in the left panel

---

### Step 4: Configure Signing & Capabilities (5 minutes)

1. **Select the project:**
   - Click **ProTech** (blue icon) at the top of Project Navigator
   - Select **ProTech** target (under TARGETS)
   - Click **Signing & Capabilities** tab

2. **Configure Signing:**
   - ☑️ Check **"Automatically manage signing"**
   - **Team:** Select your Apple Developer team
   - **Bundle Identifier:** Should be `com.yourcompany.ProTech` or similar

3. **Add Capabilities:**
   - Click **"+ Capability"** button (top left)
   - Add **iCloud**:
     - ☑️ Check **CloudKit**
     - Container should auto-create: `iCloud.$(CFBundleIdentifier)`
   
   - Click **"+ Capability"** again
   - Add **In-App Purchase**
     - (No configuration needed)
   
   - **App Sandbox** should already be there. Configure it:
     - Under **Network:**
       - ☑️ Check **Outgoing Connections (Client)**
     - Under **File Access:**
       - ☑️ Check **User Selected File** → **Read/Write**
     - Under **Hardware:**
       - ☑️ Check **Printing**

---

### Step 5: Create StoreKit Configuration (5 minutes)

1. **Create the file:**
   - **File** → **New** → **File...** (or ⌘N)
   - In the filter box, type: **storekit**
   - Select **StoreKit Configuration File**
   - Click **Next**
   - Name: `Configuration.storekit`
   - Save Location: ProTech folder
   - Click **Create**

2. **Add products:**
   - The file opens automatically
   - Click **"+"** button at bottom left
   - Select **"Add Subscription"**
   - Configure:
     - **Reference Name:** Monthly Pro Subscription
     - **Product ID:** `com.yourcompany.techstorepro.monthly`
     - **Subscription Duration:** 1 Month
     - **Price:** $19.99 USD
     - **Subscription Group:** Create new → "Pro Membership"
   
   - Click **"+"** again for annual (optional):
     - **Reference Name:** Annual Pro Subscription
     - **Product ID:** `com.yourcompany.techstorepro.annual`
     - **Subscription Duration:** 1 Year
     - **Price:** $199.99 USD
     - **Subscription Group:** Pro Membership (same group)

3. **Enable for testing:**
   - **Product** → **Scheme** → **Edit Scheme...**
   - Select **Run** in left sidebar
   - Click **Options** tab
   - **StoreKit Configuration:** Select `Configuration.storekit`
   - Click **Close**

---

### Step 6: Build the Project (2 minutes)

1. **Clean build folder:**
   - **Product** → **Clean Build Folder** (or ⇧⌘K)

2. **Build:**
   - **Product** → **Build** (or ⌘B)
   - Wait for build to complete
   - Check for errors in the Issue Navigator (⌘4)

3. **Common build errors and fixes:**

   **Error: "Cannot find type 'Customer' in scope"**
   - Fix: Go back to Core Data model, select Customer entity
   - Data Model Inspector → Codegen → Class Definition
   - Clean and rebuild

   **Error: "No such module 'CoreData'"**
   - Fix: Clean build folder (⇧⌘K) and rebuild

   **Error: "Ambiguous use of 'ContentView'"**
   - Fix: Make sure you deleted the old ContentView.swift

---

### Step 7: Run the App! (1 minute)

1. **Select destination:**
   - At the top of Xcode, next to the Run button
   - Select **"My Mac"** or **"My Mac (Designed for iPad)"**

2. **Run:**
   - Click the **Play** button (▶️) or press **⌘R**
   - The app should launch!

3. **What you should see:**
   - ProTech window opens
   - Sidebar with Dashboard, Customers, Forms, SMS, Reports, Settings
   - Dashboard view showing statistics (0 customers initially)
   - "Upgrade to Pro" button in sidebar (since no subscription yet)

---

### Step 8: Test Basic Functionality (5 minutes)

1. **Add a customer:**
   - Click **"+"** button in toolbar
   - Or press **⌘N**
   - Fill in: First Name, Last Name, Phone, Email
   - Click **Save**
   - Customer appears in the list!

2. **View customer details:**
   - Click **Customers** in sidebar
   - Click on the customer you just added
   - See customer details with avatar

3. **Edit customer:**
   - In customer detail view
   - Click **"Edit Customer"** button
   - Make changes
   - Click **Save**

4. **Test subscription view:**
   - Click **"Upgrade to Pro"** in sidebar
   - Subscription view appears with features list
   - Products should load (test mode)
   - Try clicking a subscription (won't charge in test mode)

5. **Check settings:**
   - Click **Settings** in sidebar
   - Try each tab:
     - General (company info)
     - SMS (Twilio settings)
     - Forms (form settings)
     - Subscription (status)

---

## ✅ Success Checklist

After completing all steps, verify:

- [ ] All 4 Core Data entities created with correct attributes
- [ ] Codegen set to "Class Definition" for all entities
- [ ] Old ContentView.swift and Persistence.swift deleted
- [ ] Capabilities added (iCloud, In-App Purchase, App Sandbox)
- [ ] StoreKit configuration file created with products
- [ ] App builds without errors (⌘B)
- [ ] App runs successfully (⌘R)
- [ ] Can add a customer
- [ ] Can view customer details
- [ ] Can edit customer
- [ ] Dashboard shows customer count
- [ ] Settings tabs all work
- [ ] Subscription view appears

---

## 🐛 Troubleshooting

### Build Error: "Cannot find 'Customer' in scope"

**Cause:** Core Data entities not properly configured

**Fix:**
1. Open ProTech.xcdatamodeld
2. Select Customer entity
3. Data Model Inspector (⌥⌘3)
4. Codegen → Class Definition
5. Repeat for all 4 entities
6. Clean Build Folder (⇧⌘K)
7. Build (⌘B)

### Build Error: Multiple ContentView definitions

**Cause:** Old ContentView.swift not deleted

**Fix:**
1. Find ContentView.swift in root (not in Views/Main/)
2. Right-click → Delete
3. Choose "Move to Trash"
4. Clean and rebuild

### App crashes on launch

**Cause:** Core Data model mismatch

**Fix:**
1. Check Console (⌘⇧C) for error message
2. Verify all entity names are spelled correctly
3. Verify all attribute types match the schema
4. Delete app from Applications folder
5. Clean Build Folder
6. Rebuild and run

### "No products available" in subscription view

**Cause:** StoreKit configuration not enabled

**Fix:**
1. Product → Scheme → Edit Scheme
2. Run → Options
3. StoreKit Configuration → Select Configuration.storekit
4. Close and run again

### Xcode doesn't see new files

**Cause:** File system sync issue

**Fix:**
1. Close Xcode
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/ProTech-*`
3. Reopen project
4. Clean and build

---

## 📊 Expected Results

After successful setup:

**Dashboard:**
- Shows "0 Total Customers"
- Shows "0 Added This Month"
- Quick actions available
- Upgrade promo banner (if not subscribed)

**Customers:**
- Empty state with "Add Your First Customer" button
- Search bar ready
- Add button in toolbar

**Settings:**
- General tab: Company info fields
- SMS tab: Twilio credential fields
- Forms tab: Customization options
- Subscription tab: Free version status

**Pro Features:**
- Forms, SMS, Reports tabs show lock icon
- Clicking them shows upgrade prompt
- After test subscription, features unlock

---

## 🎉 You're Done!

Your ProTech app is now fully configured and running!

**Next Steps:**
1. Add your company information (Settings → General)
2. Customize the app icon (Assets.xcassets → AppIcon)
3. Test all features
4. Setup Twilio for SMS (optional)
5. Prepare for App Store (see APP_STORE_CHECKLIST.md)

**Total Time:** ~25 minutes
**Status:** ✅ Ready to use!

---

## 📱 Quick Reference

**Keyboard Shortcuts:**
- ⌘N - New customer
- ⌘B - Build
- ⌘R - Run
- ⇧⌘K - Clean build folder
- ⌘, - Open settings

**Important Files:**
- `ProTech.xcdatamodeld` - Core Data model
- `Configuration.storekit` - Test subscriptions
- `ProTechApp.swift` - App entry point
- `Configuration.swift` - App constants

**Need Help?**
- Check Console (⌘⇧C) for errors
- Review SETUP_INSTRUCTIONS.md
- Check IMPLEMENTATION_GUIDE.md

---

**You've successfully set up ProTech! 🚀**
