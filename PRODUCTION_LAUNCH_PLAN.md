# ProTech - Production Launch Implementation Plan

**Created:** November 2, 2025  
**Target Launch:** December 2025 (4 weeks)  
**Priority:** Critical Path to Production

---

## Overview

This document provides a **step-by-step implementation plan** to complete all missing features identified in the audit and prepare ProTech for App Store launch.

**Current Status:** 75% Complete  
**Estimated Work:** 130-180 hours (3-4 weeks)  
**Required Resources:** 1 Full-Time Developer

---

## Sprint 1: Critical Blockers (Week 1)

**Goal:** Fix App Store rejection blockers and enable monetization  
**Duration:** 5 days  
**Priority:** 🔴 CRITICAL

### Task 1.1: Configure StoreKit & Subscriptions
**Time:** 8 hours  
**Files to Modify:**
- `Configuration.swift`
- `SubscriptionManager.swift`

**Steps:**
1. Create App Store Connect account (if not done)
2. Register bundle IDs:
   - `com.yourcompany.protech` (main app)
   - Configure In-App Purchase IDs:
     - `com.yourcompany.protech.monthly` ($19.99/month)
     - `com.yourcompany.protech.annual` ($199.99/year)
3. Update `Configuration.swift`:
   ```swift
   static let enableStoreKit = true
   static let monthlySubscriptionID = "com.yourcompany.protech.monthly"
   static let annualSubscriptionID = "com.yourcompany.protech.annual"
   ```
4. Test subscription purchase flow
5. Test restore purchases
6. Test subscription expiration
7. Verify paywall appears for Pro features

**Acceptance Criteria:**
- [ ] User can purchase monthly subscription
- [ ] User can purchase annual subscription
- [ ] Restore purchases works
- [ ] Pro features unlock after purchase
- [ ] Subscription status persists after app restart

---

### Task 1.2: Implement Email Sending
**Time:** 12 hours  
**Files to Create/Modify:**
- Create: `Services/EmailService.swift`
- Modify: `EstimateDetailView.swift`
- Modify: `EstimateGeneratorView.swift`
- Modify: `InvoiceDetailView.swift`

**Implementation:**

```swift
// Services/EmailService.swift
import AppKit

class EmailService {
    static let shared = EmailService()
    
    func sendEmail(to recipient: String, 
                   subject: String, 
                   body: String, 
                   attachmentURL: URL? = nil) {
        let service = NSSharingService(named: .composeEmail)!
        service.recipients = [recipient]
        service.subject = subject
        
        var items: [Any] = [body]
        if let url = attachmentURL {
            items.append(url)
        }
        
        if service.canPerform(withItems: items) {
            service.perform(withItems: items)
        }
    }
    
    func sendEstimate(_ estimate: Estimate, 
                     customer: Customer, 
                     pdfURL: URL) {
        let recipient = customer.email ?? ""
        let subject = "Estimate \(estimate.formattedEstimateNumber)"
        let body = """
        Dear \(customer.displayName),
        
        Please find attached your estimate for review.
        
        Estimate Number: \(estimate.formattedEstimateNumber)
        Total: \(estimate.formattedTotal)
        
        Thank you for your business!
        """
        
        sendEmail(to: recipient, subject: subject, body: body, attachmentURL: pdfURL)
    }
    
    func sendInvoice(_ invoice: Invoice, 
                    customer: Customer, 
                    pdfURL: URL) {
        let recipient = customer.email ?? ""
        let subject = "Invoice \(invoice.invoiceNumber ?? "")"
        let body = """
        Dear \(customer.displayName),
        
        Please find attached your invoice.
        
        Invoice Number: \(invoice.invoiceNumber ?? "")
        Amount Due: \(invoice.formattedTotal)
        
        Thank you for your business!
        """
        
        sendEmail(to: recipient, subject: subject, body: body, attachmentURL: pdfURL)
    }
}
```

**Update Views:**

