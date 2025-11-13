# Phase 4: Production Configuration Guide

**Date:** November 13, 2025  
**Status:** IN PROGRESS  
**Goal:** Configure ProTech for production launch

---

## 📋 Overview

This guide walks through all Phase 4 tasks to prepare ProTech for App Store submission and production deployment.

**Estimated Time:** 1 week (with all accounts ready)

---

## 🔧 Task 4.1: Update Configuration.swift

### Current State
Your `Configuration.swift` has placeholder values that need to be replaced with production URLs and IDs.

### Required Changes

#### 1. Company/Brand Information

**Current:**
```swift
static let appName = "ProTech"
```

**Action Required:**
- Confirm this is your final app name
- Match exactly with App Store Connect listing
- Consider: "ProTech - Repair Shop Manager" for clarity

#### 2. Subscription Product IDs

**Current (Placeholders):**
```swift
static let monthlySubscriptionID = "com.yourcompany.techstorepro.monthly"
static let annualSubscriptionID = "com.yourcompany.techstorepro.annual"
```

**Update To:**
```swift
static let monthlySubscriptionID = "com.nugentic.protech.monthly"
static let annualSubscriptionID = "com.nugentic.protech.annual"
```

**Steps:**
1. Go to App Store Connect → Your App → Subscriptions
2. Create subscription group (e.g., "ProTech Premium")
3. Create monthly subscription:
   - Product ID: `com.nugentic.protech.monthly`
   - Name: "ProTech Monthly"
   - Duration: 1 month
   - Price: Choose tier (suggest $29.99-49.99/month)
4. Create annual subscription:
   - Product ID: `com.nugentic.protech.annual`
   - Name: "ProTech Annual"
   - Duration: 1 year
   - Price: Choose tier (suggest $299-399/year, ~30% discount)
5. Update Configuration.swift with exact IDs

#### 3. Support URLs

**Current (Placeholders):**
```swift
static let supportURL = URL(string: "https://yourcompany.com/support")!
static let privacyPolicyURL = URL(string: "https://yourcompany.com/privacy")!
static let termsOfServiceURL = URL(string: "https://yourcompany.com/terms")!
```

**Options:**

**Option A: Use Your Domain**
```swift
static let supportURL = URL(string: "https://nugentic.com/protech/support")!
static let privacyPolicyURL = URL(string: "https://nugentic.com/protech/privacy")!
static let termsOfServiceURL = URL(string: "https://nugentic.com/protech/terms")!
```

**Option B: Use Subdomain**
```swift
static let supportURL = URL(string: "https://protech.nugentic.com/support")!
static let privacyPolicyURL = URL(string: "https://protech.nugentic.com/privacy")!
static let termsOfServiceURL = URL(string: "https://protech.nugentic.com/terms")!
```

**Option C: Quick Solution - GitHub Pages**
```swift
static let supportURL = URL(string: "https://nugentic.github.io/protech/support")!
static let privacyPolicyURL = URL(string: "https://nugentic.github.io/protech/privacy")!
static let termsOfServiceURL = URL(string: "https://nugentic.github.io/protech/terms")!
```

**Required:**
- Create these web pages before submitting to App Store
- Apple requires working privacy policy and terms
- Support page can be simple contact form or email

#### 4. Feature Flags - StoreKit

**Current:**
```swift
static let enableStoreKit = false  // ❌ Disabled
```

**Update To:**
```swift
static let enableStoreKit = true  // ✅ Enable for production
```

**Important:**
- Only enable AFTER creating subscription products in App Store Connect
- Test in Sandbox environment first
- Verify subscription flow works before production

#### 5. Bundle Identifier

**Verify in Xcode:**
- Open ProTech.xcodeproj
- Select ProTech target
- General tab → Identity
- Current: `Nugentic.ProTech`
- Confirm matches App Store Connect

---

## 📱 Task 4.2: App Store Connect Setup

### Prerequisites
- [ ] Apple Developer Account ($99/year)
- [ ] Team ID and provisioning profiles
- [ ] App icon (1024x1024px)
- [ ] Screenshots (various sizes)

### Step-by-Step Process

#### Step 1: Create App in App Store Connect

1. **Go to:** https://appstoreconnect.apple.com
2. **Navigate to:** My Apps → + (Plus icon)
3. **Select:** New App
4. **Fill in:**
   - **Platform:** macOS
   - **Name:** ProTech (or your chosen name)
   - **Primary Language:** English (US)
   - **Bundle ID:** com.nugentic.protech (select from dropdown)
   - **SKU:** PROTECH-MACOS-001 (your internal reference)
   - **User Access:** Full Access

