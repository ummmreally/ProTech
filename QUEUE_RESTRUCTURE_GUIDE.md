# Queue Restructure Implementation Guide

## Overview
The queue system has been completely restructured to separate customer check-ins from active repairs. This creates a clearer workflow where customers check in from the portal, appear in a dedicated queue, and staff can then start repair tickets from those check-ins.

## Changes Summary

### Two Separate Queues
1. **Queue** - Customer check-ins from the portal (walk-ups)
2. **Repairs** - Active repair tickets (formerly the old Queue)

### New Workflow
```
Customer Portal Check-In → Queue View → Start Repair → Repairs View → Complete
```

## Files Created

### 1. **CheckIn.swift** - New Core Data Model
Location: `ProTech/Models/CheckIn.swift`

**Properties:**
- `id: UUID` - Unique identifier
- `customerId: UUID` - Reference to customer
- `checkedInAt: Date` - When customer checked in
- `deviceType: String?` - Device type (iPhone, iPad, etc.)
- `deviceModel: String?` - Device model
- `issueDescription: String?` - Problem description
- `status: String` - "waiting", "started", "completed"
- `ticketId: UUID?` - Set when repair ticket created
- `createdAt: Date` - Record creation time

**Purpose:** Tracks customers who check in via the portal before a repair ticket is created.

### 2. **CheckInQueueView.swift** - Check-In Queue Interface
Location: `ProTech/Views/Queue/CheckInQueueView.swift`

**Features:**
- Displays all customers with status "waiting"
- Shows customer name, device, issue, and time checked in
- "Start Repair" button for each check-in
- Opens form to create repair ticket
- Updates check-in status to "started" when ticket created
- Links check-in to ticket via `ticketId`

**Components:**
- `CheckInQueueView` - Main queue view
- `CheckInCard` - Individual customer card
- `StartRepairFromCheckInView` - Form to create ticket from check-in

### 3. **RepairsView.swift** - Active Repairs View
Location: `ProTech/Views/Repairs/RepairsView.swift`

**Features:**
- Identical to old `QueueView` functionality
- Shows tickets with status "waiting" or "in_progress"
- Filter by status (All, Waiting, In Progress, Completed, Picked Up)
- Navigate to repair details
- "Check In Customer" button (manual check-in bypassing portal)

**Components:**
- `RepairsView` - Main repairs view
- `RepairTicketCard` - Individual ticket card
- `RepairStatusBadge` - Status indicator
- `RepairStatus` enum - Status types

### 4. **PortalCheckInView.swift** - Customer Self Check-In
Location: `ProTech/Views/Customers/PortalCheckInView.swift`

**Features:**
- Form for customers to check in from portal
- Fields: Device Type, Device Model, Issue Description
- Creates CheckIn record with status "waiting"
- Shows success message after check-in
- Sends notification to staff

**Components:**
- `PortalCheckInView` - Check-in form
- `CheckInSuccessView` - Success confirmation screen

## Files Modified

### 1. **ContentView.swift**
**Changes:**
- Added `repairs` case to `Tab` enum
- Changed `queue` icon from "line.3.horizontal.decrease.circle.fill" to "person.2.wave.2.fill"
- Added `repairs` icon: "wrench.and.screwdriver.fill"
- Updated `isPremium` to include both `queue` and `repairs` as free features
- Updated routing:
  - `.queue` → `CheckInQueueView()`
  - `.repairs` → `RepairsView()`

### 2. **SidebarView.swift**
**Changes:**
- Added `Tab.repairs` to "Core" section
- Navigation now shows: Dashboard, Queue, Repairs, Customers, Calendar

### 3. **CustomerPortalView.swift**
**Changes:**
- Added `.checkIn` case to `PortalTab` enum
- Added "Check In" menu item with "hand.raised.fill" icon
- Routes to `PortalCheckInView(customer: customer)`
- Customers can now check in directly from portal