```swift
// EstimateDetailView.swift line 521
Button("Send") {
    if let pdfURL = generatePDFURL() {
        EmailService.shared.sendEstimate(estimate, customer: fetchCustomer(), pdfURL: pdfURL)
    }
    dismiss()
}
.disabled(recipientEmail.isEmpty)

// EstimateGeneratorView.swift line 126
Button("Save & Send to Customer") {
    saveEstimate(status: "pending")
    if let savedEstimate = lastSavedEstimate,
       let pdfURL = generatePDFURL(for: savedEstimate) {
        EmailService.shared.sendEstimate(savedEstimate, customer: selectedCustomer, pdfURL: pdfURL)
    }
}

// InvoiceDetailView.swift line 799
private func sendEmail() {
    guard let pdfDocument = pdfDocument,
          let pdfURL = savePDFTemporarily(pdfDocument) else { return }
    
    EmailService.shared.sendInvoice(invoice, customer: fetchCustomer(), pdfURL: pdfURL)
}
```

**Acceptance Criteria:**
- [ ] "Send Email" button opens Mail.app with pre-filled recipient
- [ ] PDF is attached to email
- [ ] Subject and body are populated correctly
- [ ] Works for both estimates and invoices

---

### Task 1.3: Replace Placeholder URLs
**Time:** 4 hours  
**Files to Modify:**
- `Configuration.swift`
- Create privacy policy page
- Create terms of service page
- Create support page

**Steps:**
1. Register domain (e.g., `protech-app.com`)
2. Create simple website with:
   - Privacy Policy page
   - Terms of Service page
   - Support page with contact form
3. Update `Configuration.swift`:
   ```swift
   static let supportURL = URL(string: "https://protech-app.com/support")!
   static let privacyPolicyURL = URL(string: "https://protech-app.com/privacy")!
   static let termsOfServiceURL = URL(string: "https://protech-app.com/terms")!
   ```

**Privacy Policy Must Include:**
- What data is collected (customer info, usage analytics)
- How data is stored (local Core Data, optional iCloud)
- Third-party services (Twilio, Square)
- User rights (export, delete data)
- Contact information

**Acceptance Criteria:**
- [ ] All URLs point to live, accessible pages
- [ ] Privacy policy meets Apple requirements
- [ ] Support page is functional
- [ ] Links work in Settings view

---

### Task 1.4: Test All Critical Paths
**Time:** 8 hours

**Test Scenarios:**
1. **Subscription Flow:**
   - [ ] Launch app → View Pro feature → See paywall → Purchase → Feature unlocks
   - [ ] Restart app → Subscription persists
   - [ ] Restore purchases works

2. **Email Flow:**
   - [ ] Create estimate → Send to customer → Email opens with PDF
   - [ ] Create invoice → Send to customer → Email opens with PDF

3. **Core Features:**
   - [ ] Add customer → Save → Appears in list
   - [ ] Create repair ticket → Track status → Complete
   - [ ] Check-in customer → Appears in queue → Start repair
   - [ ] Create estimate → Customer approves in portal → Generate invoice

**Acceptance Criteria:**
- [ ] No crashes in critical paths
- [ ] All data persists correctly
- [ ] UI responds within 2 seconds

---

## Sprint 2: High Priority Features (Week 2)

**Goal:** Complete core features and integrations  
**Duration:** 5 days  
**Priority:** 🟡 HIGH

### Task 2.1: Form Template System
**Time:** 10 hours  
**Files to Modify:**
- `ProTech.xcdatamodeld` - Add FormTemplate entity
- `FormService.swift` - Uncomment template loading
- `ProTechApp.swift` - Enable template loading

**Core Data Entity:**
```swift
Entity: FormTemplate
Attributes:
- id: UUID
- name: String
- type: String (intake, pickup, estimate)
- fields: [FieldDefinition] (Binary Data / Transformable)
- isDefault: Bool
- createdAt: Date
- updatedAt: Date
```

**Default Templates to Create:**
1. **Device Intake Form:**
   - Customer name
   - Device type/model
   - Issue description
   - Accessories included
   - Estimated cost
   - Customer signature

