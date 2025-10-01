# Configure Core Data - Do This Now in Xcode

## 🎯 Current Task: Create 4 Entities in Core Data

**Time Required:** 10 minutes  
**Difficulty:** Easy - Just follow the steps!

---

## 📍 Step 1: Open the Core Data Model (30 seconds)

**In Xcode (should already be open):**

1. Look at the **left sidebar** (Project Navigator)
2. Find and **click** on: `ProTech.xcdatamodeld`
3. The Core Data model editor opens in the center

**You should see:**
- Left panel: Empty (or just "Entity" if Xcode created a default)
- Center: Grid area
- Bottom: "Add Entity" button with + icon

---

## 📍 Step 2: Create Customer Entity (3 minutes)

### 2.1 Create the Entity

1. Click **"Add Entity"** button (bottom left, + icon)
2. A new entity appears named "Entity"
3. **Double-click** "Entity" and rename to: `Customer`
4. Press Enter

### 2.2 Add Attributes

Now add 13 attributes. For each one:
- Click **"+"** under the "Attributes" section
- Type the attribute name
- Select the type from dropdown
- Check/uncheck "Optional" checkbox

**Add these in order:**

```
1.  Name: id              Type: UUID          Optional: ☐ (unchecked)
2.  Name: firstName       Type: String        Optional: ☐
3.  Name: lastName        Type: String        Optional: ☐
4.  Name: email           Type: String        Optional: ☑️ (checked)
5.  Name: phone           Type: String        Optional: ☑️
6.  Name: address         Type: String        Optional: ☑️
7.  Name: notes           Type: String        Optional: ☑️
8.  Name: createdAt       Type: Date          Optional: ☐
9.  Name: updatedAt       Type: Date          Optional: ☐
10. Name: locationId      Type: UUID          Optional: ☑️
11. Name: customFields    Type: String        Optional: ☑️
12. Name: cloudSyncStatus Type: String        Optional: ☑️
13. Name: cloudRecordID   Type: String        Optional: ☑️
```

### 2.3 Set Codegen

1. **Click** on "Customer" in the left panel (to select the entity)
2. Open **Data Model Inspector** (right sidebar)
   - If not visible: Menu → View → Inspectors → Data Model
   - Or press: **⌥⌘3**
3. Find the **"Codegen"** dropdown
4. Select: **"Class Definition"**

✅ Customer entity complete!

---

## 📍 Step 3: Create FormTemplate Entity (2 minutes)

### 3.1 Create the Entity

1. Click **"Add Entity"** button again
2. Rename "Entity" to: `FormTemplate`

### 3.2 Add Attributes

Add these 7 attributes:

```
1. Name: id           Type: UUID      Optional: ☐
2. Name: name         Type: String    Optional: ☑️
3. Name: type         Type: String    Optional: ☑️
4. Name: templateJSON Type: String    Optional: ☑️
5. Name: isDefault    Type: Boolean   Optional: ☐
6. Name: createdAt    Type: Date      Optional: ☐
7. Name: updatedAt    Type: Date      Optional: ☐
```

### 3.3 Set Codegen

1. Select "FormTemplate" in left panel
2. Data Model Inspector → Codegen → **"Class Definition"**

✅ FormTemplate entity complete!

---

## 📍 Step 4: Create FormSubmission Entity (2 minutes)

### 4.1 Create the Entity

1. Click **"Add Entity"**
2. Rename to: `FormSubmission`

### 4.2 Add Attributes

Add these 7 attributes:

```
1. Name: id            Type: UUID        Optional: ☐
2. Name: templateId    Type: UUID        Optional: ☐
3. Name: customerId    Type: UUID        Optional: ☐
4. Name: ticketId      Type: UUID        Optional: ☑️
5. Name: dataJSON      Type: String      Optional: ☑️
6. Name: submittedAt   Type: Date        Optional: ☑️
7. Name: signatureData Type: Binary Data Optional: ☑️
```

### 4.3 Set Codegen

1. Select "FormSubmission"
2. Data Model Inspector → Codegen → **"Class Definition"**

