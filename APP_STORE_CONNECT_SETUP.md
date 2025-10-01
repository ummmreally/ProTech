# App Store Connect Setup - Bundle ID & App Registration

## 🎯 The Problem

Your bundle ID doesn't appear in App Store Connect because you need to:
1. Register the Bundle ID in Apple Developer Portal first
2. Then create the app in App Store Connect

---

## 📍 Step 1: Register Bundle ID (Apple Developer Portal)

### Go to Apple Developer Portal:

1. Open: https://developer.apple.com/account
2. Sign in with your Apple ID
3. Click **"Certificates, Identifiers & Profiles"**

### Create App ID (Bundle ID):

1. Click **"Identifiers"** in the sidebar
2. Click the **"+"** button (top left, near "Identifiers")
3. Select **"App IDs"** → Click **Continue**
4. Select **"App"** → Click **Continue**

### Configure App ID:

**Description:**
- Enter: `ProTech` (this is just a name for you to see)

**Bundle ID:**
- Select: **Explicit**
- Enter: `com.swiezy.protech` (or your preferred bundle ID)
  - Format: `com.yourcompany.appname`
  - Must be unique
  - Cannot be changed later
  - Use lowercase, no spaces
  - Examples:
    - `com.swiezy.protech`
    - `com.yourname.protech`
    - `com.yourbusiness.protech`

**Capabilities:**
Check these boxes:
- ☑️ **iCloud** (for CloudKit sync)
- ☑️ **In-App Purchase** (for subscriptions)
- ☑️ **Push Notifications** (optional, for future)

Click **Continue** → Click **Register**

✅ Your Bundle ID is now registered!

---

## 📍 Step 2: Update Xcode with Your Bundle ID

### In Xcode:

1. Select **ProTech** project (blue icon at top of navigator)
2. Select **ProTech** target (under TARGETS)
3. Click **Signing & Capabilities** tab

### Update Bundle Identifier:

**Find "Bundle Identifier" field:**
- Current value: probably `com.yourcompany.ProTech` or similar
- Change to: `com.swiezy.protech` (match what you registered)

**Team:**
- Select your Apple Developer team from dropdown
- If you don't see your team:
  - Xcode → Preferences → Accounts
  - Add your Apple ID
  - Download Manual Profiles

**Signing Certificate:**
- Should auto-select "Apple Development"
- If errors: Click "Try Again" or "Download Manual Profiles"

### Verify Capabilities:

Make sure these are added:
- ✅ iCloud (with CloudKit container)
- ✅ In-App Purchase
- ✅ App Sandbox (with Network, File Access, Printing)

---

## 📍 Step 3: Update Configuration.swift

### Update Product IDs to match your Bundle ID:

Open `ProTech/App/Configuration.swift`:

Change:
```swift
// In-App Purchase Product IDs
static let monthlySubscriptionID = "com.yourcompany.techstorepro.monthly"
static let annualSubscriptionID = "com.yourcompany.techstorepro.annual"
```

To match your new bundle ID:
```swift
// In-App Purchase Product IDs
static let monthlySubscriptionID = "com.swiezy.protech.monthly"
static let annualSubscriptionID = "com.swiezy.protech.annual"
```

**Important:** 
- Product IDs should start with your bundle ID
- Add `.monthly` or `.annual` at the end
- These will be used when creating in-app purchases

---

## 📍 Step 4: Create App in App Store Connect

### Go to App Store Connect:

1. Open: https://appstoreconnect.apple.com
2. Sign in with same Apple ID
3. Click **"My Apps"**
4. Click **"+"** button (next to Apps)
5. Select **"New App"**

### Fill in App Information:

**Platforms:**
- ☑️ Check **macOS** (uncheck iOS if shown)

**Name:**
- Enter: `ProTech` (or your preferred app name)
- This is the public name users see
- 30 character limit
- Must be unique on App Store

**Primary Language:**
- Select: **English (U.S.)** or your language

**Bundle ID:**
- Click dropdown → Select your bundle ID
- **NOW it should appear!** (because you registered it in Step 1)
- Select: `com.swiezy.protech` (or whatever you registered)

**SKU:**
- Enter: `PROTECH001` (or any unique ID)
- This is for your internal tracking
- Not visible to users
- Can be anything unique

**User Access:**
- Select: **Full Access** (or as needed)

Click **Create**

✅ Your app is now in App Store Connect!

---

## 📍 Step 5: Configure App Store Listing (Optional for Testing)

You can fill this out later, but here's what you'll need eventually:

### App Information:

**Privacy Policy URL:**
- Required for subscriptions
- Example: `https://yourwebsite.com/privacy`

**Category:**
- Primary: Business or Productivity
- Secondary: Utilities (optional)

**Age Rating:**
- Click "Edit" → Answer questions
- Likely: 4+ (No Objectionable Content)

### Pricing and Availability:

**Price:**
- Free (base app)
- Subscriptions handled separately in In-App Purchases

**Availability:**
- All countries or select specific ones

### App Privacy:

- You'll need to fill this out before submission
- Describes what data you collect
- Important for transparency

---

## 📍 Step 6: Create In-App Purchases (For Subscriptions)

### In App Store Connect:

1. Go to your app → **"In-App Purchases"** tab
2. Click **"+"** to create new
3. Select **"Auto-Renewable Subscription"**

### Create Subscription Group:

1. Click **"Create"** for subscription group
2. **Reference Name:** `Pro Membership`
3. Click **Create**

### Add Monthly Subscription:

