//
//  SupabaseConfig.swift
//  ProTech
//
//  Supabase configuration for macOS app
//

import Foundation

enum SupabaseConfig {
    // Supabase credentials for repair shop system
    // TechMedics Project (sztwxxwnhupwmvxhbzyo)
    static let supabaseURL = "https://sztwxxwnhupwmvxhbzyo.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6dHd4eHduaHVwd212eGhienlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzMTgwNjAsImV4cCI6MjA3NTg5NDA2MH0.bXsI9XFPIBNtHZR46HiM5qXfzhqZMYOBn1v2UAFAOAk"
    
    // Redirect URL for OAuth and email confirmations
    // This MUST match the URL scheme configured in your Xcode project
    static let redirectURL = "protech://auth-callback"
    
    // Storage bucket names (must match iOS apps)
    static let repairPhotosBucket = "repair-photos"
    static let receiptsBucket = "receipts"
    static let employeePhotosBucket = "employee-photos"
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
