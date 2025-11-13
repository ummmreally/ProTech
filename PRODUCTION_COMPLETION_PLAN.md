# ProTech macOS App - Production Completion Plan

**Created:** November 12, 2025  
**Target Completion:** TBD  
**Current Status:** ~75% Complete

---

## Executive Summary

This plan consolidates all outstanding work needed to complete the ProTech macOS app for production launch. Based on audit findings and fix documentation, we have organized tasks into 5 phases focusing on critical blockers first, then core features, polish, production prep, and finally testing/launch.

**Completion Estimate:** 
- Phase 1 (Critical): 1-2 weeks
- Phase 2 (Core): 2-3 weeks  
- Phase 3 (Polish): 1-2 weeks
- Phase 4 (Production): 1 week
- Phase 5 (Testing): 1-2 weeks
- **Total: 6-10 weeks**

---

## Phase 1: Critical Blockers (MUST FIX)

*Priority: 🔴 CRITICAL - App cannot launch to production without these*

### 1.1 Core Data Model Completion

**Issue:** Missing entities causing crashes and disabled features  
**Impact:** App launches but many features disabled  
**Files:** `ProTech.xcdatamodeld`

**Tasks:**
- [ ] Add `FormTemplate` entity with attributes:
  - `id` (UUID, required)
  - `name` (String)
  - `type` (String)
  - `templateJSON` (String)
  - `isDefault` (Boolean)
  - `createdAt`, `updatedAt` (Date)

- [ ] Add `Payment` entity:
  - `id`, `customerId`, `invoiceId` (UUID)
  - `amount` (Decimal)
  - `paymentMethod` (String)
  - `paymentDate`, `createdAt` (Date)

- [ ] Add `Invoice` entity:
  - `id`, `customerId` (UUID)
  - `invoiceNumber` (String)
  - `total`, `balance` (Decimal)
  - `status` (String)
  - `issueDate`, `dueDate` (Date)

- [ ] Add `Estimate` entity:
  - `id`, `customerId` (UUID)
  - `estimateNumber` (String)
  - `status` (String)
  - `total` (Decimal)
  - `createdAt`, `expiresAt` (Date)

- [ ] Add `Appointment` entity:
  - `id`, `customerId`, `employeeId` (UUID)
  - `scheduledDate` (Date)
  - `status`, `appointmentType` (String)
  - `notes` (String)

- [ ] Add `CheckIn` entity:
  - `id`, `customerId`, `ticketId` (UUID)
  - `checkInDate` (Date)
  - `deviceInfo`, `issueDescription` (String)

**Verification:**
- [ ] Build succeeds without entity errors
- [ ] Dashboard loads all widgets
- [ ] Form templates system initializes
- [ ] No Core Data fetch crashes

---

### 1.2 Dashboard Metrics Re-enablement

**Issue:** Dashboard shows $0 for all financial metrics  
**Impact:** Critical business intelligence missing  
**Files:** `Services/DashboardMetricsService.swift`

**Tasks:**
- [ ] Uncomment `getTodayRevenue()` (line ~50)
- [ ] Uncomment `getWeekRevenue()` (line ~70)
- [ ] Uncomment `getMonthRevenue()` (line ~90)
- [ ] Uncomment `getOutstandingBalance()` (line ~120)
- [ ] Uncomment `getAverageTicketValue()` (line ~140)
- [ ] Uncomment `getPendingEstimates()` (line ~160)
- [ ] Uncomment `getUnpaidInvoices()` (line ~180)
- [ ] Uncomment `getTodayAppointments()` (line ~200)
- [ ] Restore Payment & Estimate fetches in `getRecentActivity()`

**Verification:**
- [ ] Dashboard displays actual revenue data
- [ ] Financial widgets update in real-time
- [ ] No fetch request crashes

---

### 1.3 Form Templates System

**Issue:** Feature commented out to prevent crashes  
**Impact:** Users cannot use forms/check-in workflow  
**Files:** `ProTechApp.swift`, `Services/FormService.swift`

**Tasks:**
- [ ] Uncomment `FormService.shared.loadDefaultTemplates()` in `ProTechApp.swift:20`
- [ ] Create default form templates:
  - Device Intake Form
  - Pickup/Release Form
  - Repair Authorization Form
  - Safety Waiver Form