2. **Device Pickup Form:**
   - Repair completed
   - Work performed
   - Parts replaced
   - Total cost
   - Customer signature

3. **Estimate Form:**
   - Service description
   - Line items with costs
   - Total estimate
   - Validity period
   - Terms & conditions

**Acceptance Criteria:**
- [ ] FormTemplate entity exists in Core Data
- [ ] Default templates load on first launch
- [ ] Templates appear in form builder
- [ ] Users can create forms from templates

---

### Task 2.2: Stock Adjustment Sheet
**Time:** 6 hours  
**Files to Create:**
- `Views/Inventory/StockAdjustmentSheet.swift`

**Implementation:**

```swift
struct StockAdjustmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: InventoryItem
    
    @State private var adjustmentType: AdjustmentType = .add
    @State private var quantity: Int = 1
    @State private var reason: String = ""
    @State private var notes: String = ""
    
    enum AdjustmentType: String, CaseIterable {
        case add = "Add Stock"
        case remove = "Remove Stock"
        case set = "Set Stock Level"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Stock") {
                    LabeledContent("Item", value: item.name ?? "")
                    LabeledContent("Current Quantity", value: "\(item.quantity)")
                }
                
                Section("Adjustment") {
                    Picker("Type", selection: $adjustmentType) {
                        ForEach(AdjustmentType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...1000)
                    
                    Picker("Reason", selection: $reason) {
                        Text("Purchase").tag("purchase")
                        Text("Sale").tag("sale")
                        Text("Damage").tag("damage")
                        Text("Return").tag("return")
                        Text("Correction").tag("correction")
                        Text("Other").tag("other")
                    }
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section {
                    LabeledContent("New Quantity") {
                        Text("\(calculateNewQuantity())")
                            .bold()
                            .foregroundColor(calculateNewQuantity() < 0 ? .red : .green)
                    }
                }
            }
            .navigationTitle("Adjust Stock")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAdjustment() }
                        .disabled(reason.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 450)
    }
    
    private func calculateNewQuantity() -> Int32 {
        switch adjustmentType {
        case .add:
            return item.quantity + Int32(quantity)
        case .remove:
            return item.quantity - Int32(quantity)
        case .set:
            return Int32(quantity)
        }
    }
    
    private func saveAdjustment() {
        let adjustment = StockAdjustment(context: viewContext)
        adjustment.id = UUID()
        adjustment.itemId = item.id
        adjustment.adjustmentType = adjustmentType.rawValue
        adjustment.quantityChange = Int32(quantity)
        adjustment.reason = reason
        adjustment.notes = notes.isEmpty ? nil : notes
        adjustment.previousQuantity = item.quantity
        adjustment.newQuantity = calculateNewQuantity()
        adjustment.createdAt = Date()
        
        item.quantity = calculateNewQuantity()
        item.updatedAt = Date()
        
        try? viewContext.save()
        dismiss()
    }
}
```

**Acceptance Criteria:**
- [ ] Stock adjustment sheet opens from inventory list
- [ ] Can add, remove, or set stock quantity
- [ ] Adjustment is recorded in StockAdjustment entity
- [ ] Inventory quantity updates correctly
- [ ] History shows in inventory detail

---

### Task 2.3: Square API Connection Test
**Time:** 4 hours  
**Files to Modify:**
- `SquareSettingsView.swift`
- `SquareAPIService.swift`

**Implementation:**

```swift
// Add to SquareAPIService.swift
func testConnection() async throws -> (success: Bool, message: String) {
    guard let accessToken = getAccessToken() else {
        throw SquareAPIError.missingCredentials
    }
    
    let url = URL(string: "\(baseURL)/v2/locations")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse else {
        return (false, "Invalid response from Square API")
    }
    
    if httpResponse.statusCode == 200 {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let locations = json?["locations"] as? [[String: Any]] ?? []
        return (true, "Connected! Found \(locations.count) location(s)")
    } else {
        let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        let errors = json?["errors"] as? [[String: Any]] ?? []
        let errorMessage = errors.first?["detail"] as? String ?? "Unknown error"
        return (false, "Connection failed: \(errorMessage)")
    }
}

// Update SquareSettingsView.swift
private func testConnection() {
    testingConnection = true
    testSuccess = nil
    testMessage = ""
    
    Task {
        do {
            let result = try await SquareAPIService.shared.testConnection()
            await MainActor.run {
                testSuccess = result.success
                testMessage = result.message
                testingConnection = false
            }
        } catch {
            await MainActor.run {
                testSuccess = false
                testMessage = "Error: \(error.localizedDescription)"
                testingConnection = false
            }
        }
    }
}
```

