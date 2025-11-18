# Reprint Documents Feature

## Feature Added

Added a dedicated **"Print Documents"** section in the Ticket Detail view that allows reprinting of service documents at any time, regardless of ticket status.

## Location

**Ticket Detail View** → Scroll down to **"Print Documents"** section

### How to Access

1. Navigate to **Queue** (or any view with tickets)
2. Click on any ticket to open **Ticket Detail View**
3. Scroll down to the **"Print Documents"** section
4. Two buttons are always available:
   - 📄 **Print Check-In Agreement**
   - 📄 **Print Pickup Form**

## Available Documents

### 1. Print Check-In Agreement

**Purpose:** Service agreement signed by customer at check-in

**When to Use:**
- Customer lost their copy
- Need a duplicate for records
- Original was damaged
- Customer requests a copy

**What's Included:**
- Customer information
- Device details
- Issue description
- Service terms and conditions
- Signature section
- Authorization for repair
- Pricing estimates (if applicable)

**Printer Routing:** 
- Routes to **standard paper printer** (Letter size, 8.5" × 11")
- Uses the new printer routing fix to avoid Dymo label printer

### 2. Print Pickup Form

**Purpose:** Service completion form signed by customer at pickup

**When to Use:**
- Customer is picking up their device
- Need duplicate receipt for records
- Customer lost their pickup slip
- Store copy for filing

**What's Included:**
- Ticket number and pickup date
- Customer information
- Device information and serial number
- Service summary and resolution
- Pickup acknowledgment section
- Customer signature line
- Staff member signature line
- 7-day issue reporting policy
- Warranty terms reference

**Printer Routing:** 
- Routes to **standard paper printer** (Letter size, 8.5" × 11")
- Uses the new printer routing fix to avoid Dymo label printer

## Code Changes

### File Modified: `/ProTech/Views/Queue/TicketDetailView.swift`

#### 1. Added Print Documents Section

**Location:** Between "Barcode" and "Actions" sections (lines 218-231)

```swift
// Print Documents
Section("Print Documents") {
    Button {
        printCheckInAgreement()
    } label: {
        Label("Print Check-In Agreement", systemImage: "doc.text.fill")
    }
    
    Button {
        printPickupForm()
    } label: {
        Label("Print Pickup Form", systemImage: "doc.text.fill")
    }
}
```

#### 2. Added Print Method

**Location:** Private methods section (lines 434-437)

```swift
private func printCheckInAgreement() {
    guard let customer = customer.first else { return }
    DymoPrintService.shared.printCheckInAgreement(ticket: ticket, customer: customer)
}
```

The `printPickupForm()` method already existed and is now used by both locations.

## User Interface

### Before
```
┌─────────────────────────────────┐
│ Barcode                         │
│  • Print Ticket Label           │
│  • Ticket #12345                │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Actions                         │
│  [Status-dependent buttons]     │
│  • Mark as Completed (shows     │
│    Print Pickup Form button)    │
└─────────────────────────────────┘
```

### After
```
┌─────────────────────────────────┐
│ Barcode                         │
│  • Print Ticket Label           │
│  • Ticket #12345                │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Print Documents                 │ ✅ NEW SECTION
│  📄 Print Check-In Agreement    │ ✅ Always Available
│  📄 Print Pickup Form           │ ✅ Always Available
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Actions                         │
│  [Status-dependent buttons]     │
│  • (Print Pickup Form still     │
│    appears when completed)      │
└─────────────────────────────────┘
```

## Benefits

### 1. Always Available
- **Before:** Print Pickup Form only available when status = "completed"
- **After:** Both documents available anytime, any status

### 2. Centralized Location
- All document printing in one dedicated section
- Easy to find and use
- Consistent user experience

### 3. Reprint Capability
- Lost documents can be reprinted
- Multiple copies for records
- Customer requests handled easily

### 4. No Status Dependency
- Don't need to change ticket status to reprint
- Works for archived tickets
- Works for tickets in any stage

## Use Cases

### Use Case 1: Lost Check-In Agreement
**Scenario:** Customer calls saying they lost their check-in paperwork

**Steps:**
1. Open the ticket
2. Scroll to "Print Documents"
3. Click "Print Check-In Agreement"
4. Provide customer with new copy

### Use Case 2: Manager Needs Copy for Records
**Scenario:** Manager needs a copy of the pickup form for filing

**Steps:**
1. Open completed ticket
2. Scroll to "Print Documents"
3. Click "Print Pickup Form"
4. File the copy

### Use Case 3: Customer Disputes Service
**Scenario:** Customer claims they didn't agree to repairs

**Steps:**
1. Open the ticket
2. Scroll to "Print Documents"
3. Click "Print Check-In Agreement"
4. Show customer their signed authorization

