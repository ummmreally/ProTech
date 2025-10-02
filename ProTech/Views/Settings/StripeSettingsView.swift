//
//  StripeSettingsView.swift
//  ProTech
//
//  Stripe API configuration and settings
//

import SwiftUI

struct StripeSettingsView: View {
    @State private var apiKey = ""
    @State private var testMode = true
    @State private var showingAPIKey = false
    @State private var isConfigured = false
    @State private var showingSaveAlert = false
    
    private let stripeService = StripeService.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stripe Integration")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure payment processing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(isConfigured ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    Text(isConfigured ? "Connected" : "Not Connected")
                        .font(.subheadline)
                        .foregroundColor(isConfigured ? .green : .red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
            .padding()
            
            Divider()
            
            // Configuration Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // API Key Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Configuration")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Test Mode", isOn: $testMode)
                            
                            Text("Use test API keys for development")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("API Key")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Button {
                                    showingAPIKey.toggle()
                                } label: {
                                    Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if showingAPIKey {
                                TextField("sk_test_...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            } else {
                                SecureField("sk_test_...", text: $apiKey)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(.body, design: .monospaced))
                            }
                            
                            Text(testMode ? "Enter your Stripe test API key" : "Enter your Stripe live API key")
                                .font(.caption)
                                .foregroundColor(testMode ? .orange : .red)
                        }
                        
                        Button {
                            saveConfiguration()
                        } label: {
                            Label("Save Configuration", systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKey.isEmpty)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Get Your API Keys")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            InstructionStep(number: 1, text: "Go to dashboard.stripe.com")
                            InstructionStep(number: 2, text: "Navigate to Developers → API keys")
                            InstructionStep(number: 3, text: "Copy your Secret key (starts with sk_test_ or sk_live_)")
                            InstructionStep(number: 4, text: "Paste it above and save")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "creditcard.fill", title: "Credit Card Processing", description: "Accept Visa, Mastercard, Amex, and more")
                        FeatureRow(icon: "lock.shield.fill", title: "Secure Payments", description: "PCI-compliant payment processing")
                        FeatureRow(icon: "arrow.uturn.backward", title: "Refunds", description: "Issue full or partial refunds")
                        FeatureRow(icon: "wallet.pass.fill", title: "Saved Cards", description: "Save payment methods for repeat customers")
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Help Links
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Resources")
                            .font(.headline)
                        
                        Link(destination: URL(string: "https://stripe.com/docs")!) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Stripe Documentation")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                        
                        Link(destination: URL(string: "https://dashboard.stripe.com")!) {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("Stripe Dashboard")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .onAppear {
            loadConfiguration()
        }
        .alert("Configuration Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text("Stripe API key has been saved successfully. You can now process payments.")
        }
    }
    
    private func loadConfiguration() {
        isConfigured = stripeService.isConfigured()
        // Note: For security, we don't show the actual API key
        // In production, never display or log API keys
    }
    
    private func saveConfiguration() {
        stripeService.configure(apiKey: apiKey)
        isConfigured = true
        showingSaveAlert = true
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Preview

struct StripeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        StripeSettingsView()
    }
}
