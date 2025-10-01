# Setup StoreKit for Subscription Testing

## 🎯 What This Does

StoreKit Configuration allows you to test in-app purchases and subscriptions **without real money** during development.

---

## 📍 Step 1: Create StoreKit Configuration File (2 minutes)

### In Xcode:

1. **File** → **New** → **File...** (or press ⌘N)

2. In the template chooser:
   - Type "storekit" in the search box
   - Select **"StoreKit Configuration File"**
   - Click **Next**

3. Save the file:
   - **Save As:** `Configuration.storekit`
   - **Location:** ProTech folder (next to other files)
   - **Targets:** ☑️ ProTech (check the box)
   - Click **Create**

The file opens automatically with an empty product list.

---

## 📍 Step 2: Add Subscription Products (3 minutes)

### Add Monthly Subscription:

1. Click the **"+"** button at the bottom left
2. Select **"Add Subscription"**
3. Fill in the details:

**Product Configuration:**
- **Reference Name:** `Monthly Pro Subscription`
- **Product ID:** `com.yourcompany.techstorepro.monthly`
  - ⚠️ Must match `Configuration.swift` → `monthlySubscriptionID`
- **Price:** `$19.99`
- **Subscription Duration:** `1 Month`
- **Subscription Group:** Click "Create Group" → Name it `Pro Membership`
- **Review Information:**
  - Display Name: `Pro Membership - Monthly`
  - Description: `Monthly subscription to ProTech Pro features`
- **Localizations:** (optional, can skip for testing)

4. Click **Save** (or just click elsewhere)

### Add Annual Subscription (Optional):

1. Click **"+"** again
2. Select **"Add Subscription"**
3. Fill in:

**Product Configuration:**
- **Reference Name:** `Annual Pro Subscription`
- **Product ID:** `com.yourcompany.techstorepro.annual`
- **Price:** `$199.99`
- **Subscription Duration:** `1 Year`
- **Subscription Group:** Select existing `Pro Membership`
- **Review Information:**
  - Display Name: `Pro Membership - Annual`
  - Description: `Annual subscription to ProTech Pro features (save 16%)`

4. Click **Save**

### Your Configuration Should Show:

```
Pro Membership (Group)
├── Monthly Pro Subscription - $19.99/month
└── Annual Pro Subscription - $199.99/year (Optional)
```

---

## 📍 Step 3: Enable StoreKit in Scheme (1 minute)

### Configure the Scheme:

1. In Xcode menu: **Product** → **Scheme** → **Edit Scheme...**
   - Or press: **⌘<** (Command + Less Than)

2. In the scheme editor:
   - Select **Run** in the left sidebar
   - Click the **Options** tab at the top

3. Find **StoreKit Configuration:**
   - Click the dropdown (probably says "None")
   - Select **Configuration.storekit**

4. Click **Close**

---

## 📍 Step 4: Update Configuration.swift (30 seconds)

### Enable StoreKit:

Open `ProTech/App/Configuration.swift` and change:

```swift
// Feature Flags
static let enableStoreKit = false  // ← Change this
```

To:

```swift
// Feature Flags
static let enableStoreKit = true  // ← Changed to true
```

### Verify Product IDs Match:

Make sure these match your StoreKit products:

```swift
// In-App Purchase Product IDs
static let monthlySubscriptionID = "com.yourcompany.techstorepro.monthly"
static let annualSubscriptionID = "com.yourcompany.techstorepro.annual"
```

If your Product IDs in StoreKit Configuration are different, update them here!

---

## 📍 Step 5: Build and Test (2 minutes)

### Build the App:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build**: Product → Build (⌘B)
3. **Run**: Product → Run (⌘R)

### Test Subscriptions:

1. **Click "Upgrade to Pro"** button in sidebar
2. Subscription view should appear
3. You should see:
   - ✅ Product names loaded
   - ✅ Prices displayed ($19.99/month, etc.)
   - ✅ "7-day free trial • Cancel anytime" text

4. **Try to purchase:**
   - Click on a subscription product
   - StoreKit popup appears with test purchase flow
   - Click **Subscribe**
   - ✅ Purchase completes (no real money!)
   - ✅ "Upgrade to Pro" button disappears
   - ✅ Pro features unlock (Forms, SMS, Reports)

5. **Verify unlock:**
   - Click **Forms** tab → Should work (no lock screen)
   - Click **SMS** tab → Should work
   - Check **Settings** → **Subscription** tab → Shows active subscription

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Configuration.storekit file created
- [ ] At least 1 subscription product added
- [ ] Product IDs match Configuration.swift
- [ ] StoreKit enabled in scheme (Options tab)
- [ ] enableStoreKit = true in Configuration.swift
- [ ] App builds without errors
- [ ] Subscription view loads products
- [ ] Can complete test purchase
- [ ] Pro features unlock after purchase
- [ ] Settings shows active subscription

---

## 🎮 Testing Tips

### Test Different Scenarios:

**Test Purchase:**
```
1. Click "Upgrade to Pro"
2. Select a subscription
3. Complete purchase
4. Verify features unlock
```

