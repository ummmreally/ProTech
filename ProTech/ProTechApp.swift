//
//  ProTechApp.swift
//  ProTech
//
//  Main app entry point
//

import SwiftUI

@main
struct ProTechApp: App {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    let persistenceController = CoreDataManager.shared
    
    init() {
        // Load default form templates on first launch
        FormService.shared.loadDefaultTemplates()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
                .environmentObject(subscriptionManager)
                .frame(minWidth: 900, minHeight: 600)
                .onAppear {
                    // Check subscription status on launch
                    Task {
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                }
        }
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