- [ ] Test form creation workflow
- [ ] Test form submission and PDF generation

**Verification:**
- [ ] App launches with forms enabled
- [ ] Default templates appear in forms list
- [ ] Forms can be created and submitted
- [ ] PDFs generate correctly

---

### 1.4 Email Integration

**Issue:** Multiple email functions not implemented  
**Impact:** Cannot send estimates, invoices, or automated notifications  
**Files:** `EstimateDetailView.swift`, `InvoiceDetailView.swift`, `RecurringInvoiceService.swift`

**Tasks:**
- [ ] Implement email service using one of:
  - Option A: `NSSharingService` (native Mail.app)
  - Option B: SMTP service (e.g., SendGrid, Mailgun)
  - Option C: Supabase Edge Functions with Resend/SendGrid

- [ ] Fix email in `EstimateDetailView.swift:521`:
  ```swift
  private func emailEstimate() {
      let pdf = generatePDF()
      EmailService.shared.send(
          to: estimate.customer.email,
          subject: "Estimate #\(estimate.estimateNumber)",
          body: "Please see attached estimate",
          attachments: [pdf]
      )
  }
  ```

- [ ] Fix email in `InvoiceDetailView.swift:799`
- [ ] Fix email in `EstimateGeneratorView.swift:126`
- [ ] Fix recurring invoice emails in `RecurringInvoiceService.swift:258, 272`

**Verification:**
- [ ] Can send estimate via email
- [ ] Can send invoice via email
- [ ] Recurring invoices email automatically
- [ ] Attachments work correctly
- [ ] Admin notifications send on failures

---

## Phase 2: Core Features Completion

*Priority: 🟡 HIGH - Essential for full functionality*

### 2.1 Inventory Management

**Issue:** Stock adjustment incomplete, PO system placeholder  
**Impact:** Cannot manage inventory properly  
**Files:** `InventoryListView.swift`, `PurchaseOrdersListView.swift`

**Tasks:**
- [ ] Implement `StockAdjustmentSheet` view:
  - Quantity adjustment (+/-)
  - Adjustment reason dropdown
  - Notes field
  - Save to `StockAdjustment` entity

- [ ] Create Purchase Order system:
  - `CreatePurchaseOrderView` with supplier selection
  - Line items for products/quantities/costs
  - PO number generation
  - Status tracking (ordered, received, cancelled)
  - Inventory update on receipt

- [ ] Add `PurchaseOrder` and `PurchaseOrderLineItem` entities to Core Data

**Verification:**
- [ ] Can adjust stock quantities
- [ ] History tracks all adjustments
- [ ] Can create and manage POs
- [ ] Inventory updates when PO received

---

### 2.2 Square Integration Testing

**Issue:** Connection test not implemented  
**Impact:** Users can't verify Square credentials  
**Files:** `SquareSettingsView.swift:140`

**Tasks:**
- [ ] Implement Square API test:
  ```swift
  private func testConnection() async {
      isTestingConnection = true
      defer { isTestingConnection = false }
      
      do {
          // Test with /v2/locations endpoint
          let locations = try await SquareAPIService.shared.listLocations()
          connectionTestResult = .success("Connected! Found \(locations.count) location(s)")
      } catch {
          connectionTestResult = .failure("Connection failed: \(error.localizedDescription)")
      }
  }
  ```

- [ ] Display connection status with visual feedback
- [ ] Show location information on success
- [ ] Provide helpful error messages

**Verification:**
- [ ] Test with valid credentials shows success
- [ ] Test with invalid credentials shows error
- [ ] Error messages are helpful

---

### 2.3 Recurring Invoice System

**Issue:** Email integration incomplete, no admin notifications  
**Impact:** Automated billing won't work reliably  
**Files:** `RecurringInvoiceService.swift`

**Tasks:**
- [ ] Connect to email service (from Phase 1.4)
- [ ] Implement admin notification system:
  - Email admin on invoice send failure
  - Dashboard alert for failed invoices
  - Retry queue for failed sends

- [ ] Add configuration for retry logic:
  - Max retry attempts
  - Retry interval
  - Failure escalation