**Test Restore:**
```
1. Delete app from Applications
2. Rebuild and run
3. Click "Upgrade to Pro"
4. Click "Restore Purchases"
5. Subscription should restore
```

**Test Subscription Info:**
```
1. Go to Settings → Subscription tab
2. Should show:
   - Plan name
   - Price
   - Expiration date
   - Active status
   - Days remaining
```

**Test Free Trial:**
```
1. Purchase shows "7-day free trial"
2. In test mode, trial is instant
3. Check Settings → shows trial status
```

### StoreKit Test Controls:

During app run, in Xcode:
1. **Debug** → **StoreKit** → **Manage Transactions**
2. You can:
   - View purchased subscriptions
   - Clear purchase history
   - Speed up/slow down time
   - Test renewals
   - Test expirations
   - Test refunds

---

## 🐛 Troubleshooting

### "No products available" in subscription view

**Cause:** Products not loading from StoreKit

**Fix:**
1. Check Product IDs match exactly in:
   - Configuration.storekit products
   - Configuration.swift constants
2. Verify StoreKit Configuration enabled in scheme
3. Clean build folder and rebuild
4. Check Console for error messages

### Subscription view shows but no prices

**Cause:** Product fetch failed

**Fix:**
1. Make sure StoreKit Configuration selected in scheme
2. Verify products have prices set
3. Check subscription group is assigned
4. Rebuild app

### Purchase button does nothing

**Cause:** StoreKit not enabled in scheme

**Fix:**
1. Product → Scheme → Edit Scheme
2. Run → Options
3. StoreKit Configuration → Select Configuration.storekit
4. Close and rebuild

### "Failed to verify receipt" error

**Cause:** Normal in development (no real receipt)

**Fix:**
- This is expected in test mode
- Set `enableStoreKit = false` to bypass verification
- Or implement proper receipt validation for production

### Features don't unlock after purchase

**Cause:** Subscription status not updating

**Fix:**
1. Check SubscriptionManager.isProSubscriber
2. Verify updatePurchasedProducts() is called
3. Add breakpoint in purchase completion
4. Check Console for subscription state

---

## 📊 Product ID Reference

Make sure these match exactly:

**In Configuration.storekit:**
```
Monthly: com.yourcompany.techstorepro.monthly
Annual:  com.yourcompany.techstorepro.annual
```

**In Configuration.swift:**
```swift
static let monthlySubscriptionID = "com.yourcompany.techstorepro.monthly"
static let annualSubscriptionID = "com.yourcompany.techstorepro.annual"
```

**If you want different IDs:**
1. Choose your bundle ID (e.g., com.swiezy.protech)
2. Update both files with same IDs:
   - `com.swiezy.protech.monthly`
   - `com.swiezy.protech.annual`

---

## 🚀 For Production (App Store)

When ready to submit to App Store:

### 1. Create Real Products in App Store Connect:
- Log in to App Store Connect
- My Apps → Your App → In-App Purchases
- Create subscriptions with **exact same Product IDs**
- Set real prices
- Add localizations
- Submit for review

### 2. Update Configuration:
```swift
static let enableStoreKit = false  // Use real App Store
```

### 3. Test with TestFlight:
- Build for TestFlight
- Invite internal testers
- Test real purchase flow
- Verify receipt validation

### 4. Enable for Production:
- Products approved by Apple
- App approved for sale
- Users can purchase with real money

---

## 🎓 How StoreKit Testing Works

**In Development:**
- Configuration.storekit provides fake products
- No real money involved
- Instant purchases
- Can clear purchase history anytime
- Controlled by Xcode

**In Production:**
- Real products from App Store Connect
- Real money transactions
- Apple handles billing
- Real receipts
- Managed by App Store

---

## 📚 Quick Reference

**Keyboard Shortcuts:**
- ⌘N - New file
- ⌘< - Edit scheme
- ⌘B - Build
- ⌘R - Run
- ⇧⌘K - Clean build folder

**Important Files:**
- `Configuration.storekit` - Test products
- `Configuration.swift` - Product IDs & settings
- `SubscriptionManager.swift` - Purchase logic
- `SubscriptionView.swift` - Purchase UI

**StoreKit Menu (while running):**
- Debug → StoreKit → Manage Transactions
- Debug → StoreKit → Clear Purchase History
- Debug → StoreKit → Manage Renewals

---

## ✨ Success Indicators

Your StoreKit is working when:
- ✅ Products load with names and prices
- ✅ Can complete test purchase
- ✅ "Upgrade to Pro" button hides after purchase
- ✅ Pro features unlock (no lock icon)
- ✅ Settings → Subscription shows active status
- ✅ Can restore purchases
- ✅ No "failed to load" errors

---

## 🎉 You're Done!

Once StoreKit is configured:
- ✅ Test subscriptions work
- ✅ Can test all purchase flows
- ✅ Free trial testing enabled
- ✅ No real money spent
- ✅ Ready for development and testing
- ✅ Easy to switch to production later

---

**Total Setup Time:** ~10 minutes
**Difficulty:** Easy (just follow the steps!)

**Your subscription system is ready for testing! 🚀**