#### Step 2: App Information

**Category:**
- Primary: Business
- Secondary: Productivity

**Age Rating:**
- Complete the questionnaire
- Likely result: 4+

**Privacy Policy URL:**
- Enter your privacy policy URL (from Configuration.swift)

**Support URL:**
- Enter your support URL

#### Step 3: Pricing and Availability

**Price:**
- Free (with in-app subscriptions)

**Availability:**
- All territories OR select specific countries
- Suggest: Start with US, Canada, UK, Australia

#### Step 4: App Information Details

**App Name:** ProTech - Repair Shop Manager

**Subtitle (170 chars max):**
"Complete repair shop management for Mac. Tickets, invoicing, inventory & customer tracking."

**Description (4000 chars max):**
```
ProTech is the ultimate repair shop management solution designed exclusively for macOS. Built for independent repair shops, computer service centers, and electronics repair businesses.

KEY FEATURES:

✓ TICKET MANAGEMENT
• Complete repair tracking from check-in to pickup
• Custom repair workflows and status tracking
• Automatic customer notifications
• Internal notes and photo attachments
• Repair history and audit trails

✓ CUSTOMER MANAGEMENT
• Comprehensive customer database
• Communication history tracking
• Device and repair history
• Customer notes and preferences
• Quick search and filtering

✓ INVOICING & PAYMENTS
• Professional invoice generation
• Multiple payment methods
• Receipt printing
• Outstanding balance tracking
• Payment history

✓ ESTIMATES & QUOTES
• Professional estimate creation
• Email delivery with approval tracking
• One-click convert to invoice
• Valid until dates
• Line item management

✓ INVENTORY CONTROL
• Parts and product tracking
• Low stock alerts
• Purchase order management
• Stock adjustment history
• SKU and barcode support

✓ EMPLOYEE MANAGEMENT
• User accounts with role-based permissions
• Time clock with clock in/out
• Employee performance tracking
• Time off request management
• Attendance tracking

✓ POINT OF SALE
• Quick checkout interface
• Receipt printing
• Discount codes and loyalty programs
• Payment processing integration
• Sales reporting

✓ FORMS & DOCUMENTS
• Customizable intake forms
• Digital signature capture
• PDF generation and printing
• Form templates
• Email delivery

✓ SQUARE INTEGRATION
• Sync customers and inventory
• Process payments
• Real-time synchronization
• Conflict resolution
• Webhook support

✓ COMMUNICATIONS
• SMS notifications via Twilio
• Email automation
• Status update notifications
• Appointment reminders
• Marketing campaigns

✓ REPORTING & ANALYTICS
• Revenue and sales reports
• Employee performance metrics
• Inventory usage tracking
• Customer analytics
• Custom date ranges

✓ BACKUP & SYNC
• Supabase cloud backup
• Cross-device synchronization
• Automatic data backup
• Secure encryption

PERFECT FOR:
• Computer repair shops
• Cell phone repair stores
• Electronics service centers
• IT repair businesses
• Small to medium repair shops

SUBSCRIPTION REQUIRED:
ProTech requires a subscription to access all features:
• Monthly: $XX.XX/month
• Annual: $XXX.XX/year (save XX%)

30-DAY FREE TRIAL AVAILABLE

Privacy Policy: [your URL]
Terms of Service: [your URL]
Support: [your URL]
```

**Keywords (100 chars max):**
```
repair,shop,management,invoice,ticket,pos,inventory,customer,business,crm
```

**Promotional Text (170 chars):**
"New: Discount codes, receipt printing, time off management, and enhanced Square integration. Plus hundreds of bug fixes and improvements!"

#### Step 5: App Review Information

**Contact Information:**
- First Name: [Your name]
- Last Name: [Your name]
- Phone: [Your phone with country code]
- Email: [Your email]

**Demo Account (REQUIRED):**
```
Username: demo@protech-app.com
Password: Demo123!
```

