//
//  TwilioSettingsView.swift
//  ProTech
//
//  Twilio SMS configuration settings
//

import SwiftUI

struct TwilioSettingsView: View {
    @State private var accountSID = ""
    @State private var authToken = ""
    @State private var phoneNumber = ""
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
            
            Section("Twilio Credentials") {
                TextField("Account SID", text: $accountSID)
                    .textContentType(.username)
                    .font(.system(.body, design: .monospaced))
                    .help("Starts with 'AC' - found in Twilio Console")
                
                SecureField("Auth Token", text: $authToken)
                    .textContentType(.password)
                    .font(.system(.body, design: .monospaced))
                    .help("Click the eye icon in Twilio Console to reveal")
                
                TextField("Phone Number", text: $phoneNumber, prompt: Text("+15551234567"))
                    .textContentType(.telephoneNumber)
                    .font(.system(.body, design: .monospaced))
                    .help("Use E.164 format: +1XXXXXXXXXX")
            }
            
            Section {
                HStack {
                    Button("Save Credentials") {
                        saveCredentials()
                    }
                    .disabled(accountSID.isEmpty || authToken.isEmpty || phoneNumber.isEmpty)
                    
                    Spacer()
                    
                    if isTesting {
                        ProgressView()
                            .controlSize(.small)
                    }
                    
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(!TwilioService.shared.isConfigured || isTesting)
                }
            }
            
            if showTestResult {
                Section {
                    HStack {
                        Image(systemName: isTestSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isTestSuccess ? .green : .red)
                        Text(testResult)
                            .font(.body)
                    }
                }
            }
            
            Section("How It Works") {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(number: "1", text: "Create a Twilio account and get a phone number")
                    InfoRow(number: "2", text: "Copy your Account SID and Auth Token")
                    InfoRow(number: "3", text: "Paste credentials here and save")
                    InfoRow(number: "4", text: "Send unlimited SMS to your customers!")
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
        .onAppear {
            loadCredentials()
        }
        .sheet(isPresented: $showTutorial) {
            TwilioTutorialView()
        }
    }
    
    private func loadCredentials() {
        accountSID = SecureStorage.retrieve(key: SecureStorage.Keys.twilioAccountSID) ?? ""
        authToken = SecureStorage.retrieve(key: SecureStorage.Keys.twilioAuthToken) ?? ""
        phoneNumber = SecureStorage.retrieve(key: SecureStorage.Keys.twilioPhoneNumber) ?? ""
    }
    
    private func saveCredentials() {
        let success = TwilioService.shared.saveCredentials(
            accountSID: accountSID,
            authToken: authToken,
            phoneNumber: phoneNumber
        )
        
        if success {
            testResult = "✅ Credentials saved successfully!"
            isTestSuccess = true
            showTestResult = true
        } else {
            testResult = "❌ Failed to save credentials"
            isTestSuccess = false
            showTestResult = true
        }
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
