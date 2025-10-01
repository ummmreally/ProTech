
# Developer Mode - Pro Features Testing

## 🎯 What It Does

The Developer Mode toggle allows you to **test all Pro features without requiring a real subscription**. Perfect for development and testing!

---

## 📍 How to Access

1. Open ProTech app
2. Click **Settings** in sidebar
3. Click **Developer** tab (hammer icon 🔨)
4. Toggle **"Enable Pro Mode"** ON

---

## ✨ What Happens When Enabled

### Instant Access:
- ✅ **Forms** tab unlocks
- ✅ **SMS** tab unlocks
- ✅ **Reports** tab unlocks
- ✅ All premium features work
- ✅ No "Upgrade to Pro" prompts
- ✅ No subscription required

### UI Changes:
- 🔓 Lock icons disappear from premium tabs
- ✅ Green checkmarks appear on features
- 🟢 "Pro Mode Active" indicator shows
- ⭐ "Upgrade to Pro" button hides

---

## 🎮 Testing Workflow

### Step 1: Enable Pro Mode
```
Settings → Developer → Toggle "Enable Pro Mode" ON
```

### Step 2: Test Premium Features
```
✓ Click Forms tab → Should work (no lock)
✓ Click SMS tab → Should work
✓ Click Reports tab → Should work
✓ Try sending SMS (with Twilio configured)
✓ Create custom forms
✓ View analytics
```

### Step 3: Verify Status
```
Settings → Developer → Check "Current Status"
- Real Subscription: None
- Developer Override: Enabled
- Effective Status: Pro ✅
```

### Step 4: Disable When Done
```
Settings → Developer → Toggle "Enable Pro Mode" OFF
```

---

## 📊 Status Display

The Developer tab shows three status indicators:

**Real Subscription:**
- Shows your actual App Store subscription status
- Green = Active subscription
- Gray = No subscription

**Developer Override:**
- Shows if Pro Mode is enabled
- Orange = Override active
- Gray = Override disabled

**Effective Status:**
- Shows what the app sees
- Green "Pro" = Has access to premium features
- Gray "Free" = Limited to free features

---

## ⚠️ Important Notes

### Before Production:

**MUST DO:**
1. ✅ Disable Pro Mode toggle
2. ✅ Test with real StoreKit Configuration
3. ✅ Verify subscription flow works
4. ✅ Test restore purchases

**DON'T:**
- ❌ Leave Pro Mode enabled in production
- ❌ Submit to App Store with override active
- ❌ Give users access to this setting

### Security:

The toggle is stored in `UserDefaults` with key:
```swift
"developerProModeEnabled"
```

To disable programmatically:
```swift
UserDefaults.standard.set(false, forKey: "developerProModeEnabled")
```

---

## 🔧 Technical Details

### How It Works:

**SubscriptionManager.swift:**
```swift
var isProSubscriber: Bool {
    // Check developer override first
    if UserDefaults.standard.bool(forKey: "developerProModeEnabled") {
        return true
    }
    return !purchasedProductIDs.isEmpty
}
```

**Priority:**
1. Developer override (if enabled)
2. Real subscription status
3. Returns false if neither

### Integration:

All premium feature checks use:
```swift
if subscriptionManager.isProSubscriber {
    // Show premium feature
}
```

This automatically respects the developer override!

---

## 🎯 Use Cases

### 1. Feature Development
```
Enable Pro Mode → Develop premium features → Test without subscription
```

### 2. UI Testing
```
Enable Pro Mode → Test all screens → Verify layouts work
```

### 3. Demo/Screenshots
```
Enable Pro Mode → Take screenshots → Show all features
```

### 4. QA Testing
```
Enable Pro Mode → Test workflows → Verify everything works
```

### 5. Client Demos
```
Enable Pro Mode → Show client → Demonstrate full app
```

---

## 🐛 Troubleshooting

### Pro Mode enabled but features still locked

