//
//  SquareInventorySyncSettingsView.swift
//  ProTech
//
//  Settings view for Square Inventory Sync integration
//

import SwiftUI
import SwiftData

struct SquareInventorySyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var syncManager: SquareInventorySyncManager
    @State private var configuration: SquareConfiguration?
    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var locations: [Location] = []
    @State private var selectedLocationId = ""
    @State private var testingConnection = false
    
    init(modelContext: ModelContext) {
        _syncManager = StateObject(wrappedValue: SquareInventorySyncManager(modelContext: modelContext))
    }
    
    var body: some View {
        Form {
            // Connection Status Section
            Section {
                if let config = configuration {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Connected to Square")
                                .font(.headline)
                            Text("Merchant ID: \(config.merchantId)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Disconnect") {
                            disconnectSquare()
                        }
                        .foregroundColor(.red)
                    }
                } else {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Not Connected")
                            .font(.headline)
                        Spacer()
                        Button("Connect to Square") {
                            connectToSquare()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } header: {
                Text("Connection Status")
            }
            
            // Location Settings
            if let config = configuration {
                Section {
                    Picker("Primary Location", selection: $selectedLocationId) {
                        ForEach(locations, id: \.id) { location in
                            Text(location.name ?? location.id)
                                .tag(location.id)
                        }
                    }
                    .onChange(of: selectedLocationId) { _, newValue in
                        updateLocation(newValue)
                    }
                    
                    if !locations.isEmpty {
                        Text("\(locations.count) location(s) available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("Select the Square location to sync inventory with")
                }
                
                // Environment
                Section {
                    Picker("Environment", selection: Binding(
                        get: { config.environment },
                        set: { updateEnvironment($0) }
                    )) {
                        Text(SquareEnvironment.sandbox.displayName)
                            .tag(SquareEnvironment.sandbox)
                        Text(SquareEnvironment.production.displayName)
                            .tag(SquareEnvironment.production)
                    }
                } header: {
                    Text("Environment")
                } footer: {
                    Text("Use Sandbox for testing, Production for live data")
                }
                
                // Sync Settings
                Section {
                    Toggle("Enable Auto-Sync", isOn: Binding(
                        get: { config.syncEnabled },
                        set: { updateSyncEnabled($0) }
                    ))
                    
                    if config.syncEnabled {
                        Picker("Sync Interval", selection: Binding(
                            get: { config.syncInterval },
                            set: { updateSyncInterval($0) }
                        )) {
                            Text(TimeInterval.fifteenMinutes.syncIntervalDisplayName)
                                .tag(TimeInterval.fifteenMinutes)
                            Text(TimeInterval.thirtyMinutes.syncIntervalDisplayName)
                                .tag(TimeInterval.thirtyMinutes)
                            Text(TimeInterval.oneHour.syncIntervalDisplayName)
                                .tag(TimeInterval.oneHour)
                            Text(TimeInterval.fourHours.syncIntervalDisplayName)
                                .tag(TimeInterval.fourHours)
                            Text(TimeInterval.daily.syncIntervalDisplayName)
                                .tag(TimeInterval.daily)
                        }
                    }
                    
                    Picker("Sync Direction", selection: Binding(
                        get: { config.defaultSyncDirection },
                        set: { updateSyncDirection($0) }
                    )) {
                        Text(SyncDirection.bidirectional.displayName)
                            .tag(SyncDirection.bidirectional)
                        Text(SyncDirection.toSquare.displayName)
                            .tag(SyncDirection.toSquare)
                        Text(SyncDirection.fromSquare.displayName)
                            .tag(SyncDirection.fromSquare)
                    }
                    
                    Picker("Conflict Resolution", selection: Binding(
                        get: { config.defaultConflictResolution },
                        set: { updateConflictResolution($0) }
                    )) {
                        Text(ConflictResolutionStrategy.mostRecent.displayName)
                            .tag(ConflictResolutionStrategy.mostRecent)
                        Text(ConflictResolutionStrategy.squareWins.displayName)
                            .tag(ConflictResolutionStrategy.squareWins)
                        Text(ConflictResolutionStrategy.proTechWins.displayName)
                            .tag(ConflictResolutionStrategy.proTechWins)
                        Text(ConflictResolutionStrategy.manual.displayName)
                            .tag(ConflictResolutionStrategy.manual)
                    }
                } header: {
                    Text("Sync Settings")
                } footer: {
                    Text("Configure how and when inventory syncs with Square")
                }
                
                // Last Sync Info
                Section {
                    if let lastSync = config.lastFullSync {
                        LabeledContent("Last Full Sync", value: lastSync, format: .dateTime)
                    } else {
                        Text("Never synced")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Sync History")
                }
                
                // Actions
                Section {
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            if testingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("Test Connection")
                        }
                    }
                    .disabled(testingConnection)
                } header: {
                    Text("Actions")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Square Integration")
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            loadConfiguration()
            if configuration != nil {
                await loadLocations()
            }
        }
    }
    
    // MARK: - Actions
    
    private func connectToSquare() {
        // In a real implementation, this would open the OAuth flow
        // For now, we'll show a placeholder
        isConnecting = true
        
        // Simulate OAuth flow
        Task {
            do {
                // This would be replaced with actual OAuth implementation
                let config = SquareConfiguration(
                    accessToken: "PLACEHOLDER_TOKEN",
                    merchantId: "PLACEHOLDER_MERCHANT",
                    locationId: "PLACEHOLDER_LOCATION",
                    environment: .sandbox
                )
                
                try syncManager.saveConfiguration(config)
                self.configuration = config
                await loadLocations()
                isConnecting = false
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                isConnecting = false
            }
        }
    }
    
    private func disconnectSquare() {
        if let config = configuration {
            modelContext.delete(config)
            try? modelContext.save()
            self.configuration = nil
            self.locations = []
        }
    }
    
    private func testConnection() {
        testingConnection = true
        
        Task {
            do {
                let isValid = try await SquareAPIService.shared.validateToken()
                if isValid {
                    errorMessage = "Connection successful!"
                } else {
                    errorMessage = "Connection failed. Please reconnect."
                }
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            testingConnection = false
        }
    }
    
    private func loadConfiguration() {
        configuration = syncManager.getConfiguration()
        if let config = configuration {
            selectedLocationId = config.locationId
            SquareAPIService.shared.setConfiguration(config)
        }
    }
    
    private func loadLocations() async {
        do {
            locations = try await SquareAPIService.shared.listLocations()
        } catch {
            errorMessage = "Failed to load locations: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func updateLocation(_ locationId: String) {
        guard let config = configuration else { return }
        config.locationId = locationId
        config.locationName = locations.first(where: { $0.id == locationId })?.name
        config.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func updateEnvironment(_ environment: SquareEnvironment) {
        guard let config = configuration else { return }
        config.environment = environment
        config.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func updateSyncEnabled(_ enabled: Bool) {
        guard let config = configuration else { return }
        config.syncEnabled = enabled
        config.updatedAt = Date()
        try? modelContext.save()
        
        if enabled {
            syncManager.startAutoSync(interval: config.syncInterval)
        } else {
            syncManager.stopAutoSync()
        }
    }
    
    private func updateSyncInterval(_ interval: TimeInterval) {
        guard let config = configuration else { return }
        config.syncInterval = interval
        config.updatedAt = Date()
        try? modelContext.save()
        
        if config.syncEnabled {
            syncManager.startAutoSync(interval: interval)
        }
    }
    
    private func updateSyncDirection(_ direction: SyncDirection) {
        guard let config = configuration else { return }
        config.defaultSyncDirection = direction
        config.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func updateConflictResolution(_ strategy: ConflictResolutionStrategy) {
        guard let config = configuration else { return }
        config.defaultConflictResolution = strategy
        config.updatedAt = Date()
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SquareInventorySyncSettingsView(modelContext: ModelContext(try! ModelContainer(for: SquareConfiguration.self)))
    }
}
