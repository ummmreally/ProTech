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
            
            SquareInventorySyncSettingsView()
                .tabItem {
                    Label("Square", systemImage: "cart")
                }
                .tag(SettingsTab.square)
            
            SocialMediaPlatformSettingsView()
                .tabItem {
                    Label("Social Media", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(SettingsTab.socialMedia)
            
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
            
            DeveloperSettingsView()
                .tabItem {
                    Label("Developer", systemImage: "hammer.fill")
                }
                .tag(SettingsTab.developer)
        }
        .frame(minWidth: 600, minHeight: 500)
    }
}

enum SettingsTab {
    case general, sms, square, socialMedia, forms, subscription, developer
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("companyName") private var companyName = ""
    @AppStorage("brandName") private var brandName = "ProTech"
    @AppStorage("companyEmail") private var companyEmail = ""
    @AppStorage("companyPhone") private var companyPhone = ""
    @AppStorage("companyAddress") private var companyAddress = ""
    @AppStorage("customLogoPath") private var customLogoPath = ""
    
    @State private var showingImagePicker = false
    
    var body: some View {
        Form {
            Section("Branding") {
                TextField("Brand Name (shown on login)", text: $brandName)
                    .help("This name will appear on the login screen")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Login Screen Logo")
                        .font(.headline)
                    
                    if !customLogoPath.isEmpty, let nsImage = NSImage(contentsOfFile: customLogoPath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    } else {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Button("Choose Logo...") {
                            showingImagePicker = true
                        }
                        
                        if !customLogoPath.isEmpty {
                            Button("Remove Logo") {
                                customLogoPath = ""
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
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
        .fileImporter(
            isPresented: $showingImagePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleImageSelection(result)
        }
    }
    
    private func handleImageSelection(_ result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }
            
            // Get access to security-scoped resource
            guard selectedFile.startAccessingSecurityScopedResource() else {
                print("Failed to access file")
                return
            }
            defer { selectedFile.stopAccessingSecurityScopedResource() }
            
            // Create app support directory for logos
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let logoDir = appSupport.appendingPathComponent("ProTech/Logos", isDirectory: true)
            
            try FileManager.default.createDirectory(at: logoDir, withIntermediateDirectories: true)
            
            // Copy file to app support
            let destinationURL = logoDir.appendingPathComponent("login_logo\(selectedFile.pathExtension.isEmpty ? "" : "." + selectedFile.pathExtension)")
            
            // Remove existing logo if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            try FileManager.default.copyItem(at: selectedFile, to: destinationURL)
            
            // Save path
            customLogoPath = destinationURL.path
            
        } catch {
            print("Error selecting logo: \(error.localizedDescription)")
        }
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

// MARK: - Developer Settings

struct DeveloperSettingsView: View {
    @AppStorage("developerProModeEnabled") private var proModeEnabled = false
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "hammer.fill")
                            .foregroundColor(.orange)
                        Text("Developer Mode")
                            .font(.headline)
                    }
                    Text("These settings are for testing and development only.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Pro Features Testing") {
                Toggle(isOn: $proModeEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Pro Mode")
                            .font(.body)
                        Text("Test premium features without subscription")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: proModeEnabled) { _, newValue in
                    // Force update subscription status
                    subscriptionManager.objectWillChange.send()
                }
                
                if proModeEnabled {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Pro Mode Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section("Current Status") {
                LabeledContent("Real Subscription") {
                    Text(subscriptionManager.hasActiveSubscription ? "Active" : "None")
                        .foregroundColor(subscriptionManager.hasActiveSubscription ? .green : .secondary)
                }
                
                LabeledContent("Developer Override") {
                    Text(proModeEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(proModeEnabled ? .orange : .secondary)
                }
                
                LabeledContent("Effective Status") {
                    Text(subscriptionManager.isProSubscriber || proModeEnabled ? "Pro" : "Free")
                        .foregroundColor(subscriptionManager.isProSubscriber || proModeEnabled ? .green : .secondary)
                }
            }
            
            Section("Features Unlocked") {
                ForEach(PremiumFeature.allCases, id: \.self) { feature in
                    HStack {
                        Image(systemName: subscriptionManager.isProSubscriber || proModeEnabled ? "checkmark.circle.fill" : "lock.circle.fill")
                            .foregroundColor(subscriptionManager.isProSubscriber || proModeEnabled ? .green : .gray)
                        Text(feature.rawValue)
                            .foregroundColor(subscriptionManager.isProSubscriber || proModeEnabled ? .primary : .secondary)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("⚠️ Important")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Remember to disable Pro Mode before releasing to production or submitting to the App Store.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}
