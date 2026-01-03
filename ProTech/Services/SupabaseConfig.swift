//
//  SupabaseConfig.swift
//  ProTech
//
//  Centralized configuration for all external services
//  All credentials are hardcoded - no settings UI required
//

import Foundation

// MARK: - Supabase Configuration
enum SupabaseConfig {
    // Credentials have been moved to ProductionConfig.swift
    // Use ProductionConfig.shared.currentEnvironment to access them
    
    // Redirect URL for OAuth and email confirmations
    static let redirectURL = "protech://auth-callback"
    
    // Storage bucket names
    static let repairPhotosBucket = "repair-photos"
    static let receiptsBucket = "receipts"
    static let employeePhotosBucket = "employee-photos"
    static let signaturesBucket = "signatures"
}

// MARK: - Twilio Configuration
enum TwilioConfig {
    // Twilio credentials - REPLACE WITH YOUR ACTUAL VALUES
    static let accountSID = "AC7c546fe017f866e63ebd8cdd5f6e7c9b"      // Starts with "AC"
    static let authToken = "057f79cec823098da19ef70b72f91fea"
    static let phoneNumber = "+18332488492"                // Your Twilio phone number in E.164 format
    
    // API Base URL
    static let apiBaseURL = "https://api.twilio.com/2010-04-01"
    
    // Check if configured (not using placeholder values)
    static var isConfigured: Bool {
        return !accountSID.hasPrefix("YOUR_") && 
               !authToken.hasPrefix("YOUR_") && 
               phoneNumber.hasPrefix("+1") && phoneNumber.count >= 12
    }
}

// MARK: - Square Configuration
enum SquareConfig {
    // Square credentials - REPLACE WITH YOUR ACTUAL VALUES
    static let accessToken = "EAAAl7otpVYDkINJHZrUIrdexJVz2GBToF3Lh563Dh-nR7dWb-YBxGhW7oHSqYzh"    // Production token starts with "EQ" or "EA"
    static let applicationId = "sq0idp-sTMiZB_brLLe7ONRdGPpTQ"
    static let clientSecret = "sq0csp-MgHk7kj2EjNkXU66L053DOgXs16p3IKqFH0rbAA5kdk"
    static let locationId = "L0ZVBAJGM03JR"
    
    // Environment
    static let environment: SquareEnvironment = .production
    
    // API Base URLs
    static var apiBaseURL: String {
        switch environment {
        case .sandbox:
            return "https://connect.squareupsandbox.com/v2"
        case .production:
            return "https://connect.squareup.com/v2"
        }
    }
    
    // Check if configured (not using placeholder values)
    static var isConfigured: Bool {
        return !accessToken.hasPrefix("YOUR_") && 
               !applicationId.hasPrefix("YOUR_") && 
               !locationId.hasPrefix("YOUR_") &&
               !clientSecret.hasPrefix("YOUR_")
    }
}

// MARK: - Sync Configuration
enum SyncConfig {
    // Enable/disable automatic sync
    static let autoSyncEnabled = true
    
    // Sync interval (seconds)
    static let syncInterval: TimeInterval = 30
    
    // Conflict resolution strategy
    enum ConflictResolution {
        case serverWins    // Server data overwrites local
        case localWins     // Local data overwrites server
        case newestWins    // Newest timestamp wins
    }
    
    static let conflictStrategy: ConflictResolution = .newestWins
}

// MARK: - Google Ads Configuration
enum GoogleAdsConfig {
    // Keys for UserDefaults
    private static let kDeveloperToken = "GoogleAds_DeveloperToken"
    private static let kClientId = "GoogleAds_ClientId"
    private static let kClientSecret = "GoogleAds_ClientSecret"
    private static let kRefreshToken = "GoogleAds_RefreshToken"
    private static let kCustomerId = "GoogleAds_CustomerId"
    
    // Computed properties backed by UserDefaults
    static var developerToken: String? {
        get { UserDefaults.standard.string(forKey: kDeveloperToken) }
        set { UserDefaults.standard.set(newValue, forKey: kDeveloperToken) }
    }
    
    static var clientId: String? {
        get { UserDefaults.standard.string(forKey: kClientId) }
        set { UserDefaults.standard.set(newValue, forKey: kClientId) }
    }
    
    static var clientSecret: String? {
        get { UserDefaults.standard.string(forKey: kClientSecret) }
        set { UserDefaults.standard.set(newValue, forKey: kClientSecret) }
    }
    
    static var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: kRefreshToken) }
        set { UserDefaults.standard.set(newValue, forKey: kRefreshToken) }
    }
    
    static var customerId: String? {
        get { UserDefaults.standard.string(forKey: kCustomerId) }
        set { UserDefaults.standard.set(newValue, forKey: kCustomerId) }
    }
    
    static var isConfigured: Bool {
        return developerToken != nil && !developerToken!.isEmpty &&
               clientId != nil && !clientId!.isEmpty &&
               clientSecret != nil && !clientSecret!.isEmpty &&
               refreshToken != nil && !refreshToken!.isEmpty &&
               customerId != nil && !customerId!.isEmpty
    }
}
