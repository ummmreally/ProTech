# Square Customer Sync Guide

**Feature:** Customer synchronization between ProTech and Square  
**Status:** ✅ Ready to use  
**Last Updated:** 2025-10-04

---

## Overview

ProTech now supports syncing customers between your local database and Square! This allows you to:

- **Import customers** from Square into ProTech
- **Export customers** from ProTech to Square  
- **Keep both systems in sync** with bidirectional updates
- **Smart matching** by email or phone number
- **Track sync status** for each customer

---

## Features

### 🔄 Three Sync Modes

1. **Import from Square**
   - Pulls all customers from Square into ProTech
   - Updates existing customers if they already exist
   - Safe: Won't delete any local customers

2. **Export to Square**
   - Pushes ProTech customers to Square
   - Only exports customers not yet synced
   - Creates new customer profiles in Square

3. **Sync All (Bidirectional)**
   - First imports from Square
   - Then exports new ProTech customers
   - Keeps both systems perfectly aligned

### 📊 Real-time Statistics

View live stats in the sync interface:
- Total local customers
- Customers synced with Square
- Customers not yet synced
- Import/export/update counts

### 🔍 Smart Matching

The system intelligently matches customers by:
- Square Customer ID (primary)
- Email address (fallback)
- Phone number (fallback)

---

## Getting Started

### Prerequisites

✅ Square API credentials configured (see `SQUARE_CREDENTIALS_SETUP_GUIDE.md`)  
✅ Square permissions: `CUSTOMERS_READ`, `CUSTOMERS_WRITE`

### Accessing Customer Sync

1. Open **Settings**
2. Navigate to **Square Integration**
3. Click **"Customer Sync"** from the actions menu
4. Or go to **Settings → Square Integration → Customer Sync**

---

## How to Use

### First-Time Setup

#### If you have customers in Square only:

1. Click **"Import from Square"**
2. Confirm the import
3. Wait for sync to complete
4. Verify customers appear in ProTech

**Result:** All Square customers are now in ProTech

#### If you have customers in ProTech only:

1. Click **"Export to Square"**
2. Confirm the export
3. Wait for sync to complete
4. Check Square Dashboard to verify

**Result:** All ProTech customers are now in Square

#### If you have customers in both systems:

1. Click **"Sync All"**
2. Confirm bidirectional sync
3. System will merge intelligently
4. Review sync results

**Result:** Both systems contain all customers

---

## Sync Process Details

### Import from Square

```
Square → ProTech
```

**What happens:**
1. Fetches all customers from Square (paginated)
2. For each Square customer:
   - Checks if customer exists locally (by Square ID)
   - Creates new if not found
   - Updates existing if found
3. Saves all changes to ProTech database

**Fields imported:**
- First name (`given_name`)
- Last name (`family_name`)
- Email address
- Phone number
- Address (formatted as single string)
- Notes

### Export to Square

```
ProTech → Square
```

**What happens:**
1. Finds all ProTech customers without Square ID
2. For each customer:
   - Creates new customer in Square
   - Stores Square Customer ID locally
   - Marks as synced
3. Saves mapping to database

**Fields exported:**
- First name
- Last name
- Email address
- Phone number
- Address
- Notes
- Reference ID (ProTech UUID)

### Bidirectional Sync

```
Square ⟷ ProTech
```

**What happens:**
1. **Phase 1:** Import from Square (updates existing)
2. **Phase 2:** Export to Square (new customers only)
3. Final result: Complete parity

---

## Customer Matching Logic

### Priority Order:

1. **Square Customer ID** (most reliable)
   - Direct match in local database
   - Used for updates

2. **Email Address** (exact match)
   - If Square ID not found
   - Prevents duplicates

3. **Phone Number** (exact match)
   - If email not found
   - E.164 format matching

4. **Create New**
   - If no matches found
   - Generates new UUID

---

## API Endpoints Used

### Square Customers API

