# Customer Portal - Quick Start Guide

## For Shop Owners

### Setup (5 minutes)

1. **Add Portal to Main Menu**
   ```swift
   // In your main navigation view
   NavigationLink(destination: CustomerPortalLoginView()) {
       Label("Customer Portal", systemImage: "person.circle.fill")
   }
   ```

2. **Test the Portal**
   - Find a customer with email/phone
   - Login using their email
   - Verify data displays correctly

3. **Share with Customers**
   - Tell customers: "Check your repair status online!"
   - Provide email or phone used at check-in

---

## For Customers

### Access Portal (3 steps)

1. **Open ProTech App** → Click "Customer Portal"
2. **Enter Email or Phone** → Use info from check-in
3. **View Your Info** → Repairs, invoices, estimates, payments

### What You Can Do

- ✅ Track repair status in real-time
- ✅ View and download invoices
- ✅ Approve or decline estimates
- ✅ See payment history
- ✅ Check outstanding balances

---

## Common Tasks

### Approve an Estimate
1. Login to portal
2. Click "Estimates" tab
3. Click estimate to view details
4. Click "Approve" button
5. Confirm approval

### View Repair Status
1. Login to portal
2. Click "My Repairs" tab
3. Click repair for details
4. See timeline and current status

### Check Balance
1. Login to portal
2. View "Financial Summary" on Overview
3. See "Outstanding Balance"

---

## Features at a Glance

| Feature | Description |
|---------|-------------|
| **Overview** | Dashboard with stats and quick actions |
| **My Repairs** | All repairs with status tracking |
| **Invoices** | View and download invoices |
| **Estimates** | Approve/decline repair estimates |
| **Payments** | Complete payment history |

---

## Status Colors

- 🟢 **Green** - Completed, Paid, Approved
- 🔵 **Blue** - In Progress, Pending
- 🟠 **Orange** - Waiting, Needs Attention
- 🔴 **Red** - Overdue, Declined
- ⚪ **Gray** - Expired, Picked Up

---

## Integration

### Listen for Estimate Actions

```swift
// In your admin view
.onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { notification in
    // Customer approved estimate
    if let estimateId = notification.userInfo?["estimateId"] as? UUID {
        print("Estimate approved: \(estimateId)")
    }
}

.onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { notification in
    // Customer declined estimate
    if let estimateId = notification.userInfo?["estimateId"] as? UUID,
       let reason = notification.userInfo?["reason"] as? String {
        print("Estimate declined: \(estimateId) - Reason: \(reason)")
    }
}
```

---

## Files Created

```
ProTech/
├── Services/
│   └── CustomerPortalService.swift          # Portal business logic
├── Views/Customers/
│   ├── CustomerPortalView.swift             # Main portal interface
│   ├── CustomerPortalComponents.swift       # UI components
│   └── CustomerPortalLoginView.swift        # Authentication
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Can't login | Verify email/phone matches check-in record |
| No data showing | Ensure customer has tickets/invoices |
| Estimates missing | Check estimate is assigned to customer |
| Slow performance | Check Core Data indexes are enabled |

---

## Next Steps

1. ✅ Test portal with real customer data
2. ✅ Train staff on portal availability
3. ✅ Add portal info to email signatures
4. ✅ Include portal access in receipts
5. ✅ Monitor estimate approval rates

---

## Support

For detailed information, see `CUSTOMER_PORTAL_COMPLETE.md`

**The Customer Portal is ready to use!** 🎉