### 4. **Extensions.swift**
**Changes:**
- Added `.customerCheckedIn` notification
- Fired when customer completes check-in
- Staff can listen for this to know when customers arrive

### 5. **CoreDataManager.swift**
**Changes:**
- Added `CheckIn.entityDescription()` to model entities
- CheckIn records now persist in Core Data

## Data Flow

### Customer Check-In Flow
```
1. Customer logs into portal
2. Clicks "Check In" tab
3. Fills out check-in form:
   - Device Type (required)
   - Device Model (optional)
   - Issue Description (required)
4. Submits check-in
5. CheckIn record created with status "waiting"
6. Notification sent to staff
7. Customer sees success message
8. Customer appears in Queue view
```

### Staff Workflow
```
1. Staff sees notification of new check-in
2. Opens "Queue" tab
3. Sees customer waiting with:
   - Name, email, phone
   - Device information
   - Issue description
   - Time checked in
4. Clicks "Start Repair" button
5. Form opens pre-filled with check-in data
6. Staff can edit/add details:
   - Priority
   - Estimated completion
7. Creates Ticket
8. CheckIn status → "started"
9. CheckIn.ticketId set
10. Ticket appears in Repairs view
11. Normal repair workflow continues
```

### Repair Workflow (Unchanged)
```
1. Ticket created (from check-in or manual)
2. Appears in Repairs view
3. Status: waiting → in_progress → completed → picked_up
4. Customer can track via portal
5. Invoice/payment processing
```

## Navigation Changes

### Before
```
Dashboard
Queue (repairs)
Customers
Calendar
```

### After
```
Dashboard
Queue (check-ins from portal)
Repairs (active repair tickets)
Customers
Calendar
```

## UI/UX Improvements

### Queue View (Check-Ins)
- **Icon:** People waving (welcoming customers)
- **Color:** Blue (friendly, approachable)
- **Empty State:** "No customers waiting"
- **Card Style:** Customer-focused (name prominent, contact info visible)
- **Action:** Green "Start Repair" button

### Repairs View
- **Icon:** Wrench and screwdriver (repair work)
- **Color:** Purple for in-progress, Orange for waiting
- **Empty State:** "All caught up! No active repairs"
- **Card Style:** Ticket-focused (ticket number, status badge)
- **Action:** Navigate to repair details

### Customer Portal
- **New "Check In" Tab:** Hand raised icon
- **Simple Form:** Just device and issue
- **Success Message:** "You're Checked In! Please have a seat"
- **Clear Instructions:** "A team member will call you shortly"

## Notifications

### New Notification
```swift
.customerCheckedIn
```

**Fired When:** Customer submits check-in form

**UserInfo:**
- `checkInId: UUID` - The check-in record ID

**Use Cases:**
- Play sound when customer arrives
- Show badge on Queue tab
- Send push notification to staff
- Display toast notification

## Database Schema

### CheckIn Entity
```
id: UUID (Primary Key)
customerId: UUID (Foreign Key → Customer)
checkedInAt: Date
deviceType: String?
deviceModel: String?
issueDescription: String?
status: String (waiting/started/completed)
ticketId: UUID? (Foreign Key → Ticket)
createdAt: Date
```

**Indexes:**
- `checkin_id_index` on `id`
- `checkin_customer_id_index` on `customerId`

**Relationships:**
- `customerId` → Customer (many-to-one)
- `ticketId` → Ticket (one-to-one optional)

## Migration Notes

### For Existing Users
- No data migration needed
- CheckIn is a new entity
- Existing tickets unchanged
- Old "Queue" view is now "Repairs"
- No breaking changes to existing workflow

### For New Installations
- CheckIn entity automatically created
- Both Queue and Repairs tabs available
- Customer portal includes Check In feature

## Testing Checklist

### Customer Portal Check-In
- [ ] Customer can access "Check In" tab
- [ ] Form validates required fields
- [ ] Check-in creates record in database
- [ ] Success message displays
- [ ] Notification fires