**Verification:**
- [ ] Recurring invoices generate on schedule
- [ ] Invoices email to customers automatically
- [ ] Failed sends notify admin
- [ ] Retry logic works correctly

---

### 2.4 Appointment Calendar Views

**Issue:** Only day view implemented, week/month placeholders  
**Impact:** Limited calendar functionality  
**Files:** `AppointmentSchedulerView.swift:211`

**Tasks:**
- [ ] Implement Week View:
  - 7-column grid layout
  - Hour slots on Y-axis
  - Drag appointments between days
  - Multi-day events

- [ ] Implement Month View:
  - Calendar grid with weeks
  - Appointment dots/indicators
  - Click day to see details
  - Navigation between months

- [ ] Add view switcher (Day/Week/Month tabs)

**Verification:**
- [ ] Can switch between Day/Week/Month views
- [ ] Appointments display in all views
- [ ] Navigation works correctly
- [ ] Performance is acceptable

---

## Phase 3: Polish & UX Improvements

*Priority: 🟢 MEDIUM - Enhances user experience*

### 3.1 Minor Feature Completions

**Tasks:**
- [ ] Implement duplicate estimate function (`EstimateListView.swift:206`)
- [ ] Add "View Invoice" navigation (`InvoiceGeneratorView.swift:97`)
- [ ] Create full inventory history modal (`InventoryItemDetailView.swift:164`)
- [ ] Implement custom date picker for attendance (`AttendanceView.swift:594`)
- [ ] Add time clock summary to employee detail (`EmployeeDetailView.swift:88`)
- [ ] Add loyalty reward redemption feedback (`CustomerLoyaltyView.swift:363`)

**Verification:**
- [ ] All TODO comments resolved
- [ ] No dead buttons or non-functional features
- [ ] User flows are complete

---

### 3.2 Form Template Management

**Issue:** Can't edit or manage templates  
**Impact:** Limited customization options  
**Files:** `FormsSettingsView.swift:35`

**Tasks:**
- [ ] Create `FormTemplateManagerView`:
  - List all templates (default + custom)
  - Edit template fields
  - Duplicate templates
  - Import/export JSON
  - Share templates

- [ ] Add template versioning
- [ ] Allow setting default templates per form type

**Verification:**
- [ ] Can view all templates
- [ ] Can edit and save changes
- [ ] Templates persist correctly
- [ ] Import/export works

---

### 3.3 Receipt & Discount Systems

**Issue:** POS features need testing/completion  
**Impact:** Point of sale not fully functional  
**Files:** `PointOfSaleView.swift`

**Tasks:**
- [ ] Test receipt printing:
  - Thermal printer support
  - PDF receipt generation
  - Email receipt option

- [ ] Implement discount code validation:
  - Create `DiscountCode` entity
  - Validation logic (active dates, usage limits)
  - Apply discount to cart
  - Track usage statistics

**Verification:**
- [ ] Receipts print correctly
- [ ] Discount codes validate and apply
- [ ] Usage tracking works
- [ ] Invalid codes show errors

---

## Phase 4: Production Configuration

*Priority: 🔴 CRITICAL - Required before launch*

### 4.1 Configuration Updates

**Issue:** Placeholder values in production config  
**Impact:** Features won't work in production  
**Files:** `Configuration.swift`

**Tasks:**
- [ ] Update URLs (lines 21-24):
  - Replace `supportURL` with actual support site
  - Replace `privacyPolicyURL` with actual policy
  - Replace `termsOfServiceURL` with actual terms
  - Create/host these web pages

- [ ] Configure subscription IDs (lines 17-18):
  - Register products in App Store Connect
  - Create In-App Purchase items
  - Update `monthlySubscriptionID`
  - Update `annualSubscriptionID`
  - Configure pricing tiers

- [ ] Enable StoreKit (line 27):
  - Set `enableStoreKit = true`
  - Test subscription flow
  - Verify receipt validation
  - Test restore purchases

**Verification:**
- [ ] All URLs point to valid pages
- [ ] Subscription products exist in App Store Connect
- [ ] StoreKit purchases work in sandbox
- [ ] Receipt validation functions

---

### 4.2 App Store Preparation