**Notes for Reviewer:**
```
ProTech is a repair shop management application for macOS.

To test the app:
1. Login with the demo account provided
2. The app has sample data pre-loaded
3. Test creating a ticket: Click "New Ticket" button
4. Test creating an invoice: Select a ticket → "Generate Invoice"
5. Test payment recording: Open invoice → "Record Payment"
6. POS system: Click "Point of Sale" in sidebar

Subscription Features:
• The demo account has a test subscription active
• You can test all premium features
• Square and Twilio integrations require API keys (optional to test)

If you have any questions, please contact [your email]
```

#### Step 6: Build Upload

**Before uploading:**
1. Set version number (e.g., 1.0.0)
2. Set build number (e.g., 1)
3. Archive build in Xcode:
   - Product → Archive
   - Window → Organizer → Archives
   - Distribute App → App Store Connect
   - Upload

**TestFlight Setup:**
1. After upload, build appears in TestFlight
2. Add internal testers (up to 100)
3. Add external testers (up to 10,000)
4. Beta review (faster than full review)

#### Step 7: Screenshots

**Required Sizes:**
- 1280 x 800 pixels (recommended)
- 1440 x 900 pixels
- 2560 x 1600 pixels
- 2880 x 1800 pixels

**Screenshots to Include:**
1. Dashboard view (main screen)
2. Ticket management
3. Customer management
4. Invoice generation
5. POS interface
6. Reports/analytics (optional)

**Tips:**
- Use clean, professional mockup data
- Show key features
- Include UI annotations/highlights
- Consistent theme/branding

#### Step 8: App Preview Video (Optional but Recommended)

**Specifications:**
- Length: 15-30 seconds
- Format: M4V, MP4, or MOV
- Resolution: Match screenshot sizes
- Size: Max 500 MB

**Content Suggestions:**
- Quick app walkthrough
- Key features highlight
- Smooth transitions
- Professional voiceover (optional)

---

## 🗄️ Task 4.3: Supabase Production Configuration

### Current Setup Review

**Your Current Credentials:**
```swift
// SupabaseConfig.swift
static let supabaseURL = "https://ucpgsubidqbhxstgykyt.supabase.co"
static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**Project:** TechMedics (ucpgsubidqbhxstgykyt)

### Production Checklist

#### 1. Database Optimization

**Tables to Index:**
```sql
-- Add indexes for performance
CREATE INDEX idx_tickets_customer_id ON tickets(customer_id);
CREATE INDEX idx_tickets_status ON tickets(status);
CREATE INDEX idx_tickets_created_at ON tickets(created_at);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_invoices_customer_id ON invoices(customer_id);
CREATE INDEX idx_payments_invoice_id ON payments(invoice_id);
CREATE INDEX idx_employees_email ON employees(email);
```

**Run in Supabase SQL Editor:**
1. Go to: https://supabase.com/dashboard/project/ucpgsubidqbhxstgykyt
2. Navigate to: SQL Editor
3. Execute the index creation queries
4. Verify: Check query performance

#### 2. Row Level Security (RLS)

**CRITICAL: Enable RLS on all tables**

```sql
-- Enable RLS on all tables
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE estimates ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- Create policies (example for customers table)
CREATE POLICY "Users can view their organization's customers"
ON customers FOR SELECT
USING (
  organization_id = (
    SELECT organization_id FROM employees
    WHERE id = auth.uid()
  )
);

CREATE POLICY "Users can insert customers in their organization"
ON customers FOR INSERT
WITH CHECK (
  organization_id = (
    SELECT organization_id FROM employees
    WHERE id = auth.uid()
  )
);

-- Repeat for other tables
```

**Important:**
- Prevents unauthorized data access
- Required for production security
- Apple may reject without proper security

#### 3. Storage Bucket Security

```sql
-- Secure repair-photos bucket
CREATE POLICY "Users can upload photos for their organization"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'repair-photos' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Users can view their organization's photos"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'repair-photos' AND
  auth.role() = 'authenticated'
);

