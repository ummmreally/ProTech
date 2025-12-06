//
//  TwilioSettingsView.swift
//  ProTech
//
//  Twilio SMS configuration settings
//

import SwiftUI

struct TwilioSettingsView: View {
    @State private var isTesting = false
    @State private var testResult = ""
    @State private var showTestResult = false
    @State private var isTestSuccess = false
    @State private var showTutorial = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Configure your Twilio account to send SMS messages to customers.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Don't have a Twilio account?")
                            .font(.callout)
                        Link("Sign up here →", destination: Configuration.twilioSignupURL)
                            .font(.callout)
                    }
                    
                    Button {
                        showTutorial = true
                    } label: {
                        Label("View Setup Tutorial", systemImage: "book.fill")
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                }
            }
            
            Section("Integration Status") {
                HStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: TwilioConfig.isConfigured ? "checkmark.shield.fill" : "xmark.shield.fill")
                        .foregroundColor(TwilioConfig.isConfigured ? .green : .red)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(TwilioConfig.isConfigured ? "Twilio Connected" : "Twilio Not Configured")
                            .font(.headline)
                        Text("Credentials are bundled directly with the app build.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Configured Credentials") {
                LabeledContent("Account SID") {
                    Text(maskedValue(TwilioConfig.accountSID))
                        .font(.system(.body, design: .monospaced))
                }
                LabeledContent("Auth Token") {
                    Text(maskedValue(TwilioConfig.authToken))
                        .font(.system(.body, design: .monospaced))
                }
                LabeledContent("Phone Number") {
                    Text(TwilioConfig.phoneNumber)
                        .font(.system(.body, design: .monospaced))
                }
                Text("To update these credentials, change them in SupabaseConfig.swift and rebuild the app.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, AppTheme.Spacing.xs)
            }
            
            Section("Diagnostics") {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Button {
                            testConnection()
                        } label: {
                            HStack {
                                if isTesting {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(isTesting ? "Testing..." : "Send Test SMS")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!TwilioService.shared.isConfigured || isTesting)
                    }
                    
                    if showTestResult {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: isTestSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isTestSuccess ? .green : .red)
                            Text(testResult)
                                .font(.body)
                        }
                        .padding(.top, AppTheme.Spacing.xs)
                    }
                }
            }
            
            Section("How It Works") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(number: "1", text: "Create a Twilio account and get a phone number")
                    InfoRow(number: "2", text: "Add your Account SID, Auth Token, and phone number in SupabaseConfig.swift")
                    InfoRow(number: "3", text: "Rebuild the app to bundle updated credentials securely")
                    InfoRow(number: "4", text: "Use the test button above to confirm connectivity")
                }
            }
            
            Section("Pricing") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Phone number: ~$1-2/month")
                    Text("• SMS in US: ~$0.0079 per message")
                    Text("• You pay Twilio directly")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showTutorial) {
            TwilioTutorialView()
        }
    }
    
    private func maskedValue(_ value: String) -> String {
        guard value.count > 6 else { return value }
        let prefix = value.prefix(4)
        let suffix = value.suffix(4)
        return "\(prefix)…\(suffix)"
    }
    
    private func testConnection() {
        isTesting = true
        showTestResult = false
        
        Task {
            let result = await TwilioService.shared.testConnection()
            
            await MainActor.run {
                isTesting = false
                showTestResult = true
                
                switch result {
                case .success(let message):
                    testResult = "✅ " + message
                    isTestSuccess = true
                case .failure(let error):
                    testResult = "❌ " + (error.errorDescription ?? "Test failed")
                    isTestSuccess = false
                }
            }
        }
    }
}