**Fix:**
1. Restart the app
2. Check Settings → Developer → Verify toggle is ON
3. Check "Effective Status" shows "Pro"
4. Force refresh by toggling OFF then ON

### Toggle doesn't stay enabled

**Fix:**
1. Make sure you're clicking the toggle (not just the label)
2. Check for any error messages
3. Restart app and try again

### Features unlock but subscription info shows "Free"

**This is normal!**
- Developer override doesn't create a fake subscription
- It just unlocks the features
- Subscription tab will still show "Free Version"
- This is intentional to distinguish from real subscriptions

### Can't find Developer tab

**Fix:**
1. Make sure you added DeveloperSettingsView to SettingsView
2. Check that SettingsTab enum includes `.developer`
3. Rebuild the app (⌘B)

---

## 📱 User Experience

### With Pro Mode OFF (Default):
```
Dashboard ✅
Queue ✅
Customers ✅
Forms 🔒 (locked)
SMS 🔒 (locked)
Reports 🔒 (locked)
Settings ✅
```

### With Pro Mode ON:
```
Dashboard ✅
Queue ✅
Customers ✅
Forms ✅ (unlocked)
SMS ✅ (unlocked)
Reports ✅ (unlocked)
Settings ✅
Developer ✅
```

---

## 🎨 UI Elements

### Developer Tab Shows:

**Header:**
- 🔨 Hammer icon
- "Developer Mode" title
- Warning text

**Pro Features Testing:**
- Toggle switch
- Description text
- "Pro Mode Active" indicator (when ON)

**Current Status:**
- Real Subscription status
- Developer Override status
- Effective Status (what app sees)

**Features Unlocked:**
- List of all premium features
- Checkmarks (green) or locks (gray)
- Real-time status updates

**Warning:**
- ⚠️ Important notice
- Reminder to disable before production

---

## 🚀 Quick Commands

**Enable Pro Mode:**
```swift
UserDefaults.standard.set(true, forKey: "developerProModeEnabled")
```

**Disable Pro Mode:**
```swift
UserDefaults.standard.set(false, forKey: "developerProModeEnabled")
```

**Check Status:**
```swift
let isEnabled = UserDefaults.standard.bool(forKey: "developerProModeEnabled")
```

**Force Refresh:**
```swift
subscriptionManager.objectWillChange.send()
```

---

## ✅ Testing Checklist

Before releasing:

- [ ] Pro Mode toggle OFF
- [ ] Test real subscription purchase
- [ ] Verify features lock without subscription
- [ ] Test restore purchases
- [ ] Verify StoreKit Configuration works
- [ ] Test free trial flow
- [ ] Check subscription status displays correctly
- [ ] Verify "Upgrade to Pro" prompts appear
- [ ] Test all premium features with real subscription
- [ ] Remove or hide Developer tab (optional)

---

## 💡 Pro Tips

**During Development:**
- Keep Pro Mode ON to test features quickly
- Toggle OFF occasionally to test free experience
- Use for screenshots and demos

**Before Testing Subscriptions:**
- Toggle Pro Mode OFF
- Clear StoreKit purchase history
- Test real purchase flow
- Verify features unlock properly

**For Demos:**
- Enable Pro Mode
- Show all features
- Explain it's a test mode
- Disable after demo

**For App Store Submission:**
- MUST disable Pro Mode
- Consider removing Developer tab entirely
- Or hide it behind a secret gesture
- Verify in TestFlight first

---

## 🎉 Summary

**What you get:**
- ✅ Instant Pro access for testing
- ✅ No subscription required
- ✅ All features unlocked
- ✅ Easy toggle on/off
- ✅ Status indicators
- ✅ Warning reminders

**Perfect for:**
- 🔧 Development
- 🧪 Testing
- 📸 Screenshots
- 👥 Demos
- 🎨 UI design

**Remember:**
- ⚠️ Disable before production
- ⚠️ Don't submit with override active
- ⚠️ Test real subscriptions too

---

**Your Pro features are now easy to test! 🚀**
