# Square Integration Setup Guide

## Quick Start

This guide will walk you through setting up the Square inventory sync integration in ProTech.

---

## Prerequisites

1. **Square Developer Account**
   - Sign up at [Square Developer Portal](https://developer.squareup.com/)
   - Create a new application

2. **Square Application Credentials**
   - Application ID (Client ID)
   - Application Secret (Client Secret)
   - Access Token (for testing)

3. **ProTech Requirements**
   - macOS 13.0 or later
   - Xcode 15.0 or later
   - Active internet connection

---

## Step 1: Create Square Application

### 1.1 Sign Up for Square Developer Account

1. Go to [https://developer.squareup.com/](https://developer.squareup.com/)
2. Click "Sign Up" or "Get Started"
3. Complete the registration process

### 1.2 Create New Application

1. Log in to Square Developer Dashboard
2. Click "Create App" or "New Application"
3. Enter application details:
   - **Name**: ProTech Inventory Sync
   - **Description**: Inventory synchronization for ProTech
4. Click "Create Application"

### 1.3 Get Application Credentials

1. In your application dashboard, navigate to "Credentials"
2. Copy the following:
   - **Application ID** (also called Client ID)
   - **Application Secret** (keep this secure!)
3. Note your **Sandbox Access Token** for testing

### 1.4 Configure OAuth Settings

1. In application settings, find "OAuth" section
2. Add Redirect URL:
   ```
   protech://square-oauth-callback
   ```
3. Select required permissions:
   - ✅ ITEMS_READ
   - ✅ ITEMS_WRITE
   - ✅ INVENTORY_READ
   - ✅ INVENTORY_WRITE
   - ✅ MERCHANT_PROFILE_READ
4. Save changes

---

## Step 2: Configure ProTech

### 2.1 Update Application Credentials

1. Open ProTech project in Xcode
2. Navigate to `ProTech/Services/SquareAPIService.swift`
3. Update the following constants:

```swift
private let clientId = "YOUR_SQUARE_APPLICATION_ID"
private let clientSecret = "YOUR_SQUARE_APPLICATION_SECRET"
```

⚠️ **Security Note**: In production, store `clientSecret` in Keychain, not in code!

### 2.2 Configure URL Scheme

1. In Xcode, select ProTech target
2. Go to "Info" tab
3. Expand "URL Types"
4. Add new URL Type:
   - **Identifier**: `com.protech.square`
   - **URL Schemes**: `protech`
   - **Role**: Editor

### 2.3 Update Info.plist

Add the following to your `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>squareup.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        <key>squareupsandbox.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

---

## Step 3: First-Time Setup

### 3.1 Launch ProTech

1. Build and run ProTech
2. Navigate to **Settings → Integrations → Square**

### 3.2 Connect to Square

1. Click "Connect to Square" button
2. You'll be redirected to Square's OAuth page
3. Log in with your Square account
4. Review and approve permissions
5. You'll be redirected back to ProTech

### 3.3 Select Location

1. After connection, select your primary Square location
2. This is where inventory will be synced

### 3.4 Configure Sync Settings

1. **Enable Auto-Sync**: Toggle on for automatic synchronization
2. **Sync Interval**: Choose how often to sync (recommended: 1 hour)
3. **Sync Direction**: 
   - **Bidirectional**: Sync both ways (recommended)
   - **To Square**: Only push ProTech changes to Square
   - **From Square**: Only pull Square changes to ProTech
4. **Conflict Resolution**:
   - **Most Recent Wins**: Use newest data (recommended)
   - **Square Wins**: Always prefer Square data
   - **ProTech Wins**: Always prefer ProTech data
   - **Manual**: Require manual resolution

---

## Step 4: Initial Data Sync

### 4.1 Choose Sync Direction

Decide which system has the "source of truth":

**Option A: Import from Square**
- Use if Square has your complete inventory
- ProTech will import all Square items

**Option B: Export to Square**
- Use if ProTech has your complete inventory
- Square will receive all ProTech items

**Option C: Bidirectional**
- Use if both systems have partial data
- Items will be matched by SKU and merged

### 4.2 Perform Initial Sync

#### Import from Square:
1. Navigate to **Inventory → Square Sync**
2. Click menu (⋯) → "Import from Square"
3. Confirm the import
4. Wait for completion (progress bar shows status)

#### Export to Square:
1. Navigate to **Inventory → Square Sync**
2. Click menu (⋯) → "Export to Square"
3. Confirm the export
4. Wait for completion

#### Sync All Items:
1. Navigate to **Inventory → Square Sync**
2. Click "Sync All" button
3. System will intelligently sync based on your settings

### 4.3 Review Sync Results

1. Check the sync dashboard for statistics
2. Review "Recent Activity" for any errors
3. Check for conflicts (if any)

---

## Step 5: Ongoing Usage

### 5.1 Automatic Sync

Once configured, ProTech will automatically sync at your chosen interval:
- Changes in ProTech → automatically pushed to Square
- Changes in Square → automatically pulled to ProTech
- Conflicts → resolved based on your strategy

### 5.2 Manual Sync

You can manually trigger sync anytime:
1. Navigate to **Inventory → Square Sync**
2. Click "Sync All" for full sync
3. Or sync individual items from item details

### 5.3 Monitor Sync Status

Dashboard shows:
- **Total Items**: Number of items being synced
- **Synced**: Successfully synchronized items
- **Pending**: Items waiting to sync
- **Failed**: Items with sync errors
- **Recent Activity**: Log of all sync operations

---

## Step 6: Webhooks (Optional - Advanced)

Webhooks enable real-time sync when changes occur in Square.

### 6.1 Development Setup (Using ngrok)

1. Install ngrok:
   ```bash
   brew install ngrok
   ```

2. Start ProTech webhook server (in debug mode)

3. Expose local server:
   ```bash
   ngrok http 8080
   ```

4. Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`)

5. In Square Developer Dashboard:
   - Go to Webhooks
   - Add webhook subscription
   - URL: `https://abc123.ngrok.io/webhook`
   - Events: Select inventory and catalog events
   - Save

### 6.2 Production Setup

For production, use a proper web server or cloud function:
- AWS Lambda
- Google Cloud Functions
- Azure Functions
- Your own server with HTTPS

---

## Troubleshooting

### Connection Issues

**Problem**: "Not Connected" or "Unauthorized"

**Solutions**:
1. Verify application credentials are correct
2. Check OAuth redirect URL matches exactly
3. Ensure all required permissions are granted
4. Try disconnecting and reconnecting
5. Check access token hasn't expired

### Sync Failures

**Problem**: Items not syncing or sync errors

**Solutions**:
1. Check internet connection
2. Verify Square location is selected
3. Check sync logs for specific errors
4. Ensure items have valid SKUs
5. Check for duplicate SKUs
6. Verify inventory quantities are valid

### Conflicts

**Problem**: Sync conflicts appearing

**Solutions**:
1. Review conflicting fields
2. Choose appropriate resolution strategy
3. Manually resolve if needed
4. Consider changing default conflict resolution
5. Ensure timestamps are accurate

### Performance Issues

**Problem**: Slow sync or timeouts

**Solutions**:
1. Reduce sync frequency
2. Sync during off-peak hours
3. Use batch operations for large datasets
4. Check network speed
5. Monitor API rate limits

### Missing Items

**Problem**: Items in Square not appearing in ProTech

**Solutions**:
1. Perform "Import from Square"
2. Check if items have variations
3. Verify item type is supported
4. Check sync logs for errors
5. Ensure items aren't deleted/archived

---

## Best Practices

### 1. Data Hygiene

- **Use unique SKUs**: Every item should have a unique SKU
- **Consistent naming**: Use same naming conventions in both systems
- **Regular cleanup**: Remove obsolete items
- **Accurate quantities**: Keep inventory counts accurate

### 2. Sync Strategy

- **Start with sandbox**: Test thoroughly before production
- **Initial sync during off-hours**: Large syncs can take time
- **Monitor first few syncs**: Watch for issues early
- **Set appropriate interval**: Balance freshness vs. performance
- **Use webhooks for real-time**: If you need instant updates

### 3. Conflict Management

- **Choose consistent strategy**: Stick with one approach
- **Most Recent usually best**: Honors latest changes
- **Manual for critical items**: High-value items may need review
- **Document decisions**: Keep notes on conflict resolutions

### 4. Security

- **Protect credentials**: Never commit secrets to version control
- **Use Keychain**: Store tokens securely
- **Rotate tokens**: Periodically refresh access tokens
- **Monitor access**: Review API usage regularly
- **HTTPS only**: Never use HTTP for webhooks

### 5. Monitoring

- **Check dashboard daily**: Quick health check
- **Review sync logs**: Catch issues early
- **Set up alerts**: For critical failures
- **Track statistics**: Monitor sync success rate
- **Test periodically**: Verify sync is working

---

## API Rate Limits

Square enforces rate limits:
- **100 requests per second** per application
- **Burst allowance** for temporary spikes
- **429 errors** when limit exceeded

ProTech handles this automatically with:
- Exponential backoff retry
- Request queuing
- Batch operations where possible

---

## Data Mapping

### ProTech → Square

| ProTech Field | Square Field |
|--------------|--------------|
| Name | Item Name |
| SKU | Variation SKU |
| Price | Variation Price |
| Quantity | Inventory Count |
| Reorder Point | Alert Threshold |
| Notes | Description |
| Category | Category ID |

### Square → ProTech

| Square Field | ProTech Field |
|--------------|---------------|
| Item Name | Name |
| Variation SKU | SKU |
| Variation Price | Price |
| Inventory Count | Quantity |
| Alert Threshold | Reorder Point |
| Description | Notes |
| Category ID | Category |

---

## Support Resources

### Documentation
- [Square API Reference](https://developer.squareup.com/reference/square)
- [Square Inventory Guide](https://developer.squareup.com/docs/inventory-api/what-it-does)
- [OAuth Guide](https://developer.squareup.com/docs/oauth-api/overview)

### Community
- [Square Developer Forums](https://developer.squareup.com/forums)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/square-connect)

### ProTech Support
- Check sync logs in the app
- Review this documentation
- Contact ProTech support

---

## Frequently Asked Questions

### Q: Can I sync multiple Square locations?
A: Currently, ProTech syncs with one primary location. Multi-location support is planned for future releases.

### Q: What happens if I delete an item in Square?
A: By default, the item remains in ProTech but the mapping is removed. You can configure auto-deletion in settings.

### Q: Can I sync only certain items?
A: Yes, you can disable sync for specific items in the item details view.

### Q: How do I handle items with variations?
A: ProTech syncs the first variation. Full variation support is planned for future releases.

### Q: Is my data secure?
A: Yes, all communication uses HTTPS, tokens are encrypted, and we follow Square's security best practices.

### Q: Can I undo a sync?
A: Sync operations cannot be undone. Always test in sandbox first and backup your data.

### Q: What if both systems are updated at the same time?
A: This creates a conflict. ProTech will resolve it based on your conflict resolution strategy.

### Q: How much does Square API access cost?
A: Square API access is free. You only pay standard Square transaction fees.

---

## Changelog

### Version 1.0 (Current)
- Initial release
- OAuth authentication
- Bidirectional sync
- Conflict resolution
- Auto-sync scheduling
- Webhook support (beta)
- Sync dashboard

### Planned Features
- Multi-location support
- Full variation support
- Category mapping
- Tax mapping
- Modifier support
- Advanced filtering
- Sync scheduling rules
- Mobile app support

---

## Getting Help

If you encounter issues not covered in this guide:

1. **Check Sync Logs**: Most issues are logged with details
2. **Test Connection**: Use "Test Connection" button in settings
3. **Review Square Dashboard**: Check for API errors
4. **Sandbox Testing**: Reproduce issue in sandbox environment
5. **Contact Support**: Provide sync logs and error messages

---

*Last Updated: 2025-10-02*  
*Version: 1.0*
