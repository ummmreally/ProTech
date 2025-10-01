# Add Ticket Entity to Core Data - Queue System

## 🎯 What You're Adding

The Queue system requires a new **Ticket** entity in Core Data to track customer check-ins and repairs.

---

## 📍 Step-by-Step Instructions (5 minutes)

### Step 1: Open Core Data Model

1. In Xcode Project Navigator, click `ProTech.xcdatamodeld`
2. You should see your existing 4 entities (Customer, FormTemplate, FormSubmission, SMSMessage)

### Step 2: Create Ticket Entity

1. Click **"Add Entity"** button (bottom left, + icon)
2. Double-click "Entity" and rename to: **Ticket**
3. Click **"+"** under Attributes section to add attributes

### Step 3: Add Ticket Attributes

Add these 16 attributes:

| # | Attribute Name | Type | Optional | Notes |
|---|----------------|------|----------|-------|
| 1 | id | UUID | ☐ NO | Unique identifier |
| 2 | ticketNumber | Integer 32 | ☑️ YES | Display number like #1001 |
| 3 | customerId | UUID | ☐ NO | Links to Customer |
| 4 | deviceType | String | ☑️ YES | iPhone, iPad, Mac, etc. |
| 5 | deviceModel | String | ☑️ YES | iPhone 14 Pro, etc. |
| 6 | issueDescription | String | ☑️ YES | What's wrong with device |
| 7 | status | String | ☑️ YES | waiting, in_progress, completed, picked_up |
| 8 | priority | String | ☑️ YES | low, normal, high, urgent |
| 9 | notes | String | ☑️ YES | Technician notes |
| 10 | checkedInAt | Date | ☑️ YES | When customer checked in |
| 11 | startedAt | Date | ☑️ YES | When work started |
| 12 | completedAt | Date | ☑️ YES | When work completed |
| 13 | pickedUpAt | Date | ☑️ YES | When customer picked up |
| 14 | estimatedCompletion | Date | ☑️ YES | Estimated ready date |
| 15 | createdAt | Date | ☐ NO | Record created |
| 16 | updatedAt | Date | ☐ NO | Record updated |

### Step 4: Set Codegen

1. Select **Ticket** entity in left panel
2. Open **Data Model Inspector** (right sidebar, ⌥⌘3)
3. Find **"Codegen"** dropdown
4. Select: **"Class Definition"**

### Step 5: Save

Press **⌘S** to save the model

---

## ✅ Verification

After adding the Ticket entity, you should have:
- ✅ 5 entities total (Customer, FormTemplate, FormSubmission, SMSMessage, **Ticket**)
- ✅ Ticket has 16 attributes
- ✅ Ticket has Codegen = "Class Definition"

---

## 🚀 Build and Test

### Step 1: Clean and Build

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Build**: Product → Build (⌘B)
3. Wait for "Build Succeeded" ✓

### Step 2: Run the App

1. **Run**: Product → Run (⌘R)
2. The app should launch with the new Queue tab!

### Step 3: Test the Queue System

1. **Click "Queue" in sidebar**
2. Click **"Check In Customer"** button
3. Select a customer (or create new one)
4. Fill in:
   - Device Type (required)
   - Device Model (optional)
   - Issue Description (required)
   - Priority (normal by default)
   - Estimated Completion
5. Click **"Check In"**
6. Customer appears in the queue! 🎉

### Step 4: Test Status Updates

1. Click on a ticket in the queue
2. Try changing the status:
   - **"Start Working"** (waiting → in_progress)
   - **"Mark as Completed"** (in_progress → completed)
   - **"Customer Picked Up"** (completed → picked_up)
3. Add technician notes
4. View time tracking

---

## 🎨 What the Queue System Does

### Check-In Flow
1. Employee clicks "Check In Customer"
2. Selects customer from list (or creates new)
3. Enters device info and issue
4. Sets priority and estimated completion
5. Customer gets a ticket number (starts at #1001)
6. Ticket appears in queue

### Queue Display
- Shows all active tickets (waiting + in_progress)
- Color-coded by status:
  - 🟠 Orange = Waiting
  - 🟣 Purple = In Progress
  - 🟢 Green = Completed
  - ⚪ Gray = Picked Up
- Shows time since check-in
- Displays device type with icon
- Shows ticket number

### Status Progression
```
Waiting → In Progress → Completed → Picked Up
```

### Features
- ✅ Real-time queue updates
- ✅ Priority levels (low, normal, high, urgent)
- ✅ Time tracking (checked in, started, completed, picked up)
- ✅ Technician notes
- ✅ Estimated completion dates
- ✅ Filter by status
- ✅ Ticket numbers for easy reference
- ✅ Links to customer records

---

## 🐛 Troubleshooting

### Build Error: "Cannot find 'Ticket' in scope"

**Fix:**
1. Open ProTech.xcdatamodeld
2. Select Ticket entity
3. Data Model Inspector → Codegen → "Class Definition"
4. Clean Build Folder (⇧⌘K)
5. Build (⌘B)

### Queue tab doesn't appear

**Fix:**
1. Make sure you saved all Swift files
2. Clean build folder
3. Quit and restart Xcode
4. Rebuild

### "No such entity Ticket" crash

**Fix:**
1. Verify Ticket entity exists in ProTech.xcdatamodeld
2. Verify all 16 attributes are added correctly
3. Save the model (⌘S)
4. Delete the app from Applications folder
5. Clean build folder
6. Rebuild and run

### Check-in button does nothing

**Fix:**
1. Make sure you have at least one customer in the database
2. Or click the "+" button in check-in view to create a new customer

---

## 📊 Database Schema Reference

### Ticket Entity Relationships

```
Ticket
├── customerId (UUID) → Links to Customer.id
├── ticketNumber (Int32) → Display number
├── status (String) → "waiting" | "in_progress" | "completed" | "picked_up"
├── priority (String) → "low" | "normal" | "high" | "urgent"
└── timestamps → checkedInAt, startedAt, completedAt, pickedUpAt
```

---

## 🎉 Success!

Once you complete these steps:
- ✅ Queue tab appears in sidebar
- ✅ Can check in customers
- ✅ Tickets appear in queue
- ✅ Can update ticket status
- ✅ Can add notes and track time
- ✅ Full repair workflow system working!

---

## 📚 Quick Reference

**Keyboard Shortcuts:**
- ⌘N - New customer (still works from queue)
- ⌘S - Save Core Data model
- ⌘B - Build
- ⌘R - Run
- ⇧⌘K - Clean build folder

**File Locations:**
- Core Data Model: `ProTech.xcdatamodeld`
- Queue View: `Views/Queue/QueueView.swift`
- Check-In View: `Views/Queue/CheckInCustomerView.swift`
- Ticket Detail: `Views/Queue/TicketDetailView.swift`

---

**Total Time:** 5 minutes to add entity + 2 minutes to test = **7 minutes total**

**Your repair queue system is ready! 🚀**