**Acceptance Criteria:**
- [ ] Test button calls actual Square API
- [ ] Success shows location count
- [ ] Failure shows error message
- [ ] Invalid token shows clear error

---

### Task 2.4: Recurring Invoice Email Service
**Time:** 8 hours  
**Files to Modify:**
- `RecurringInvoiceService.swift`
- Create: `Services/RecurringInvoiceEmailer.swift`

**Implementation:**

```swift
// Services/RecurringInvoiceEmailer.swift
class RecurringInvoiceEmailer {
    static let shared = RecurringInvoiceEmailer()
    
    func sendRecurringInvoice(_ invoice: Invoice, to customer: Customer) async throws {
        guard let email = customer.email, !email.isEmpty else {
            throw EmailError.noRecipient
        }
        
        // Generate PDF
        guard let pdfURL = generateInvoicePDF(invoice) else {
            throw EmailError.pdfGenerationFailed
        }
        
        // Send via Mail.app
        let service = NSSharingService(named: .composeEmail)!
        service.recipients = [email]
        service.subject = "Invoice \(invoice.invoiceNumber ?? "")"
        
        let body = """
        Dear \(customer.displayName),
        
        Your recurring invoice is ready.
        
        Invoice Number: \(invoice.invoiceNumber ?? "")
        Amount Due: \(invoice.formattedTotal)
        Due Date: \(invoice.dueDate?.formatted() ?? "")
        
        Thank you for your continued business!
        """
        
        await MainActor.run {
            service.perform(withItems: [body, pdfURL])
        }
    }
    
    func sendFailureNotification(error: Error, recurringInvoice: RecurringInvoice) {
        // Send notification to admin
        let notification = NSUserNotification()
        notification.title = "Recurring Invoice Failed"
        notification.informativeText = "Failed to generate invoice for \(recurringInvoice.description ?? "")"
        notification.soundName = NSUserNotificationDefaultSoundName
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// Update RecurringInvoiceService.swift
private func sendInvoice(_ invoice: Invoice, to customer: Customer) {
    Task {
        do {
            try await RecurringInvoiceEmailer.shared.sendRecurringInvoice(invoice, to: customer)
            print("✅ Recurring invoice sent successfully")
        } catch {
            print("❌ Failed to send recurring invoice: \(error)")
            RecurringInvoiceEmailer.shared.sendFailureNotification(
                error: error, 
                recurringInvoice: recurring
            )
        }
    }
}
```

**Acceptance Criteria:**
- [ ] Recurring invoices send automatically
- [ ] Email includes PDF attachment
- [ ] Failures trigger admin notification
- [ ] Retry logic for transient failures

---

## Sprint 3: Polish & Enhancements (Week 3)

**Goal:** Complete nice-to-have features and improve UX  
**Duration:** 5 days  
**Priority:** 🟢 MEDIUM

### Task 3.1: Purchase Order System
**Time:** 12 hours  
**Files to Create:**
- `Views/Inventory/CreatePurchaseOrderView.swift`
- `Views/Inventory/PurchaseOrderDetailView.swift`

**Implementation:** (See full implementation in separate document)

**Acceptance Criteria:**
- [ ] Can create purchase orders
- [ ] Can link to suppliers
- [ ] Can mark as received
- [ ] Inventory updates on receipt

---

### Task 3.2: Additional Features
**Time:** 10 hours total

**3.2a: View Full Inventory History** (3 hours)
- Create modal sheet with paginated history
- Add filtering by date range
- Show all stock adjustments

