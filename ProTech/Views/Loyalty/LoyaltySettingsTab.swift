//
//  LoyaltySettingsTab.swift
//  ProTech
//
//  Configure loyalty program settings
//

import SwiftUI

struct LoyaltySettingsTab: View {
    @ObservedObject var program: LoyaltyProgram
    
    @State private var name: String = ""
    @State private var pointsPerDollar: String = ""
    @State private var pointsPerVisit: String = ""
    @State private var enableTiers: Bool = true
    @State private var enableAutoNotifications: Bool = true
    @State private var pointsExpirationDays: String = ""
    @State private var isActive: Bool = true
    
    var body: some View {
        Form {
            Section("Program Configuration") {
                TextField("Program Name", text: $name)
                
                Toggle("Program Active", isOn: $isActive)
                    .tint(.green)
            }
            
            Section("Points Earning") {
                HStack {
                    Text("Points per Dollar Spent")
                    Spacer()
                    TextField("1.0", text: $pointsPerDollar)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Bonus Points per Visit")
                    Spacer()
                    TextField("10", text: $pointsPerVisit)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Points Expiration (days)")
                    Spacer()
                    TextField("0 = never", text: $pointsExpirationDays)
                        .frame(width: 100)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Features") {
                Toggle("Enable VIP Tiers", isOn: $enableTiers)
                    .tint(.purple)
                
                Toggle("Auto SMS Notifications", isOn: $enableAutoNotifications)
                    .tint(.blue)
            }
            
            Section("Actions") {
                Button {
                    saveSettings()
                } label: {
                    Label("Save Settings", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .formStyle(.grouped)
        .onAppear {
            loadSettings()
        }
    }
    
    private func loadSettings() {
        name = program.name ?? ""
        pointsPerDollar = "\(program.pointsPerDollar)"
        pointsPerVisit = "\(program.pointsPerVisit)"
        enableTiers = program.enableTiers
        enableAutoNotifications = program.enableAutoNotifications
        pointsExpirationDays = "\(program.pointsExpirationDays)"
        isActive = program.isActive
    }
    
    private func saveSettings() {
        program.name = name
        program.pointsPerDollar = Double(pointsPerDollar) ?? 1.0
        program.pointsPerVisit = Int32(pointsPerVisit) ?? 10
        program.enableTiers = enableTiers
        program.enableAutoNotifications = enableAutoNotifications
        program.pointsExpirationDays = Int32(pointsExpirationDays) ?? 0
        program.isActive = isActive
        program.updatedAt = Date()
        
        CoreDataManager.shared.save()
    }
}