### Queue View
- [ ] Check-ins appear in queue
- [ ] Customer info displays correctly
- [ ] Time ago updates properly
- [ ] "Start Repair" button works
- [ ] Empty state shows when no check-ins

### Start Repair Flow
- [ ] Form pre-fills with check-in data
- [ ] Can edit all fields
- [ ] Ticket created successfully
- [ ] Check-in status updates to "started"
- [ ] Check-in.ticketId set correctly

### Repairs View
- [ ] New tickets appear
- [ ] Filter works correctly
- [ ] Status badges display
- [ ] Navigation to details works
- [ ] Manual check-in still works

### Integration
- [ ] Customer can check in from kiosk mode
- [ ] Staff notification works
- [ ] Check-in to ticket linking works
- [ ] Portal shows repair after ticket created

## Benefits

### For Customers
- ✅ Easy self-service check-in
- ✅ No waiting at counter
- ✅ Clear feedback on check-in status
- ✅ Kiosk-friendly interface

### For Staff
- ✅ See who's waiting at a glance
- ✅ All customer info immediately available
- ✅ One-click to start repair
- ✅ Better queue management
- ✅ Clear separation of check-ins vs repairs

### For Business
- ✅ Reduced counter congestion
- ✅ Faster customer intake
- ✅ Better metrics (check-in time, wait time)
- ✅ Professional self-service experience
- ✅ Scalable for multiple locations

## Future Enhancements

### Potential Features
- [ ] Estimated wait time display
- [ ] Queue position notification
- [ ] SMS alerts when called
- [ ] Queue analytics dashboard
- [ ] Multi-queue support (walk-in vs appointment)
- [ ] Priority queue handling
- [ ] Customer queue history
- [ ] Auto-archive old check-ins

### Analytics Opportunities
- Average check-in to start time
- Peak check-in hours
- Device type distribution
- Issue category analysis
- Staff response times
- Customer satisfaction after check-in

## Troubleshooting

### Check-In Not Appearing in Queue
1. Verify CheckIn record created in database
2. Check status is "waiting"
3. Refresh Queue view
4. Check fetch request predicate

### Start Repair Button Not Working
1. Verify customer exists
2. Check form validation
3. Ensure Core Data context available
4. Check ticket number generation

### Notification Not Firing
1. Verify NotificationCenter post in check-in
2. Check notification name matches
3. Ensure observer registered
4. Test with print statements

## Code Examples

### Listen for Check-Ins
```swift
NotificationCenter.default.publisher(for: .customerCheckedIn)
    .sink { notification in
        if let checkInId = notification.userInfo?["checkInId"] as? UUID {
            // Handle new check-in
            print("New customer checked in: \(checkInId)")
        }
    }
```

### Fetch Waiting Check-Ins
```swift
let fetchRequest: NSFetchRequest<CheckIn> = CheckIn.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "status == %@", "waiting")
fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CheckIn.checkedInAt, ascending: true)]

let checkIns = try? viewContext.fetch(fetchRequest)
```

### Create Ticket from Check-In
```swift
let ticket = Ticket(context: viewContext)
ticket.id = UUID()
ticket.customerId = checkIn.customerId
ticket.deviceType = checkIn.deviceType
ticket.issueDescription = checkIn.issueDescription
ticket.status = "in_progress"
ticket.checkedInAt = checkIn.checkedInAt
ticket.startedAt = Date()

checkIn.status = "started"
checkIn.ticketId = ticket.id

try viewContext.save()
```

## Summary

The queue restructure successfully separates customer intake from repair management:

- **Queue Tab** - Portal check-ins awaiting service
- **Repairs Tab** - Active repair tickets being worked on
- **Customer Portal** - Self-service check-in capability
- **Seamless Flow** - Check-in → Queue → Start Repair → Repairs

This creates a more professional, efficient, and scalable workflow for repair shops using the kiosk mode feature.

---

**Implementation Date:** 2025-10-07  
**Version:** 1.0  
**Status:** ✅ Complete and Ready for Testing
