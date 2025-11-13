//
//  SquareSettingsView.swift
//  ProTech
//
//  Square POS configuration
//

import SwiftUI
import CoreData

struct SquareSettingsView: View {
    @State private var accessToken = ""
    @State private var locationId = ""
    @State private var environment: SquareEnvironment = .production
    @State private var isConnected = false
    @State private var testingConnection = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section("Square Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Access Token")
                        .font(.headline)
                    SecureField("Paste your Square Access Token", text: $accessToken)
                        .textFieldStyle(.roundedBorder)
                    Text("Get this from Square Developer Dashboard → Credentials")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location ID")
                        .font(.headline)
                    TextField("Square Location ID", text: $locationId)
                        .textFieldStyle(.roundedBorder)
                    Text("Will be auto-fetched when you test connection")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Picker("Environment", selection: $environment) {
                    Text("Sandbox (Testing)").tag(SquareEnvironment.sandbox)
                    Text("Production (Live)").tag(SquareEnvironment.production)
                }
            }
            
            Section("Connection Status") {
                HStack {
                    Image(systemName: isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isConnected ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(isConnected ? "Connected to Square" : "Not Connected")
                            .font(.headline)
                        if isConnected {
                            Text("Ready to process payments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                Button {
                    testConnection()
                } label: {
                    HStack {
                        if testingConnection {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(testingConnection ? "Testing..." : "Test Connection")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(accessToken.isEmpty || testingConnection)
            }
            
            Section("Setup Instructions") {
                VStack(alignment: .leading, spacing: 12) {
                    Label("1. Create Square Developer Account", systemImage: "1.circle.fill")
                    Text("Visit developer.squareup.com/apps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("2. Create New Application", systemImage: "2.circle.fill")
                    Text("Click 'Create App' and name it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("3. Get Access Token", systemImage: "3.circle.fill")
                    Text("Go to Credentials tab and copy token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("4. Paste Token Above", systemImage: "4.circle.fill")
                    Text("Then click 'Test Connection'")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Square Settings")
        .onAppear {
            loadConfiguration()
        }
        .alert("Connection Error", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadConfiguration() {
        if let token = SecureStorage.retrieve(key: SecureStorage.Keys.squareAccessToken) {
            accessToken = token
            isConnected = true
        }
        if let location = SecureStorage.retrieve(key: SecureStorage.Keys.squareLocationId) {
            locationId = location
        }
        if let envString = SecureStorage.retrieve(key: SecureStorage.Keys.squareEnvironment),
           let env = SquareEnvironment(rawValue: envString) {
            environment = env
        }
    }
    
    private func testConnection() {
        testingConnection = true
        errorMessage = ""
        
        // Save configuration first
        _ = SecureStorage.save(key: SecureStorage.Keys.squareAccessToken, value: accessToken)
        _ = SecureStorage.save(key: SecureStorage.Keys.squareEnvironment, value: environment.rawValue)
        
        // Create a temporary configuration for testing
        // Note: SquareConfiguration is a Core Data entity, so we'll create it in memory
        let context = CoreDataManager.shared.viewContext
        let tempConfig = SquareConfiguration(context: context)
        tempConfig.accessToken = accessToken
        tempConfig.environmentRaw = environment.rawValue
        tempConfig.locationId = locationId
        tempConfig.merchantId = "test" // placeholder for connection test
        
        SquareAPIService.shared.setConfiguration(tempConfig)
        
        // Test connection by fetching locations
        Task {
            do {
                let locations = try await SquareAPIService.shared.listLocations()
                
                await MainActor.run {
                    testingConnection = false
                    
                    // Clean up temporary Core Data object
                    context.rollback()
                    
                    if locations.isEmpty {
                        isConnected = false
                        errorMessage = "No locations found. Please check your Square account."
                        showingError = true
                    } else {
                        isConnected = true
                        
                        // Auto-fill first location if not set
                        if locationId.isEmpty, let firstLocation = locations.first {
                            locationId = firstLocation.id
                            _ = SecureStorage.save(key: SecureStorage.Keys.squareLocationId, value: locationId)
                        }
                        
                        errorMessage = "✅ Connected! Found \(locations.count) location(s): \(locations.map { $0.name ?? "Unnamed" }.joined(separator: ", "))"
                        showingError = true
                    }
                }
            } catch let error as SquareAPIError {
                await MainActor.run {
                    testingConnection = false
                    isConnected = false
                    
                    // Clean up temporary Core Data object
                    context.rollback()
                    
                    switch error {
                    case .unauthorized:
                        errorMessage = "Unauthorized: Invalid access token. Please check your credentials."
                    case .notConfigured:
                        errorMessage = "Configuration error: Please enter your access token."
                    case .apiError(let message):
                        errorMessage = "Square API Error: \(message)"
                    case .rateLimitExceeded:
                        errorMessage = "Rate limit exceeded. Please try again in a moment."
                    default:
                        errorMessage = "Connection failed: \(error.localizedDescription)"
                    }
                    showingError = true
                }
            } catch {
                await MainActor.run {
                    testingConnection = false
                    isConnected = false
                    
                    // Clean up temporary Core Data object
                    context.rollback()
                    
                    errorMessage = "Connection failed: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

struct SquareSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SquareSettingsView()
        }
    }
}
