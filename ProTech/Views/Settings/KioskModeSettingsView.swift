//
//  KioskModeSettingsView.swift
//  ProTech
//
//  Kiosk mode configuration settings
//

import SwiftUI

struct KioskModeSettingsView: View {
    @ObservedObject var kioskManager = KioskModeManager.shared
    @State private var showingEnableConfirmation = false
    @State private var showingDisableConfirmation = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Kiosk Mode", isOn: Binding(
                    get: { kioskManager.isKioskModeEnabled },
                    set: { newValue in
                        if newValue {
                            showingEnableConfirmation = true
                        } else {
                            showingDisableConfirmation = true
                        }
                    }
                ))
                
                if kioskManager.isKioskModeEnabled {
                    HStack {
                        Text("Status")
                        Spacer()
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            } header: {
                Text("Kiosk Mode")
            } footer: {
                Text("Kiosk mode locks the app to the Customer Portal for walk-up customer self-service. Use ⌘⇧Q or tap the top-right corner to exit with passcode.")
            }
            
            Section {
                TextField("Welcome Title", text: $kioskManager.kioskTitle)
                
                TextField("Welcome Message", text: $kioskManager.kioskWelcomeMessage, axis: .vertical)
                    .lineLimit(2...4)
            } header: {
                Text("Customization")
            }
            
            Section {
                SecureField("Admin Passcode", text: $kioskManager.adminPasscode)
                    .help("Passcode required to exit kiosk mode")
                
                Stepper("Auto-logout: \(kioskManager.autoLogoutAfterSeconds / 60) minutes", value: $kioskManager.autoLogoutAfterSeconds, in: 60...1800, step: 60)
                    .help("Automatically log out inactive customers")
            } header: {
                Text("Security")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Customer Self-Registration", systemImage: "person.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text("Customers can create profiles if not found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Auto-Logout Timer", systemImage: "clock.badge.checkmark")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    Text("Sessions end after \(kioskManager.autoLogoutAfterSeconds / 60) minutes of inactivity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Label("Admin Access", systemImage: "lock.shield")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text("Press ⌘⇧Q or tap top-right corner, then enter passcode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Features")
            }
            
            if kioskManager.isKioskModeEnabled {
                Section {
                    Button(role: .destructive) {
                        showingDisableConfirmation = true
                    } label: {
                        Label("Disable Kiosk Mode", systemImage: "xmark.circle")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Kiosk Mode")
        .alert("Enable Kiosk Mode?", isPresented: $showingEnableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Enable") {
                kioskManager.enableKioskMode()
            }
        } message: {
            Text("The app will lock to Customer Portal only. You'll need the admin passcode to exit.")
        }
        .alert("Disable Kiosk Mode?", isPresented: $showingDisableConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Disable", role: .destructive) {
                _ = kioskManager.disableKioskMode(withPasscode: kioskManager.adminPasscode)
            }
        } message: {
            Text("The app will return to normal operation with full admin access.")
        }
    }
}

#Preview {
    NavigationStack {
        KioskModeSettingsView()
    }
}
