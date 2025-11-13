//
//  Configuration.swift
//  ProTech
//
//  App configuration and constants
//

import Foundation

struct Configuration {
    // MARK: - App Information
    static let appName = "ProTech"
    static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - 🔴 PRODUCTION CONFIG - Update before App Store submission
    
    // Subscription Product IDs
    // ⚠️ TODO: Update after creating subscription products in App Store Connect
    // Instructions: https://appstoreconnect.apple.com → Your App → Subscriptions
    static let monthlySubscriptionID = "com.nugentic.protech.monthly"
    static let annualSubscriptionID = "com.nugentic.protech.annual"
    
    // Support URLs
    // ⚠️ TODO: Create these web pages before submitting to App Store
    // Apple REQUIRES working privacy policy and terms of service
    
    // Option 1: Use your domain (recommended)
    static let supportURL = URL(string: "https://nugentic.com/protech/support")!
    static let privacyPolicyURL = URL(string: "https://nugentic.com/protech/privacy")!
    static let termsOfServiceURL = URL(string: "https://nugentic.com/protech/terms")!
    
    // Option 2: Alternative URLs (uncomment and use if preferred)
    // static let supportURL = URL(string: "https://protech.nugentic.com/support")!
    // static let privacyPolicyURL = URL(string: "https://protech.nugentic.com/privacy")!
    // static let termsOfServiceURL = URL(string: "https://protech.nugentic.com/terms")!
    
    static let twilioSignupURL = URL(string: "https://www.twilio.com/try-twilio")!
    
    // MARK: - Feature Flags
    
    // StoreKit Subscriptions
    // ⚠️ TODO: Set to true ONLY after:
    //   1. Creating subscription products in App Store Connect
    //   2. Testing subscriptions in Sandbox environment
    //   3. Verifying receipt validation works
    static let enableStoreKit = false  // 🔴 SET TO TRUE FOR PRODUCTION
    
    static let enableCloudSync = true
    static let enableAnalytics = true
    static let enableBetaFeatures = false
    
    // API Configuration
    static let twilioAPIBaseURL = "https://api.twilio.com/2010-04-01"
    
    // Formatting
    static let dateFormat = "MMM d, yyyy"
    static let dateTimeFormat = "MMM d, yyyy h:mm a"
    static let currencySymbol = "$"
    
    // Limits
    static let maxCustomersInFreeVersion = -1 // Unlimited
    static let maxSMSPerMonth = -1 // Unlimited (user pays Twilio)
    
    // MARK: - Branding
    
    static let primaryColor = "AccentColor"
    static let companyName = "Nugentic"  // Used in receipts, invoices, PDFs
    
    // Debug
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
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