**3.2b: Duplicate Estimate** (2 hours)
- Clone estimate with new ID
- Reset status to draft
- Increment estimate number

**3.2c: Loyalty Reward Feedback** (2 hours)
- Add success/error alerts
- Show updated balance
- Provide confirmation dialog

**3.2d: Navigate to Invoice** (2 hours)
- Add navigation after invoice creation
- Pass invoice ID to detail view
- Show success confirmation

**3.2e: Custom Date Picker** (1 hour)
- Create date range picker sheet
- Allow start/end date selection

---

## Sprint 4: Testing & Launch Prep (Week 4)

**Goal:** Comprehensive testing and App Store preparation  
**Duration:** 5 days  
**Priority:** 🔴 CRITICAL

### Task 4.1: Comprehensive Testing
**Time:** 20 hours

**Test Matrix:**

| Feature | Manual Test | Unit Test | Integration Test |
|---------|-------------|-----------|------------------|
| Subscription Purchase | ✓ | ✓ | ✓ |
| Email Sending | ✓ | - | ✓ |
| Customer CRUD | ✓ | ✓ | - |
| Repair Tracking | ✓ | ✓ | ✓ |
| Invoice Generation | ✓ | ✓ | ✓ |
| Square Integration | ✓ | - | ✓ |
| Forms & PDF | ✓ | ✓ | - |
| Loyalty Program | ✓ | ✓ | - |
| Reports | ✓ | - | - |

**Acceptance Criteria:**
- [ ] Zero crashes in critical paths
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Performance benchmarks met
- [ ] Memory leaks fixed

---

### Task 4.2: App Store Assets
**Time:** 8 hours

**Required Assets:**
1. **App Icon** (1024x1024)
2. **Screenshots** (5-10 images):
   - Dashboard view
   - Customer management
   - Repair tracking
   - Forms & PDF
   - POS system
   - Reports
3. **Preview Video** (15-30 seconds)
4. **Marketing Copy:**
   - App name: "ProTech - Repair Shop Manager"
   - Subtitle: "Customer & Repair Management"
   - Description (4000 characters)
   - Keywords (100 characters)
   - Promotional text (170 characters)

**Acceptance Criteria:**
- [ ] All assets created at correct sizes
- [ ] Screenshots show key features
- [ ] Copy is compelling and clear
- [ ] Keywords researched for ASO

---

### Task 4.3: Final Pre-Launch Checklist
**Time:** 4 hours

**Code Review:**
- [ ] Remove all `print()` debug statements
- [ ] Remove all `// TODO` comments (or convert to issues)
- [ ] Update version to 1.0.0
- [ ] Set build number to 1
- [ ] Verify all credentials are from user input (no hardcoded tokens)

**App Store Connect:**
- [ ] Bundle ID registered
- [ ] In-App Purchases configured and approved
- [ ] Privacy policy URL active
- [ ] Support URL active
- [ ] App created in App Store Connect
- [ ] Build uploaded via Xcode
- [ ] TestFlight tested

**Legal:**
- [ ] Privacy policy reviewed by legal (if possible)
- [ ] Terms of service reviewed
- [ ] EULA (if custom)

**Acceptance Criteria:**
- [ ] App passes Xcode validation
- [ ] No warnings in build
- [ ] TestFlight build tested
- [ ] Ready for submission

---

## Risk Mitigation

### Risk 1: StoreKit Testing
**Risk:** In-App Purchases don't work in production  
**Mitigation:**
- Test in Sandbox environment
- Test with real account after approval
- Implement receipt validation
- Add verbose logging for purchase flow

### Risk 2: Email Integration
**Risk:** Mail.app integration fails on some Macs  
**Mitigation:**
- Test on multiple macOS versions
- Provide fallback "Copy Email" button
- Show clear error messages
- Document Mail.app permissions

### Risk 3: App Store Rejection
**Risk:** App rejected for incomplete features  
**Mitigation:**
- Remove all "Coming Soon" placeholders
- Test every button and link
- Provide demo data for reviewers
- Write clear App Review notes

