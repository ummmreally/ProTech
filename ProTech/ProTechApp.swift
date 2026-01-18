//
//  ProTechApp.swift
//  ProTech
//
//  Main app entry point
//

import SwiftUI

@main
struct ProTechApp: App {
    // Use @ObservedObject for singletons (not @StateObject which manages lifecycle)
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var authService = AuthenticationService.shared
    @ObservedObject private var supabaseAuth = SupabaseAuthService.shared
    @StateObject private var employeeService = EmployeeService()
    let persistenceController = CoreDataManager.shared
    
    init() {
        // Load default form templates on first launch
        FormService.shared.loadDefaultTemplates()
    }
    
    @State private var configIssues: [ConfigurationIssue] = []
    
    private func validateEnvironment() {
        let issues = ProductionConfig.shared.validateConfiguration()
        // Filter for critical/blocking issues only if desired, or show all
        // For now, only block on critical issues to avoid blocking dev work
        self.configIssues = issues.filter { issue in
            switch issue {
            case .missingSupabaseURL, .missingSupabaseKey: return true
            default: return false
            }
        }
        
        if !configIssues.isEmpty {
            AppLogger.fault("Configuration validation failed with \(configIssues.count) critical issues", category: .general)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    if !configIssues.isEmpty {
                        ConfigurationErrorView(issues: configIssues)
                    } else {
                        ContentView()
                            .environment(\.managedObjectContext, persistenceController.viewContext)
                            .environmentObject(subscriptionManager)
                            .environmentObject(authService)
                            .frame(minWidth: 900, minHeight: 600)
                            .onAppear {
                                // Validate environment configuration
                                validateEnvironment()
                                
                                // Check subscription status on launch
                                Task {
                                    await subscriptionManager.checkSubscriptionStatus()
                                }
                            }
                    }
                } else {
                    LoginView()
                        .frame(minWidth: 600, minHeight: 800)
                }
            }
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    Task {
                        await SupabaseSyncService.shared.performFullSync()
                        await RealtimeManager.shared.startRealtimeSync()
                    }
                } else {
                    RealtimeManager.shared.stopRealtimeSync()
                }
            }
            .onOpenURL { url in
                // Handle deep links for Supabase email confirmations
                handleDeepLink(url)
            }
        }
        .defaultSize(width: 650, height: 850)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Customer") {
                    NotificationCenter.default.post(name: .newCustomer, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("New Ticket") {
                    NotificationCenter.default.post(name: .newTicket, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .newItem) {
                Button("Global Search") {
                    NotificationCenter.default.post(name: .openGlobalSearch, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            
            
            CommandMenu("Navigation") {
                Button("Dashboard") { NotificationCenter.default.post(name: .navigateToDashboard, object: nil) }
                    .keyboardShortcut("1", modifiers: .command)
                Button("Queue") { NotificationCenter.default.post(name: .navigateToQueue, object: nil) }
                    .keyboardShortcut("2", modifiers: .command)
                Button("Repairs") { NotificationCenter.default.post(name: .navigateToRepairs, object: nil) }
                    .keyboardShortcut("3", modifiers: .command)
                Button("Customers") { NotificationCenter.default.post(name: .navigateToCustomers, object: nil) }
                    .keyboardShortcut("4", modifiers: .command)
                Button("Invoices") { NotificationCenter.default.post(name: .navigateToInvoices, object: nil) }
                    .keyboardShortcut("5", modifiers: .command)
                Button("Estimates") { NotificationCenter.default.post(name: .navigateToEstimates, object: nil) }
                    .keyboardShortcut("6", modifiers: .command)
                Button("Inventory") { NotificationCenter.default.post(name: .navigateToInventory, object: nil) }
                    .keyboardShortcut("7", modifiers: .command)
                Button("Point of Sale") { NotificationCenter.default.post(name: .navigateToPOS, object: nil) }
                    .keyboardShortcut("8", modifiers: .command)
                Button("Forms") { NotificationCenter.default.post(name: .navigateToForms, object: nil) }
                    .keyboardShortcut("9", modifiers: .command)
            }
            
            CommandGroup(after: .help) {
                Button("Twilio Setup Tutorial") {
                    NotificationCenter.default.post(name: .openTwilioTutorial, object: nil)
                }
            }
        }
        
        Settings {
            SettingsView()
                .frame(width: 600, height: 500)
                .environmentObject(subscriptionManager)
        }
    }
    
    // MARK: - Deep Link Handling
    
    private func handleDeepLink(_ url: URL) {
        // Check if this is an auth callback
        guard url.scheme == "protech", url.host == "auth-callback" else {
            print("⚠️ Unhandled URL scheme: \(url)")
            return
        }
        
        print("✅ Handling auth callback: \(url)")
        
        Task {
            do {
                try await supabaseAuth.handleAuthCallback(url: url)
                print("✅ Successfully authenticated via email confirmation")
            } catch {
                print("❌ Error handling auth callback: \(error)")
            }
        }
    }
}
