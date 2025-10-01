//
//  SettingsView.swift
//  ProTech
//
//  Main settings view with tabs
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var selectedTab: SettingsTab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)
            
            TwilioSettingsView()
                .tabItem {
                    Label("SMS", systemImage: "message")
                }
                .tag(SettingsTab.sms)
            
            FormsSettingsView()
                .tabItem {
                    Label("Forms", systemImage: "doc.text")
                }
                .tag(SettingsTab.forms)
            
            SubscriptionSettingsView()
                .tabItem {
                    Label("Subscription", systemImage: "star")
                }
                .tag(SettingsTab.subscription)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

enum SettingsTab {
    case general, sms, forms, subscription
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    
    var body: some View {
        Form {
            Section("Company Information") {
                TextField("Company Name", text: $companyName)
                TextField("Email", text: $companyEmail)
                TextField("Phone", text: $companyPhone)
                TextField("Address", text: $companyAddress)
            }
            
            Section("About") {
                LabeledContent("App Name", value: Configuration.appName)
                LabeledContent("Version", value: Configuration.version)
                LabeledContent("Build", value: Configuration.build)
            }
            
            Section("Support") {
                Link(destination: Configuration.supportURL) {
                    Label("Support Website", systemImage: "arrow.up.forward.app")
                }
                Link(destination: Configuration.privacyPolicyURL) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Subscription Settings

struct SubscriptionSettingsView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var subscriptionInfo: SubscriptionInfo?
    @State private var showingUpgrade = false
    @State private var isLoadingInfo = true
    
    var body: some View {
        Form {
            if subscriptionManager.isProSubscriber {
                Section("Current Subscription") {
                    if isLoadingInfo {
                        ProgressView()
                    } else if let info = subscriptionInfo {
                        LabeledContent("Plan", value: info.productName)
                        LabeledContent("Price", value: info.price)
                        LabeledContent("Expires", value: info.formattedExpirationDate)
                        LabeledContent("Status") {
                            HStack {
                                Circle()
                                    .fill(info.isActive ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(info.isActive ? "Active" : "Expired")
                            }
                        }
                        if info.daysRemaining > 0 {
                            LabeledContent("Days Remaining", value: "\(info.daysRemaining)")
                        }
                    } else {
                        Text("Unable to load subscription info")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Features Unlocked") {
                    ForEach(PremiumFeature.allCases, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(feature.rawValue)
                        }
                    }
                }
            } else {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Free Version")
                            .font(.headline)
                        Text("You're using the free version with limited features.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button {
                        showingUpgrade = true
                    } label: {
                        Label("Upgrade to Pro", systemImage: "star.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Section {
                Button("Restore Purchases") {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            subscriptionInfo = await subscriptionManager.getSubscriptionInfo()
            isLoadingInfo = false
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
        }
    }
}