**Tasks:**
- [ ] Create App Store Connect listing:
  - App name, subtitle, description
  - Keywords for ASO
  - Screenshots (6.5" and 5.5")
  - App icon (1024x1024)
  - Preview video (optional)

- [ ] Configure app settings:
  - Age rating
  - Category (Business/Productivity)
  - Pricing (free with subscription)
  - Availability regions

- [ ] Set up TestFlight:
  - Internal testing group
  - External beta testers
  - Beta testing instructions

**Verification:**
- [ ] App Store listing complete
- [ ] TestFlight build uploaded
- [ ] Beta testers invited

---

### 4.3 Database & API Configuration

**Tasks:**
- [ ] Verify Supabase production setup:
  - Row Level Security policies
  - Database indexes
  - Backup schedule
  - API rate limits

- [ ] Verify Square production credentials:
  - Production access token (not sandbox)
  - Production location ID
  - Webhook configuration
  - PCI compliance settings

- [ ] Configure monitoring:
  - Error tracking (Sentry/Crashlytics)
  - Analytics (Mixpanel/Amplitude)
  - Performance monitoring

**Verification:**
- [ ] Supabase policies tested
- [ ] Square production credentials work
- [ ] Monitoring captures events
- [ ] Alerts configured

---

## Phase 5: Testing & Launch

*Priority: 🔴 CRITICAL - Final validation*

### 5.1 Comprehensive Testing

**Tasks:**
- [ ] Unit Testing:
  - Core Data operations
  - Sync services
  - Business logic calculations
  - API integrations

- [ ] Integration Testing:
  - End-to-end workflows
  - Customer check-in → repair → invoice → payment
  - Inventory adjustment → PO → receipt
  - Appointment scheduling → reminder → completion

- [ ] UI Testing:
  - All navigation paths
  - Form validation
  - Error states
  - Loading states

- [ ] Performance Testing:
  - Large dataset handling (1000+ customers/tickets)
  - Sync performance
  - Memory usage
  - Startup time

**Verification:**
- [ ] No crashes in core workflows
- [ ] Performance meets targets
- [ ] UI is responsive
- [ ] Data syncs correctly

---

### 5.2 Beta Testing

**Tasks:**
- [ ] Internal alpha testing (1 week):
  - Team members use daily
  - Log all bugs
  - Verify critical workflows

- [ ] External beta testing (2 weeks):
  - 10-20 repair shops
  - Real-world usage
  - Feedback collection
  - Bug reporting process

- [ ] Beta feedback implementation:
  - Prioritize critical bugs
  - Address UX issues
  - Polish rough edges

**Verification:**
- [ ] Alpha testing complete
- [ ] Beta group recruited
- [ ] Critical feedback implemented
- [ ] No P0/P1 bugs remain

---

### 5.3 Launch Preparation

**Tasks:**
- [ ] Final security review:
  - API keys secured
  - Sensitive data encrypted
  - Authentication tested
  - Authorization rules verified

- [ ] Documentation:
  - User manual/help center
  - Video tutorials
  - Setup guides
  - Troubleshooting docs

- [ ] Marketing preparation:
  - Landing page
  - Demo video
  - Social media assets
  - Launch announcement

- [ ] Support setup:
  - Support email/ticketing
  - Knowledge base
  - Chat support (optional)
  - Phone support plan

**Verification:**
- [ ] Security audit passed
- [ ] Documentation complete
- [ ] Marketing ready
- [ ] Support channels active

---

### 5.4 Launch

**Tasks:**
- [ ] Submit to App Store:
  - Final build upload
  - Submit for review
  - Respond to review feedback

- [ ] Soft launch:
  - Release to small subset
  - Monitor for issues
  - Quick fix any critical bugs

- [ ] Full launch:
  - Release to all users
  - Announce on social media
  - Monitor analytics/errors
  - Respond to user feedback

**Verification:**
- [ ] App approved by Apple
- [ ] Soft launch successful
- [ ] Full launch live
- [ ] Support handling volume

---

## Success Metrics

### Pre-Launch Checklist