✅ FormSubmission entity complete!

---

## 📍 Step 5: Create SMSMessage Entity (2 minutes)

### 5.1 Create the Entity

1. Click **"Add Entity"**
2. Rename to: `SMSMessage`

### 5.2 Add Attributes

Add these 8 attributes:

```
1. Name: id           Type: UUID    Optional: ☐
2. Name: customerId   Type: UUID    Optional: ☑️
3. Name: direction    Type: String  Optional: ☑️
4. Name: body         Type: String  Optional: ☑️
5. Name: status       Type: String  Optional: ☑️
6. Name: twilioSid    Type: String  Optional: ☑️
7. Name: sentAt       Type: Date    Optional: ☐
8. Name: deliveredAt  Type: Date    Optional: ☑️
```

### 5.3 Set Codegen

1. Select "SMSMessage"
2. Data Model Inspector → Codegen → **"Class Definition"**

✅ SMSMessage entity complete!

---

## 📍 Step 6: Save and Verify (1 minute)

### 6.1 Save the Model

Press **⌘S** to save

### 6.2 Verify Everything

Check the left panel - you should see:
- ✅ Customer (13 attributes)
- ✅ FormTemplate (7 attributes)
- ✅ FormSubmission (7 attributes)
- ✅ SMSMessage (8 attributes)

### 6.3 Verify Codegen

For each entity:
1. Click on the entity name
2. Check Data Model Inspector
3. Confirm Codegen = "Class Definition"

---

## 🚀 Step 7: Build the Project!

Now that Core Data is configured:

1. **Clean Build Folder**
   - Menu: Product → Clean Build Folder
   - Or press: **⇧⌘K**

2. **Build**
   - Menu: Product → Build
   - Or press: **⌘B**
   - Wait for "Build Succeeded" ✓

3. **Run**
   - Menu: Product → Run
   - Or press: **⌘R**
   - The app should launch!

---

## ✅ Success Indicators

**If everything worked:**
- ✅ Build succeeds with no errors
- ✅ App launches and shows ProTech window
- ✅ Sidebar shows: Dashboard, Customers, Forms, SMS, Reports, Settings
- ✅ Dashboard displays (with 0 customers)
- ✅ You can click "+" or press ⌘N to add a customer

**If you see errors:**
- Check that all entities have Codegen = "Class Definition"
- Make sure you saved the model (⌘S)
- Clean build folder (⇧⌘K) and rebuild (⌘B)

---

## 🎉 You're Done!

Once the app runs successfully:

1. **Test adding a customer:**
   - Press ⌘N or click "+"
   - Fill in First Name and Last Name
   - Click Save
   - Customer appears in the list!

2. **Explore the app:**
   - Click on the customer to see details
   - Try the Settings tabs
   - Check out the Dashboard

3. **Next steps:**
   - Add your company info (Settings → General)
   - Setup Twilio for SMS (optional)
   - Customize the app icon

---

## 📚 Need Help?

**Common Issues:**

**"Cannot find 'Customer' in scope" error:**
- Fix: Make sure Codegen is set to "Class Definition" for all entities
- Clean build folder (⇧⌘K) and rebuild

**Build errors about Core Data:**
- Fix: Verify all attribute names are spelled correctly
- Check that types match (UUID, String, Date, Boolean, Binary Data)
- Save the model and clean build

**App crashes on launch:**
- Fix: Check the Console (⌘⇧C) for error messages
- Usually means an attribute type is wrong
- Double-check the attribute tables above

---

## 🎯 Quick Summary

**What you're doing:**
1. Creating 4 database tables (entities)
2. Defining their columns (attributes)
3. Telling Xcode to generate the code automatically (Codegen)

**Why it matters:**
- Customer entity = stores all your customer data
- FormTemplate = stores customizable forms
- FormSubmission = stores filled-out forms
- SMSMessage = stores SMS history

**Time investment:** 10 minutes  
**Result:** Fully functional customer management app!

---

**You've got this! Just follow the steps above and you'll be running ProTech in 10 minutes! 💪**