**Reference Name:** `Monthly Pro Subscription`

**Product ID:** `com.swiezy.protech.monthly`
- ⚠️ Must match Configuration.swift exactly!
- Cannot be changed after creation

**Subscription Duration:** `1 Month`

**Subscription Prices:**
- Click **"Add Subscription Price"**
- Select availability: All countries or specific
- Price: $19.99 USD
- Can set different prices for different countries

**Subscription Localizations:**
- Language: English (U.S.)
- **Subscription Display Name:** `Pro Membership - Monthly`
- **Description:** `Unlock all premium features including unlimited SMS, custom forms, and analytics.`

**Review Information:**
- Screenshot: Not required for subscription
- Review Notes: Optional

**App Store Promotion (Optional):**
- Can create promotional images later

Click **Save**

### Add Annual Subscription (Optional):

Repeat above with:
- Product ID: `com.swiezy.protech.annual`
- Duration: `1 Year`
- Price: $199.99 USD
- Display Name: `Pro Membership - Annual`

### Submit for Review:

- Click **"Submit for Review"** on each subscription
- Must be approved by Apple before going live
- Usually takes 24-48 hours

---

## ✅ Verification Checklist

After completing all steps:

- [ ] Bundle ID registered in Apple Developer Portal
- [ ] Bundle ID updated in Xcode
- [ ] Configuration.swift updated with correct product IDs
- [ ] App created in App Store Connect
- [ ] App linked to correct bundle ID
- [ ] In-app purchases created (monthly/annual)
- [ ] Product IDs match in all locations
- [ ] Subscriptions submitted for review (if going live)

---

## 🎮 Testing Before App Store Approval

**You can test NOW without App Store Connect products:**

1. Use StoreKit Configuration (see SETUP_STOREKIT.md)
2. Test purchases work locally
3. Verify all features work
4. When ready for TestFlight/production, switch to real products

**To test with real products:**

1. After subscriptions are approved by Apple
2. In Xcode scheme: Set StoreKit Configuration to "None"
3. Set `enableStoreKit = false` in Configuration.swift
4. Build for TestFlight
5. Invite testers via TestFlight
6. They can test with Sandbox accounts

---

## 🐛 Troubleshooting

### "Bundle ID not available" in App Store Connect

**Cause:** Bundle ID not registered yet

**Fix:**
1. Go to developer.apple.com/account
2. Identifiers → Register new App ID
3. Use exact same bundle ID
4. Return to App Store Connect

### "Bundle ID already in use"

**Cause:** Someone else registered it or you used it before

**Fix:**
1. Choose a different bundle ID
2. Use your unique domain: `com.yourname.protech`
3. Update in Xcode and Configuration.swift

### Xcode signing errors after changing bundle ID

**Fix:**
1. Select ProTech target
2. Signing & Capabilities
3. Uncheck "Automatically manage signing"
4. Check it again
5. Select your team
6. Click "Try Again"

### Product IDs don't work in production

**Cause:** Mismatch between Configuration.swift and App Store Connect

**Fix:**
1. Verify product IDs match exactly:
   - Configuration.swift constants
   - App Store Connect in-app purchases
   - StoreKit Configuration file (for testing)
2. All three must be identical

### Can't submit in-app purchases

**Cause:** App not yet created or metadata missing

**Fix:**
1. Make sure app exists in App Store Connect
2. Fill in required fields for subscription
3. Add localization with display name
4. Set pricing
5. Then submit for review

---

## 📊 Bundle ID Format Guide

**Good Bundle IDs:**
```
com.swiezy.protech          ✅ Good
com.yourcompany.protech     ✅ Good
com.yourdomain.protech      ✅ Good
tech.swiezy.protech         ✅ Good
```

**Bad Bundle IDs:**
```
ProTech                     ❌ Too short
com.apple.protech           ❌ Can't use 'apple'
com.test.app                ❌ Can't use 'test'
com.company name.app        ❌ No spaces
com.company.app-name        ❌ No hyphens
```

---

## 📚 Important URLs

**Apple Developer Portal:**
https://developer.apple.com/account

**App Store Connect:**
https://appstoreconnect.apple.com

**Bundle ID Registration:**
https://developer.apple.com/account/resources/identifiers/list

**In-App Purchase Guide:**
https://developer.apple.com/app-store/subscriptions/

---

## 🚀 Quick Summary

**For Testing (Now):**
1. Register bundle ID in developer portal
2. Update Xcode with bundle ID
3. Use StoreKit Configuration for testing
4. No need to create app in App Store Connect yet

**For Production (Later):**
1. Create app in App Store Connect
2. Add in-app purchases
3. Submit for review
4. Wait for approval
5. Release to App Store

---

## 🎯 Recommended Bundle ID

Based on ProTech, I recommend:

```
com.swiezy.protech
```

Then your product IDs would be:
```
com.swiezy.protech.monthly
com.swiezy.protech.annual
```

Simple, clear, and follows Apple conventions!

---

## ✨ Next Steps

1. **Register bundle ID** in developer portal (5 min)
2. **Update Xcode** with new bundle ID (2 min)
3. **Update Configuration.swift** product IDs (1 min)
4. **Test with StoreKit** Configuration (no App Store Connect needed)
5. **Later:** Create app in App Store Connect when ready to submit

---

**Total Time:** 15-20 minutes for full setup
**For Testing:** Just steps 1-4 needed (~10 minutes)

**Your bundle ID will now work in App Store Connect! 🎉**
