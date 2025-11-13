# Missing Core Data Entities - Complete List

## Problem
The Core Data model (`.xcdatamodeld`) is missing many entity definitions that have Swift model files.

## Entities Already in Model ✅
1. Customer
2. Employee  
3. Ticket
4. Payment
5. Invoice
6. Estimate
7. Appointment
8. InventoryItem
9. CheckIn
10. LoyaltyProgram
11. LoyaltyTier
12. LoyaltyReward
13. LoyaltyMember
14. FormTemplate
15. FormSubmission
16. PurchaseOrder
17. SMSMessage
18. SquareConfiguration (just added)
19. SquareSyncMapping (just added)
20. SyncLog (just added)
21. TimeClockEntry (just added)

## Missing Entities ❌

### Critical (Likely to cause crashes):
1. **TimeEntry** - Ticket time tracking
2. **TicketNote** - Ticket notes/comments
3. **EstimateLineItem** - Estimate line items
4. **InvoiceLineItem** - Invoice line items
5. **RepairPartUsage** - Parts used in repairs
6. **RepairProgress** - Repair stage tracking
7. **RepairStageRecord** - Stage history
8. **NotificationLog** - Notification history
9. **Transaction** - Payment transactions

### Secondary (May cause crashes in specific features):
10. **Supplier** - Inventory suppliers
11. **StockAdjustment** - Inventory adjustments
12. **LoyaltyTransaction** - Loyalty point transactions
13. **PaymentMethod** - Customer payment methods
14. **PurchaseHistory** - Purchase tracking
15. **RecurringInvoice** - Recurring billing

### Optional (Marketing/Advanced features):
16. **Campaign** - Marketing campaigns
17. **MarketingRule** - Marketing automation
18. **CampaignSendLog** - Campaign tracking
19. **NotificationRule** - Notification automation
20. **TimeOffRequest** - Employee time off
21. **EmployeeSchedule** - Employee scheduling

## Automated Solution

I will add ALL missing entities to prevent future crashes.

**Total entities to add**: 21