-- Similar for receipts bucket
```

#### 4. Backup Configuration

**Automatic Backups:**
1. Go to: Settings → Database → Backups
2. Enable: Automatic daily backups
3. Retention: 7 days (free tier) or 30 days (pro)
4. Set time: Choose low-traffic period (e.g., 3 AM)

**Manual Backup:**
```bash
# From Supabase Dashboard → Database → Backups
# Click "Download" for manual backup before major changes
```

#### 5. API Rate Limits

**Free Tier Limits:**
- 500 requests per second
- 2GB database size
- 1GB file storage
- 50GB bandwidth per month

**If Exceeding:**
- Upgrade to Pro plan ($25/month)
- Includes: 5GB database, 100GB storage, 250GB bandwidth

**Monitor Usage:**
- Dashboard → Settings → Usage
- Set up alerts for 80% capacity

#### 6. Environment Variables

**Edge Functions Configuration:**

If using Edge Functions (square-proxy), configure secrets:

```bash
# Using Supabase CLI
supabase secrets set SQUARE_ACCESS_TOKEN="your_production_token"
supabase secrets set SQUARE_LOCATION_ID="your_location_id"
```

**Or via Dashboard:**
1. Navigate to: Edge Functions → square-proxy
2. Settings → Secrets
3. Add environment variables

---

## 💳 Task 4.4: Square Production Configuration

### Current Setup

**Environment:** Sandbox (for testing)

### Switch to Production

#### 1. Square Application Setup

**Go to:** https://developer.squareup.com/apps

**Create Production Application:**
1. Click: Create App
2. Name: ProTech Production
3. Description: Repair shop management integration
4. Click: Create Application

**Get Production Credentials:**
1. Open your production app
2. Navigate to: Credentials
3. Copy:
   - **Production Access Token** (starts with `EAAA...`)
   - **Application ID**
   - **Location ID** (from Locations tab)

#### 2. Configure OAuth (Optional)

If using OAuth for customers:

**Redirect URL:**
```
protech://oauth-callback
```

**Add in Square Dashboard:**
1. OAuth → Redirect URL → Add URL
2. Save changes

#### 3. Webhook Configuration

**For real-time sync:**

**Webhook URL:**
```
https://ucpgsubidqbhxstgykyt.supabase.co/functions/v1/square-webhook
```

**Subscribe to Events:**
- `inventory.count.updated`
- `catalog.version.updated`
- `payment.created`
- `payment.updated`
- `refund.created`

**Add in Square Dashboard:**
1. Webhooks → Add Endpoint
2. URL: Your Supabase function URL
3. Select events
4. Copy signature key
5. Save webhook subscription ID

#### 4. Update App Configuration

**In-App Configuration (User will enter):**
- Users configure Square via Settings → Integrations
- Stored in `SquareConfiguration` Core Data entity
- Access token encrypted in keychain

**Default Values:**
- Environment: Production (not Sandbox)
- Base URL: `https://connect.squareup.com` (production)

#### 5. PCI Compliance

**Square Handles:**
- Card data storage
- PCI compliance
- Tokenization

**Your Responsibility:**
- Don't store raw card numbers
- Use Square's payment form
- Follow Square's best practices

**Documentation:**
https://developer.squareup.com/docs/devtools/sandbox/overview

---

## 📊 Task 4.5: Monitoring & Analytics Setup

### Option 1: Basic (Free) - Console Logging

**Already Implemented:**
```swift
// Uses print() statements throughout app
// Viewable in Xcode console during development
```

**Production Logs:**
- macOS Console.app
- User Activity → ProTech logs
- Limited but free

### Option 2: Sentry (Error Tracking)

**Why Sentry:**
- Real-time error tracking
- Stack traces
- User context
- Release tracking
- Free tier: 5,000 events/month

**Setup:**

1. **Create Account:** https://sentry.io
2. **Create Project:** ProTech (platform: macOS/Swift)
3. **Install SDK:**
```bash
# Add to Package.swift dependencies
.package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.0.0")
```

4. **Initialize in ProTechApp.swift:**
```swift
import Sentry

init() {
    SentrySDK.start { options in
        options.dsn = "https://your-dsn@sentry.io/project-id"
        options.tracesSampleRate = 0.1 // 10% performance monitoring
        options.environment = Configuration.isDebug ? "development" : "production"
        options.enableAutoSessionTracking = true
    }
    
    // Your existing init code
    FormService.shared.loadDefaultTemplates()
}
```

5. **Capture Errors:**
```swift
// Automatic crash reporting
// Manual error capture:
SentrySDK.capture(error: error)
```

### Option 3: Mixpanel (Analytics)

**Why Mixpanel:**
- User behavior tracking
- Funnel analysis
- Cohort analysis
- Free tier: 100,000 events/month

**Setup:**

1. **Create Account:** https://mixpanel.com
2. **Get Project Token**
3. **Install SDK:**
```bash
# CocoaPods or SPM
.package(url: "https://github.com/mixpanel/mixpanel-swift", from: "4.0.0")
```