- `GET /v2/customers` - List all customers
- `POST /v2/customers/search` - Search customers
- `GET /v2/customers/{id}` - Get specific customer
- `POST /v2/customers` - Create customer
- `PUT /v2/customers/{id}` - Update customer
- `DELETE /v2/customers/{id}` - Delete customer

---

## Monitoring Sync Progress

### Live Progress Indicators

- **Status Badge:** Shows current sync state (Idle/Syncing/Completed/Error)
- **Progress Bar:** Shows percentage complete during sync
- **Current Operation:** Displays current step (e.g., "Fetching customers from Square...")
- **Item Count:** Shows how many customers processed

### Post-Sync Statistics

After sync completes, view detailed results:
- **Imported:** Customers pulled from Square
- **Exported:** Customers pushed to Square
- **Updated:** Existing customers modified
- **Failed:** Errors encountered (with details)

### Sync History

- **Last Sync Date:** Shown with relative time (e.g., "2 hours ago")
- **View Sync History:** Detailed breakdown of last sync

---

## Troubleshooting

### "Not Connected" Error

**Problem:** Square API not configured  
**Solution:** Enter Square credentials first (Settings → Square Integration → Enter Credentials)

### "notConfigured" Error

**Problem:** Missing API configuration  
**Solution:** Reconnect to Square with valid access token

### "unauthorized" Error

**Problem:** Token expired or invalid  
**Solution:** 
1. Disconnect from Square
2. Reconnect with fresh token
3. Ensure token has `CUSTOMERS_READ` and `CUSTOMERS_WRITE` permissions

### Duplicate Customers

**Problem:** Same customer appears multiple times  
**Solution:**
1. Check if customers have different emails/phones
2. Manually merge in ProTech
3. Re-sync after cleanup

### Partial Sync (Some Customers Missing)

**Problem:** Not all customers imported  
**Solution:**
1. Check sync logs for errors
2. Verify customer data in Square (all customers must have at least one field: name, email, or phone)
3. Try sync again

### Rate Limit Exceeded

**Problem:** Too many requests to Square API  
**Solution:**
1. Wait a few minutes
2. Sync will auto-retry with exponential backoff
3. Consider syncing during off-peak hours

---

## Best Practices

### 🎯 Initial Setup

1. **Test with Sandbox First**
   - Use Square sandbox environment
   - Verify sync behavior
   - Then switch to production

2. **Backup Before First Sync**
   - Export ProTech customers to CSV
   - Document current state
   - Test with small dataset first

3. **Review After Sync**
   - Check customer count matches
   - Verify data integrity
   - Look for unexpected changes

### 🔄 Ongoing Usage

1. **Regular Syncing**
   - Sync daily or weekly
   - Use "Sync All" for regular updates
   - Monitor for conflicts

2. **Clean Data**
   - Remove duplicate entries
   - Standardize phone formats
   - Validate email addresses

3. **Monitor Stats**
   - Check "Not Synced" count regularly
   - Investigate failed syncs
   - Keep sync logs

### ⚠️ What to Avoid

❌ **Don't sync during peak hours** - May hit rate limits  
❌ **Don't create duplicates manually** - Use smart matching  
❌ **Don't delete Square ID fields** - Breaks sync mapping  
❌ **Don't interrupt active sync** - May leave incomplete state

---

## Advanced Features

### Smart Customer Lookup

Programmatically find and sync individual customers:

```swift
// Find customer by email
let customer = try await syncManager.syncCustomerByEmail("john@example.com")

// Find customer by phone
let customer = try await syncManager.syncCustomerByPhone("+12065551234")
```

### Sync Statistics

Get detailed counts programmatically:

```swift
let total = syncManager.getLocalCustomersCount()
let synced = syncManager.getSyncedCustomersCount()
let unsynced = syncManager.getUnsyncedCustomersCount()
```

---

## Data Mapping

### ProTech ↔ Square Field Mapping