### Risk 4: Performance Issues
**Risk:** App slow with large datasets  
**Mitigation:**
- Implement pagination for large lists
- Add loading indicators
- Optimize Core Data fetch requests
- Profile with Instruments

---

## Success Metrics

### Pre-Launch
- [ ] 100% of critical tasks complete
- [ ] 90% of high priority tasks complete
- [ ] Zero crashes in testing
- [ ] App Store assets ready
- [ ] TestFlight testing complete

### Post-Launch (Month 1)
- [ ] 50+ downloads
- [ ] 10+ Pro subscribers ($199 MRR)
- [ ] 4.0+ star rating
- [ ] < 3% crash rate
- [ ] < 5% refund rate

### Post-Launch (Month 3)
- [ ] 200+ downloads
- [ ] 30+ Pro subscribers ($600 MRR)
- [ ] 4.5+ star rating
- [ ] < 1% crash rate
- [ ] Featured consideration

---

## Team & Resources

### Required Team
- **iOS Developer** (1 FT) - 4 weeks
- **Designer** (0.25 FT) - 1 week for assets
- **QA Tester** (0.5 FT) - 2 weeks
- **Product Manager** (0.25 FT) - 4 weeks

### Tools & Services Needed
- Xcode 15+
- Apple Developer Account ($99/year)
- Domain registration ($10-15/year)
- Web hosting for support pages ($5-10/month)
- TestFlight beta testing
- App Store Connect

### Budget Estimate
- Developer (4 weeks @ $1500/week): $6,000
- Designer (1 week @ $1000/week): $1,000
- QA (2 weeks @ $750/week): $1,500
- Apple Developer: $99
- Domain & Hosting: $50
- **Total:** ~$8,650

---

## Timeline

```
Week 1: Critical Blockers
├─ Mon-Tue: StoreKit & Subscriptions
├─ Wed-Thu: Email Implementation
└─ Fri: URLs & Testing

Week 2: High Priority
├─ Mon-Tue: Form Templates
├─ Wed: Stock Adjustments
├─ Thu: Square Testing
└─ Fri: Recurring Invoices

Week 3: Polish
├─ Mon-Wed: Purchase Orders
├─ Thu: Additional Features
└─ Fri: Bug Fixes

Week 4: Launch Prep
├─ Mon-Wed: Testing
├─ Thu: Assets & App Store
└─ Fri: Final Review & Submit
```

---

## Launch Day Checklist

**T-7 Days:**
- [ ] Final build uploaded to TestFlight
- [ ] Beta testers invited
- [ ] Marketing materials finalized

**T-3 Days:**
- [ ] Submit for App Store review
- [ ] Prepare social media posts
- [ ] Set up analytics

**T-0 (Launch Day):**
- [ ] Monitor App Store status
- [ ] Post on social media
- [ ] Email announcement list
- [ ] Monitor crash reports
- [ ] Respond to reviews

**T+1 Day:**
- [ ] Review first day metrics
- [ ] Fix any critical bugs
- [ ] Thank early adopters

---

## Post-Launch Support Plan

### Week 1 After Launch
- Daily monitoring of crash reports
- Respond to all reviews within 24 hours
- Fix critical bugs immediately
- Release 1.0.1 if needed

### Month 1
- Gather user feedback
- Prioritize feature requests
- Plan version 1.1
- Track key metrics

### Month 3
- Major feature update (1.1 or 2.0)
- Marketing push
- Request App Store featuring

---

## Conclusion

This implementation plan provides a **clear path to production** in 4 weeks. By following this sprint-based approach and focusing on critical items first, ProTech will be ready for App Store launch with all essential features working correctly.

**Key Success Factors:**
1. Focus on critical blockers first
2. Test thoroughly at each stage
3. Remove all placeholders before submission
4. Prepare comprehensive App Store assets
5. Monitor closely post-launch

**Next Action:** Begin Sprint 1 immediately with StoreKit configuration.

---

**Document Version:** 1.0  
**Last Updated:** November 2, 2025  
**Owner:** Development Team  
**Status:** READY TO EXECUTE