4. **Initialize:**
```swift
import Mixpanel

init() {
    if Configuration.enableAnalytics {
        Mixpanel.initialize(token: "your-project-token")
    }
}
```

5. **Track Events:**
```swift
// Track user actions
Mixpanel.mainInstance().track(event: "Ticket Created")
Mixpanel.mainInstance().track(event: "Invoice Generated", properties: [
    "amount": invoiceTotal,
    "paymentMethod": "cash"
])
```

### Option 4: App Analytics (Built-in Apple)

**Pros:**
- Built into App Store Connect
- Free
- Privacy-focused
- No SDK required

**Metrics Available:**
- Downloads
- Sessions
- Crashes
- App Store views

**Access:**
- App Store Connect → Analytics
- Automatically enabled

### Recommended Approach

**For Launch:**
1. ✅ Use Apple's App Analytics (free, automatic)
2. ✅ Add Sentry for crash reporting (free tier sufficient)
3. ⏸️ Skip Mixpanel initially (add later if needed)

**Why:**
- Minimal setup time
- Free tiers adequate for launch
- Can add more analytics later based on needs

---

## 📝 Configuration File Updates

### File 1: Configuration.swift

**Updated file with production values:**

```swift
//
//  Configuration.swift
//  ProTech
//
//  App configuration and constants
//

import Foundation

struct Configuration {
    // App Information
    static let appName = "ProTech"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - PRODUCTION - Update these values before release
    
    // Subscription Product IDs (Update after creating in App Store Connect)
    static let monthlySubscriptionID = "com.nugentic.protech.monthly"
    static let annualSubscriptionID = "com.nugentic.protech.annual"
    
    // Support URLs (Create these web pages before submitting)
    // Option 1: Use your domain
    static let supportURL = URL(string: "https://nugentic.com/protech/support")!
    static let privacyPolicyURL = URL(string: "https://nugentic.com/protech/privacy")!
    static let termsOfServiceURL = URL(string: "https://nugentic.com/protech/terms")!
    
    // Option 2: Alternative - use subdomain
    // static let supportURL = URL(string: "https://protech.nugentic.com/support")!
    // static let privacyPolicyURL = URL(string: "https://protech.nugentic.com/privacy")!
    // static let termsOfServiceURL = URL(string: "https://protech.nugentic.com/terms")!
    
    static let twilioSignupURL = URL(string: "https://www.twilio.com/try-twilio")!
    
    // Feature Flags
    // ⚠️ Set enableStoreKit = true ONLY after:
    // 1. Creating subscription products in App Store Connect
    // 2. Testing in Sandbox environment
    // 3. Verifying subscription flow works
    static let enableStoreKit = false  // TODO: Set to true for production
    static let enableCloudSync = true
    static let enableAnalytics = true
    static let enableBetaFeatures = false
    
    // MARK: - API Configuration
    
    static let twilioAPIBaseURL = "https://api.twilio.com/2010-04-01"
    
    // MARK: - Formatting
    
    static let dateFormat = "MMM d, yyyy"
    static let dateTimeFormat = "MMM d, yyyy h:mm a"
    static let currencySymbol = "$"
    
    // MARK: - Limits
    
    static let maxCustomersInFreeVersion = -1 // Unlimited
    static let maxSMSPerMonth = -1 // Unlimited (user pays Twilio)
    
    // MARK: - Branding
    
    static let primaryColor = "AccentColor"
    static let companyName = "Nugentic"  // Used in receipts, invoices
    
    // MARK: - Debug
    
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // MARK: - Monitoring (Optional - add when ready)
    
    // static let sentryDSN = "https://your-dsn@sentry.io/project-id"
    // static let mixpanelToken = "your-mixpanel-token"
}

// MARK: - Premium Features

enum PremiumFeature: String, CaseIterable {
    case smsMessaging = "SMS Messaging"
    case customForms = "Custom Forms"
    case printForms = "Print Forms"
    case cloudSync = "Cloud Sync"
    case multiLocation = "Multi-Location"
    case analytics = "Analytics & Reports"
    case inventory = "Inventory Management"
    case advancedSearch = "Advanced Search"
    case teamCollaboration = "Team Collaboration"
    
    var description: String {
        switch self {
        case .smsMessaging:
            return "Send SMS updates to customers via Twilio"
        case .customForms:
            return "Create and customize intake and pickup forms"
        case .printForms:
            return "Generate professional PDFs and print forms"
        case .cloudSync:
            return "Sync data across devices with iCloud"
        case .multiLocation:
            return "Manage multiple store locations"
        case .analytics:
            return "View detailed analytics and generate reports"
        case .inventory:
            return "Track parts and inventory"
        case .advancedSearch:
            return "Advanced filtering and search capabilities"
        case .teamCollaboration:
            return "Multiple users and role-based permissions"
        }
    }
    
    var icon: String {
        switch self {
        case .smsMessaging: return "message.fill"
        case .customForms: return "doc.text.fill"
        case .printForms: return "printer.fill"
        case .cloudSync: return "icloud.fill"
        case .multiLocation: return "building.2.fill"
        case .analytics: return "chart.bar.fill"
        case .inventory: return "shippingbox.fill"
        case .advancedSearch: return "magnifyingglass.circle.fill"
        case .teamCollaboration: return "person.3.fill"
        }
    }
}
```