| ProTech Field | Square Field | Notes |
|---------------|--------------|-------|
| `firstName` | `given_name` | Optional |
| `lastName` | `family_name` | Optional |
| `email` | `email_address` | Optional |
| `phone` | `phone_number` | E.164 format |
| `address` | `address` (formatted) | Single string |
| `notes` | `note` | Optional |
| `id` (UUID) | `reference_id` | ProTech tracking |
| `squareCustomerId` | `id` | Square tracking |

### Address Handling

ProTech stores addresses as single strings. Square supports structured addresses:
- Address Line 1, 2, 3
- City, State, ZIP
- Country

**Current behavior:** ProTech address exported to Square as `address_line_1`

---

## Performance

### Expected Sync Times

- **100 customers:** ~10-20 seconds
- **500 customers:** ~45-60 seconds
- **1,000 customers:** ~2-3 minutes
- **5,000+ customers:** ~10-15 minutes

*Times vary based on network speed and Square API response times*

### Rate Limiting

- Square API allows ~100 requests/second
- ProTech auto-throttles to stay within limits
- Pauses 0.1s every 10 customers during export
- Exponential backoff on rate limit errors

---

## Security & Privacy

### Data Storage

- Square Customer IDs stored in ProTech database
- API tokens stored in macOS Keychain (encrypted)
- No customer data transmitted outside Square ↔ ProTech

### Permissions Required

- `CUSTOMERS_READ` - To import from Square
- `CUSTOMERS_WRITE` - To export to Square
- `MERCHANT_PROFILE_READ` - To verify connection

### GDPR/Privacy Considerations

- Customer data synced between systems
- Deletions must be handled manually in both systems
- Consider data retention policies
- Inform customers of data sync

---

## FAQ

**Q: Will syncing delete any customers?**  
A: No. Sync only adds or updates, never deletes.

**Q: What if I have the same customer in both systems?**  
A: The system matches by email/phone and updates instead of creating duplicates.

**Q: Can I sync only some customers?**  
A: Currently, sync is all-or-nothing. Individual sync coming in future updates.

**Q: What happens if sync fails midway?**  
A: Already-synced customers are saved. Re-run sync to continue where it left off.

**Q: Can I undo a sync?**  
A: Not automatically. Backup your data before first sync.

**Q: How do I know which customers are synced?**  
A: Check the "Synced with Square" count in the stats section. Synced customers have a `squareCustomerId`.

**Q: Do I need Square POS to use this?**  
A: No. Only need a Square developer account with API access.

**Q: What about customer groups/segments?**  
A: Not currently synced. This may be added in future versions.

**Q: Can I sync to multiple Square locations?**  
A: Customers in Square are merchant-level, not location-specific. One sync covers all locations.

---

## Related Guides

- [Square Credentials Setup Guide](SQUARE_CREDENTIALS_SETUP_GUIDE.md) - How to get API credentials
- [Square Inventory Sync](SQUARE_INVENTORY_SYNC_IMPLEMENTATION_PLAN.md) - Inventory sync documentation
- [Twilio Integration](TWILIO_INTEGRATION_GUIDE.md) - SMS notifications for customers

---

## Changelog

### Version 1.0 (2025-10-04)
- ✅ Initial customer sync implementation
- ✅ Import from Square
- ✅ Export to Square
- ✅ Bidirectional sync
- ✅ Smart matching by email/phone
- ✅ Real-time sync progress
- ✅ Sync statistics and history

### Future Enhancements
- 🔮 Selective customer sync (by filter)
- 🔮 Customer group/segment sync
- 🔮 Automated conflict resolution
- 🔮 Customer custom attributes sync
- 🔮 Webhook support for real-time updates
- 🔮 Sync scheduling (daily/weekly auto-sync)

---

## Support

If you encounter issues:

1. Check this guide's troubleshooting section
2. Review sync logs in Settings → Square Integration
3. Test with Square sandbox environment
4. Verify API permissions in Square Developer Dashboard
5. Check [Square API Status](https://status.squareup.com/)

---

**Happy Syncing!** 🎉

Keep your customers in perfect harmony between ProTech and Square.
