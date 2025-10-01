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
    
    // Subscription Product IDs
    static let monthlySubscriptionID = "com.yourcompany.techstorepro.monthly"
    static let annualSubscriptionID = "com.yourcompany.techstorepro.annual"
    
    // Support URLs
    static let supportURL = URL(string: "https://yourcompany.com/support")!
    static let privacyPolicyURL = URL(string: "https://yourcompany.com/privacy")!
    static let termsOfServiceURL = URL(string: "https://yourcompany.com/terms")!
    static let twilioSignupURL = URL(string: "https://www.twilio.com/try-twilio")!
    
    // Feature Flags
    static let enableStoreKit = false
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
    
    // Colors (Brand)
    static let primaryColor = "AccentColor"
    
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
