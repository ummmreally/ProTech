//
//  SupabaseConfig.swift
//  ProTech
//
//  Supabase configuration for macOS app
//

import Foundation

enum SupabaseConfig {
    // Supabase credentials for repair shop system
    // TechMedics Project (ucpgsubidqbhxstgykyt)
    static let supabaseURL = "https://ucpgsubidqbhxstgykyt.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjcGdzdWJpZHFiaHhzdGd5a3l0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk5MjI3NzYsImV4cCI6MjA2NTQ5ODc3Nn0.pW1nwjWlh_igmFnXp7zEMgdhJuwQwvNrtCrG8w3Si4k"
    
    // Storage bucket names (must match iOS apps)
    static let repairPhotosBucket = "repair-photos"
    static let receiptsBucket = "receipts"
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
