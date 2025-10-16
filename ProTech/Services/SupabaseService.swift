//
//  SupabaseService.swift
//  ProTech
//
//  Main Supabase service for macOS app
//

import Foundation
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    @Published var isInitialized = false
    @Published var syncStatus: SupabaseSyncStatus = .idle
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        self.isInitialized = true
    }
    
    // MARK: - Session Management
    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }
    
    var isAuthenticated: Bool {
        get async {
            (try? await client.auth.session) != nil
        }
    }
    
    // MARK: - Employee Authentication
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
}

// MARK: - Supabase Sync Status
enum SupabaseSyncStatus {
    case idle
    case syncing
    case success(date: Date)
    case error(String)
    
    var description: String {
        switch self {
        case .idle:
            return "Ready to sync"
        case .syncing:
            return "Syncing..."
        case .success(let date):
            return "Last synced: \(date.formatted(date: .omitted, time: .shortened))"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}