---

## ✅ Pre-Launch Checklist

### Configuration Files
- [ ] Configuration.swift updated with production values
- [ ] SupabaseConfig.swift verified (already production)
- [ ] Bundle identifier matches App Store Connect
- [ ] Version and build numbers set

### Web Pages
- [ ] Privacy Policy page created and live
- [ ] Terms of Service page created and live
- [ ] Support page created and live
- [ ] All URLs return 200 OK status

### App Store Connect
- [ ] App created in App Store Connect
- [ ] Subscription products created
- [ ] Pricing configured
- [ ] App information filled out
- [ ] Screenshots uploaded (at least 1 per size)
- [ ] App icon uploaded (1024x1024)
- [ ] Demo account created for reviewers
- [ ] Review notes written
- [ ] Build uploaded and processed

### Supabase
- [ ] Database indexes added
- [ ] Row Level Security enabled on all tables
- [ ] RLS policies created
- [ ] Storage bucket policies configured
- [ ] Automatic backups enabled
- [ ] Usage monitoring set up

### Square
- [ ] Production application created
- [ ] Production credentials obtained
- [ ] Webhook endpoint configured (if needed)
- [ ] PCI compliance reviewed

### Testing
- [ ] StoreKit subscriptions tested in Sandbox
- [ ] All core features tested end-to-end
- [ ] Payment flows verified
- [ ] Email/SMS notifications tested
- [ ] Backup/restore tested
- [ ] Performance acceptable with real data

### Monitoring (Optional but Recommended)
- [ ] Sentry project created and configured
- [ ] Error tracking tested
- [ ] Analytics implementation (if using)

---

## 🚀 Launch Timeline

### Week 1: Configuration & Setup
- Days 1-2: Update Configuration.swift
- Days 3-4: Create web pages (privacy, terms, support)
- Day 5: Create App Store Connect listing
- Days 6-7: Upload build, configure subscriptions

### Week 2: Testing & Submission
- Days 1-3: Internal testing with TestFlight
- Day 4: Final bug fixes
- Day 5: Submit for review
- Days 6-14: App Review process (Apple takes 1-7 days typically)

### Post-Submission
- Monitor for App Review questions
- Respond within 24 hours if contacted
- Fix any rejection issues quickly
- Celebrate when approved! 🎉

---

## 📞 Support & Resources

### Apple Resources
- **App Store Connect:** https://appstoreconnect.apple.com
- **Developer Portal:** https://developer.apple.com
- **Support:** https://developer.apple.com/contact/
- **Guidelines:** https://developer.apple.com/app-store/review/guidelines/

### Supabase Resources
- **Dashboard:** https://supabase.com/dashboard
- **Documentation:** https://supabase.com/docs
- **Support:** https://supabase.com/support

### Square Resources
- **Developer Dashboard:** https://developer.squareup.com
- **Documentation:** https://developer.squareup.com/docs
- **Support:** https://developer.squareup.com/forums

---

## 🎯 Next Steps

**After completing this guide:**

1. **Test everything** - Use TestFlight for beta testing
2. **Gather feedback** - Get real users to test
3. **Fix critical bugs** - Address any P0/P1 issues
4. **Submit for review** - Upload to App Store
5. **Plan launch marketing** - Prepare announcement
6. **Monitor post-launch** - Watch for crashes/issues

---

**Status:** Ready to implement!  
**Estimated completion:** 1-2 weeks  
**Blockers:** Need to create web pages (privacy, terms, support)

Good luck with your production launch! 🚀
