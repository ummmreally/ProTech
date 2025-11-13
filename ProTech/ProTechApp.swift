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
    @StateObject private var employeeService = EmployeeService()
    let persistenceController = CoreDataManager.shared
    
    init() {
        // Load default form templates on first launch
        FormService.shared.loadDefaultTemplates()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.viewContext)
                        .environmentObject(subscriptionManager)
                        .environmentObject(authService)
                        .frame(minWidth: 900, minHeight: 600)
                        .onAppear {
                            // Check subscription status on launch
                            Task {
                                await subscriptionManager.checkSubscriptionStatus()
                            }
                        }
                } else {
                    LoginView()
                        .frame(minWidth: 600, minHeight: 800)
                        .onAppear {
                            // Create default admin if needed
                            employeeService.createDefaultAdminIfNeeded()
                        }
                }
            }
        }
        .defaultSize(width: 650, height: 850)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Customer") {
                    NotificationCenter.default.post(name: .newCustomer, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
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
}
