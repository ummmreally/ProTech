# Core Data Quick Reference - ProTech

## 🎯 Quick Setup (10 minutes)

### Step 1: Open the Model
In Xcode Project Navigator → Click `ProTech.xcdatamodeld`

### Step 2: Create 4 Entities

---

## Entity 1: Customer (13 attributes)

Click "Add Entity" → Rename to **Customer**

| # | Attribute | Type | Optional |
|---|-----------|------|----------|
| 1 | id | UUID | ☐ NO |
| 2 | firstName | String | ☐ NO |
| 3 | lastName | String | ☐ NO |
| 4 | email | String | ☑️ YES |
| 5 | phone | String | ☑️ YES |
| 6 | address | String | ☑️ YES |
| 7 | notes | String | ☑️ YES |
| 8 | createdAt | Date | ☐ NO |
| 9 | updatedAt | Date | ☐ NO |
| 10 | locationId | UUID | ☑️ YES |
| 11 | customFields | String | ☑️ YES |
| 12 | cloudSyncStatus | String | ☑️ YES |
| 13 | cloudRecordID | String | ☑️ YES |

**Set Codegen:** Select Customer → Data Model Inspector → Codegen: **Class Definition**

---

## Entity 2: FormTemplate (7 attributes)

Click "Add Entity" → Rename to **FormTemplate**

| # | Attribute | Type | Optional |
|---|-----------|------|----------|
| 1 | id | UUID | ☐ NO |
| 2 | name | String | ☑️ YES |
| 3 | type | String | ☑️ YES |
| 4 | templateJSON | String | ☑️ YES |
| 5 | isDefault | Boolean | ☐ NO |
| 6 | createdAt | Date | ☐ NO |
| 7 | updatedAt | Date | ☐ NO |

**Set Codegen:** Select FormTemplate → Data Model Inspector → Codegen: **Class Definition**

---

## Entity 3: FormSubmission (7 attributes)

Click "Add Entity" → Rename to **FormSubmission**

| # | Attribute | Type | Optional |
|---|-----------|------|----------|
| 1 | id | UUID | ☐ NO |
| 2 | templateId | UUID | ☐ NO |
| 3 | customerId | UUID | ☐ NO |
| 4 | ticketId | UUID | ☑️ YES |
| 5 | dataJSON | String | ☑️ YES |
| 6 | submittedAt | Date | ☑️ YES |
| 7 | signatureData | Binary Data | ☑️ YES |

**Set Codegen:** Select FormSubmission → Data Model Inspector → Codegen: **Class Definition**

---

## Entity 4: SMSMessage (8 attributes)

Click "Add Entity" → Rename to **SMSMessage**

| # | Attribute | Type | Optional |
|---|-----------|------|----------|
| 1 | id | UUID | ☐ NO |
| 2 | customerId | UUID | ☑️ YES |
| 3 | direction | String | ☑️ YES |
| 4 | body | String | ☑️ YES |
| 5 | status | String | ☑️ YES |
| 6 | twilioSid | String | ☑️ YES |
| 7 | sentAt | Date | ☐ NO |
| 8 | deliveredAt | Date | ☑️ YES |

**Set Codegen:** Select SMSMessage → Data Model Inspector → Codegen: **Class Definition**

---

## ✅ Verification Checklist

After creating all entities:

- [ ] 4 entities visible in left panel (Customer, FormTemplate, FormSubmission, SMSMessage)
- [ ] Customer has 13 attributes
- [ ] FormTemplate has 7 attributes
- [ ] FormSubmission has 7 attributes
- [ ] SMSMessage has 8 attributes
- [ ] All entities have Codegen set to "Class Definition"
- [ ] Model saved (⌘S)

---

## 🎨 Attribute Types Reference

| Type | Description | Example |
|------|-------------|---------|
| **String** | Text data | "John Doe" |
| **UUID** | Unique identifier | Auto-generated |
| **Date** | Date and time | 2025-01-15 10:30 |
| **Boolean** | True/False | true |
| **Binary Data** | Files, images | Signature image |
| **Decimal** | Numbers with decimals | 19.99 |

---

## 🔧 Common Issues

### "Cannot find 'Customer' in scope" error

**Fix:**
1. Select Customer entity in model
2. Open Data Model Inspector (⌥⌘3)
3. Set Codegen to "Class Definition"
4. Clean Build Folder (⇧⌘K)
5. Build (⌘B)

### Entities not showing in code

**Fix:**
1. Make sure Codegen is set for ALL entities
2. Save the model (⌘S)
3. Clean and rebuild

### Wrong attribute type selected

**Fix:**
1. Click the attribute
2. Data Model Inspector → Type dropdown
3. Select correct type
4. Save

---

## 🚀 After Core Data Setup

1. **Save the model** (⌘S)
2. **Clean build folder** (⇧⌘K)
3. **Build** (⌘B)
4. **Run** (⌘R)

Your app should now:
- Launch successfully
- Show empty customer list
- Allow adding customers
- Store data persistently

---

## 📖 Need Help?

- **Detailed guide:** XCODE_STEPS.md
- **Full setup:** SETUP_INSTRUCTIONS.md
- **Troubleshooting:** See "Troubleshooting" section in XCODE_STEPS.md

---

**Total Time:** ~10 minutes
**Difficulty:** Easy (just follow the tables!)

**You've got this! 💪**