### Use Case 4: Insurance Claim Documentation
**Scenario:** Customer needs documentation for insurance

**Steps:**
1. Open the ticket
2. Print both documents:
   - Check-In Agreement (proof of service request)
   - Pickup Form (proof of completion)
3. Provide to customer

## Testing

### Test 1: Print Check-In Agreement
1. Open any ticket (any status)
2. Scroll to "Print Documents"
3. Click "Print Check-In Agreement"
4. **Verify:** Print dialog opens
5. **Verify:** Document shows customer/device info
6. **Verify:** Routes to standard paper printer (not Dymo)

### Test 2: Print Pickup Form
1. Open any ticket (any status)
2. Scroll to "Print Documents"
3. Click "Print Pickup Form"
4. **Verify:** Print dialog opens
5. **Verify:** Document shows pickup acknowledgment
6. **Verify:** Routes to standard paper printer (not Dymo)

### Test 3: Both Buttons Available
1. Open a "waiting" status ticket
2. **Verify:** Both print buttons visible and enabled
3. Change status to "in_progress"
4. **Verify:** Both print buttons still visible
5. Change status to "completed"
6. **Verify:** Both print buttons still visible
7. **Verify:** "Print Pickup Form" also appears in Actions section

### Test 4: No Customer Data
1. Open a ticket with no customer (edge case)
2. Click either print button
3. **Verify:** Handles gracefully (nothing happens or shows error)

### Test 5: Printer Routing
1. Print both documents
2. **Verify:** Both go to standard printer
3. **Verify:** Neither goes to Dymo label printer
4. **Verify:** Console shows routing logs:
   ```
   📄 Routing document 'Service Agreement' to standard printer: [Name]
   📄 Routing document 'Pickup Form' to standard printer: [Name]
   ```

## Related Files

**Modified:**
- `/ProTech/Views/Queue/TicketDetailView.swift` (added section and method)

**Uses (existing, no changes):**
- `/ProTech/Services/DymoPrintService.swift`
  - `printCheckInAgreement(ticket:customer:)` method
  - `printPickupForm(ticket:customer:)` method

**Related Features:**
- `PRINTER_ROUTING_FIX.md` - Ensures documents go to correct printer
- `CheckInPrintDialog.swift` - Original check-in printing
- `RepairProgressView.swift` - Related to completion workflow

## Known Limitations

1. **Customer Required:** 
   - Both print functions require a customer record
   - Silently fails if customer is nil
   - Consider adding user-facing error message

2. **No Preview:**
   - Opens print dialog directly
   - No on-screen preview before printing
   - Users must review in print dialog

3. **No Print History:**
   - Doesn't track when documents were reprinted
   - No audit log of print operations
   - Consider adding to notes/timeline

## Future Enhancements

Possible improvements:
- [ ] Add print history/audit log
- [ ] Show preview before printing
- [ ] Export as PDF option
- [ ] Email document to customer
- [ ] Batch print multiple tickets
- [ ] Custom templates per store
- [ ] Error message if customer missing
- [ ] Print counter badge (e.g., "Printed 3 times")

## Comparison: Print Locations

### Check-In Agreement

**Location 1 (Original):** Check-In Process
- **When:** During initial customer check-in
- **Where:** `CheckInPrintDialog` after check-in complete
- **Purpose:** Print at time of service request
- **Printer:** Standard printer ✅

**Location 2 (New):** Ticket Detail View
- **When:** Anytime after check-in
- **Where:** "Print Documents" section
- **Purpose:** Reprint as needed
- **Printer:** Standard printer ✅

### Pickup Form

**Location 1 (Original):** Actions Section
- **When:** Only when status = "completed"
- **Where:** Actions section in Ticket Detail
- **Purpose:** Print when ready for pickup
- **Printer:** Standard printer ✅
- **Note:** This button still exists for workflow convenience

**Location 2 (New):** Print Documents Section
- **When:** Anytime, any status
- **Where:** "Print Documents" section
- **Purpose:** Reprint as needed
- **Printer:** Standard printer ✅

## Implementation Notes

### Why Two Pickup Form Buttons?

The pickup form button appears in **two locations** by design:

1. **Actions Section (Status-dependent):**
   - Part of the completion workflow
   - Appears when marking ticket complete
   - Encourages printing at right time
   - Stays visible for "completed" tickets

2. **Print Documents Section (Always available):**
   - For reprinting later
   - Works regardless of status
   - Handles lost documents
   - Manager/staff convenience

This dual approach balances **workflow guidance** (print at completion) with **flexibility** (reprint anytime).

---

**Added Date:** November 17, 2024  
**Status:** ✅ Complete - Ready to Use  
**Priority:** Medium (Convenience feature)  
**Impact:** Document reprinting workflow
