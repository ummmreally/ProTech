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
    // Supabase credentials for repair shop system
    // TechMedics Project (sztwxxwnhupwmvxhbzyo)
    static let supabaseURL = "https://sztwxxwnhupwmvxhbzyo.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dHd4eHduaHVwd212eGhienlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMTgwNjAsImV4cCI6MjA3NTg5NDA2MH0.bXsI9XFPIBNtHZR46HiM5qXfzhqZMYOBn1v2UAFAOAk"
    
    // Redirect URL for OAuth and email confirmations
    static let redirectURL = "protech://auth-callback"
    
    // Storage bucket names
    static let repairPhotosBucket = "repair-photos"
    static let receiptsBucket = "receipts"
    static let employeePhotosBucket = "employee-photos"
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
