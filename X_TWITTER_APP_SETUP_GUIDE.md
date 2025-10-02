# X/Twitter App Setup - Complete Guide 🐦

## 📋 What to Enter

### ✅ **Required Fields**

#### **1. Callback URI / Redirect URL** (CRITICAL!)
```
protech://oauth/x
```
**⚠️ IMPORTANT:** This MUST match exactly! No typos!

**If you want to add more:**
- `protech://oauth/x`
- `http://localhost:3000/callback` (for testing)

---

#### **2. Website URL**
Enter your business website. Examples:
```
https://www.yourcompany.com
```

**Don't have a website?** Use:
```
https://github.com/yourusername
```
or
```
https://www.facebook.com/yourcompany
```

---

### 📝 **Optional Fields**

#### **3. Organization Name**
This shows when users authorize your app.

**Good Examples:**
```
ProTech Repair Shop
[Your Business Name]
```

**What users see:**
> "ProTech Repair Shop wants to access your account"

---

#### **4. Organization URL**
Link to your company info.

**Examples:**
```
https://www.yourcompany.com
https://www.yourcompany.com/about
```

**Don't have one?** Leave blank or use same as Website URL

---

#### **5. Terms of Service**
Link to your terms.

**Examples:**
```
https://www.yourcompany.com/terms
https://www.yourcompany.com/tos
```

**Don't have one?** Leave blank (optional)

---

#### **6. Privacy Policy**
Link to your privacy policy.

**Examples:**
```
https://www.yourcompany.com/privacy
https://www.yourcompany.com/privacy-policy
```

**Don't have one?** Leave blank (optional)

---

## 🎯 Quick Setup (Minimal)

If you want to get started quickly, just fill:

### **Required:**
1. **Callback URI:** `protech://oauth/x`
2. **Website URL:** `https://yourcompany.com` (or any URL)

### **Optional (Recommended):**
3. **Organization Name:** `Your Business Name`

### **Skip (Optional):**
4. Organization URL
5. Terms of Service
6. Privacy Policy

---

## 📸 Example Configuration

```
┌─────────────────────────────────────────┐
│ App Info                                │
├─────────────────────────────────────────┤
│                                         │
│ Callback URI / Redirect URL *          │
│ [protech://oauth/x              ]      │
│                                         │
│ Website URL *                           │
│ [https://www.myrepairshop.com   ]      │
│                                         │
│ Organization name                       │
│ [My Repair Shop                 ]      │
│                                         │
│ Organization URL                        │
│ [https://www.myrepairshop.com   ]      │
│                                         │
│ Terms of service                        │
│ [                                ]      │
│                                         │
│ Privacy policy                          │
│ [                                ]      │
│                                         │
└─────────────────────────────────────────┘
```

---

## ⚠️ Common Mistakes

### **Callback URI Errors:**

❌ **WRONG:**
- `protech://oauth/twitter` (should be /x)
- `protech://oauth/X` (case sensitive - must be lowercase x)
- `protech://oauth` (missing /x)
- `https://protech.com/callback` (wrong protocol)

✅ **CORRECT:**
- `protech://oauth/x`

---

## 🔧 After Filling Out

Once you submit:

1. **Go to "Keys and tokens" tab**
2. **Copy Client ID** (looks like: `aBcDeFgHiJkLmN...`)
3. **Copy Client Secret** (click show, then copy)
4. **Paste both in ProTech Settings → Social Media → X/Twitter**

---

## 💡 Tips

### **For Testing:**
- Website URL can be anything valid
- Organization name helps users trust your app
- Terms/Privacy are optional for testing

### **For Production:**
- Use real business website
- Add professional organization name
- Add terms/privacy when available

---

## 🚀 Next Steps After Setup

1. ✅ Fill out app info with values above
2. ✅ Submit/Save
3. ✅ Go to "Keys and tokens"
4. ✅ Copy Client ID
5. ✅ Copy Client Secret
6. ✅ Open ProTech
7. ✅ Go to Settings → Social Media → X/Twitter
8. ✅ Paste Client ID
9. ✅ Paste Client Secret
10. ✅ Click "Connect Account"
11. ✅ Authorize
12. ✅ Start posting! 🎉

---

## 📝 Copy-Paste Values

**Use these if you need quick values:**

```
Callback URI:
protech://oauth/x

Website URL:
https://github.com/yourcompany

Organization Name:
ProTech Business
```

---

## 🎯 What Matters Most

### **Critical (Must be exact):**
1. ✅ Callback URI: `protech://oauth/x`

### **Required (Can be anything):**
2. ✅ Website URL: Any valid URL

### **Nice to have:**
3. 👍 Organization Name

### **Optional:**
4. ⚪ Everything else

---

## ✅ Validation Checklist

Before clicking save, verify:

- [ ] Callback URI is exactly: `protech://oauth/x`
- [ ] Website URL is a valid URL
- [ ] Organization name is filled (recommended)
- [ ] No typos in callback URI

---

**That's it! Once you save, you'll get your Client ID and Secret!** 🎉

---

*X/Twitter Setup Guide*  
*Status: Complete*  
*Difficulty: ⭐ Easy*
