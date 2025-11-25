//
//  SupabaseService.swift
//  ProTech
//
//  Main Supabase service for macOS app
//

import Foundation
import Supabase
import Auth

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    var client: SupabaseClient
    
    @Published var isInitialized = false
    @Published var syncStatus: SupabaseSyncStatus = .idle
    @Published var currentShopId: String?
    @Published var currentRole: String?
    
    private init() {
        let authOptions = SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
        let clientOptions = SupabaseClientOptions(auth: authOptions)
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey,
            options: clientOptions
        )
        self.isInitialized = true
        
        // Setup auth state listener
        Task {
            await setupAuthListener()
        }
    }
    
    private func setupAuthListener() async {
        for await (event, session) in client.auth.authStateChanges {
            switch event {
            case .signedIn:
                if let session = session {
                    await extractClaims(from: session)
                }
            case .signedOut:
                currentShopId = nil
                currentRole = nil
            default:
                break
            }
        }
    }
    
    private func extractClaims(from session: Session) async {
        // For now, use default shop ID
        // In production, this would extract from JWT claims
        currentShopId = "00000000-0000-0000-0000-000000000001"
        currentRole = "admin"
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
    
    // MARK: - Configuration
    
    func reconfigure(url: String, key: String) async {
        guard let supabaseURL = URL(string: url) else {
            print("❌ Invalid Supabase URL: \(url)")
            return
        }
        
        print("🔄 Reconfiguring Supabase client...")
        print("   URL: \(url)")
        
        let authOptions = SupabaseClientOptions.AuthOptions(emitLocalSessionAsInitialSession: true)
        let clientOptions = SupabaseClientOptions(auth: authOptions)
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: key,
            options: clientOptions
        )
        
        // Re-setup listener for the new client
        Task {
            await setupAuthListener()
        }
        
        print("✅ Supabase client reconfigured successfully")
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