- [ ] All Phase 1 tasks completed (Critical Blockers)
- [ ] All Phase 2 tasks completed (Core Features)
- [ ] All Phase 4 tasks completed (Production Config)
- [ ] Beta testing completed with positive feedback
- [ ] No P0 or P1 bugs remaining
- [ ] App Store listing approved
- [ ] Support system operational

### Post-Launch KPIs

**Week 1:**
- Crash-free rate > 99%
- Average rating > 4.0
- Support response time < 4 hours
- No critical bugs

**Month 1:**
- 100+ active users
- Average rating > 4.5
- Subscription conversion > 10%
- Monthly recurring revenue > $1,000

**Month 3:**
- 500+ active users
- Retention rate > 80%
- MRR > $5,000
- Positive unit economics

---

## Risk Mitigation

### High Risk Items

1. **Core Data Migrations**
   - Risk: Existing data corruption
   - Mitigation: Backup before migration, test thoroughly
   - Rollback: Keep old schema version accessible

2. **Email Delivery**
   - Risk: Deliverability issues, spam folders
   - Mitigation: Use reputable ESP, configure SPF/DKIM
   - Fallback: Manual send option, notification log

3. **Square Integration**
   - Risk: API changes, credential issues
   - Mitigation: Version pinning, error handling
   - Fallback: Manual payment entry

4. **StoreKit Revenue**
   - Risk: Low conversion, technical issues
   - Mitigation: A/B test pricing, optimize paywall
   - Fallback: Alternative monetization (one-time purchase)

---

## Resource Requirements

### Development Team
- 1-2 iOS/macOS developers (full-time)
- 1 backend developer (part-time for Supabase/Square)
- 1 designer (part-time for polish phase)
- 1 QA tester (full-time for Phase 5)

### Infrastructure
- Supabase Pro plan (~$25/month)
- Square production account
- Email service (SendGrid/Mailgun ~$10-50/month)
- Error tracking (Sentry ~$25/month)
- Analytics (free tier initially)

### Budget Estimate
- Development: 6-10 weeks × team cost
- Infrastructure: ~$100-200/month ongoing
- App Store: $99/year developer account
- Marketing: $500-2000 for launch
- Support: Initial in-house, scale as needed

---

## Next Steps

### Immediate Actions (This Week)

1. **Prioritize Phase 1 tasks** - These are blocking everything else
2. **Set up project tracking** - Create tickets for all tasks
3. **Establish timeline** - Set deadlines for each phase
4. **Assign ownership** - Who owns which tasks
5. **Schedule daily standups** - Track progress and blockers

### This Sprint (Next 2 Weeks)

1. Complete Core Data model additions
2. Re-enable dashboard metrics
3. Implement form templates system
4. Start email integration work

---

## Appendix: File Checklist

### Files Requiring Changes

**Critical (Phase 1):**
- [ ] `ProTech.xcdatamodeld` - Add missing entities
- [ ] `Services/DashboardMetricsService.swift` - Re-enable fetches
- [ ] `ProTechApp.swift` - Enable form templates
- [ ] `EstimateDetailView.swift` - Email integration
- [ ] `InvoiceDetailView.swift` - Email integration
- [ ] `RecurringInvoiceService.swift` - Email + notifications

**Important (Phase 2):**
- [ ] `InventoryListView.swift` - Stock adjustment
- [ ] `PurchaseOrdersListView.swift` - Full PO system
- [ ] `SquareSettingsView.swift` - Connection test
- [ ] `AppointmentSchedulerView.swift` - Week/month views

**Polish (Phase 3):**
- [ ] `EstimateListView.swift` - Duplicate function
- [ ] `InvoiceGeneratorView.swift` - Navigation
- [ ] `InventoryItemDetailView.swift` - Full history
- [ ] `AttendanceView.swift` - Custom date picker
- [ ] `EmployeeDetailView.swift` - Time clock section
- [ ] `CustomerLoyaltyView.swift` - Reward feedback
- [ ] `FormsSettingsView.swift` - Template management
- [ ] `PointOfSaleView.swift` - Receipt/discount completion

**Production (Phase 4):**
- [ ] `Configuration.swift` - Update all placeholders

---

**Plan Status:** ✅ Complete  
**Ready for Execution:** Yes  
**Estimated Completion:** 6-10 weeks with dedicated team

