//
//  SquareInventorySyncSettingsView.swift
//  ProTech
//
//  Settings view for Square Inventory Sync integration
//

import SwiftUI
import CoreData

struct SquareInventorySyncSettingsView: View {
    private let context: NSManagedObjectContext
    @StateObject private var syncManager: SquareInventorySyncManager
    @State private var configuration: SquareConfiguration?
    @State private var isConnecting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var locations: [Location] = []
    @State private var selectedLocationId = ""
    @State private var testingConnection = false
    @State private var showManualSetup = false
    @State private var manualAccessToken = ""
    @State private var manualMerchantId = ""
    @State private var manualLocationId = ""
    @State private var manualEnvironment: SquareEnvironment = .sandbox
    @State private var showSheetError = false
    @State private var sheetErrorMessage = ""
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        _syncManager = StateObject(wrappedValue: SquareInventorySyncManager(context: context))
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
                            Text("Merchant ID: \(config.merchantId ?? "Unknown")")
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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("Not Connected")
                                .font(.headline)
                            Spacer()
                        }
                        
                        Text("Enter your Square credentials to enable inventory sync")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button {
                            // Reset form state when opening
                            manualAccessToken = ""
                            manualLocationId = ""
                            manualEnvironment = .sandbox
                            showSheetError = false
                            sheetErrorMessage = ""
                            showManualSetup = true
                        } label: {
                            HStack {
                                Image(systemName: "key.fill")
                                Text("Enter Square Credentials")
                            }
                            .frame(maxWidth: .infinity)
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
                    // Navigation to Sync Dashboard
                    NavigationLink(destination: SquareSyncDashboardView(context: context)) {
                        Label("Open Sync Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    
                    // Navigation to Customer Sync
                    NavigationLink(destination: SquareCustomerSyncView(context: context)) {
                        Label("Customer Sync", systemImage: "person.2.badge.gearshape")
                    }
                    
                    Divider()
                    
                    // Quick Sync Actions
                    Button {
                        performFullSync()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Sync All Items Now")
                            Spacer()
                            if syncManager.syncStatus == .syncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(syncManager.syncStatus == .syncing)
                    
                    Button {
                        importFromSquare()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Import from Square")
                        }
                    }
                    .disabled(syncManager.syncStatus == .syncing)
                    
                    Button {
                        exportToSquare()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.circle")
                            Text("Export to Square")
                        }
                    }
                    .disabled(syncManager.syncStatus == .syncing)
                    
                    Divider()
                    
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
                } footer: {
                    if syncManager.syncStatus == .syncing {
                        SyncProgressBar(
                            progress: syncManager.syncProgress,
                            currentOperation: syncManager.currentOperation
                        )
                        .padding(.top, 8)
                    }
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
        .sheet(isPresented: $showManualSetup) {
            manualSetupSheet
        }
        .task {
            loadConfiguration()
            if configuration != nil {
                await loadLocations()
            }
        }
    }
    
    // MARK: - Manual Setup Sheet
    
    private var manualSetupSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Get your credentials from Square Developer Dashboard")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Link("Open Square Developer Dashboard", destination: URL(string: "https://developer.squareup.com/apps")!)
                        .font(.caption)
                } header: {
                    Text("Setup Instructions")
                }
                
                Section {
                    Picker("Environment", selection: $manualEnvironment) {
                        Text("Sandbox (Testing)").tag(SquareEnvironment.sandbox)
                        Text("Production (Live)").tag(SquareEnvironment.production)
                    }
                    .pickerStyle(.segmented)
                    
                    if manualEnvironment == .sandbox {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Sandbox Mode", systemImage: "testtube.2")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("Use sandbox access token for testing. No real transactions will be processed.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Production Mode", systemImage: "checkmark.shield")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text("Use production access token. Real transactions will be processed.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Environment")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Access Token")
                            .font(.headline)
                        SecureField("Paste your Square Access Token", text: $manualAccessToken)
                            .textFieldStyle(.roundedBorder)
                        
                        if manualEnvironment == .sandbox {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Get Sandbox Token:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("1. Go to Square Developer Dashboard")
                                    .font(.caption2)
                                Text("2. Select your app → Credentials")
                                    .font(.caption2)
                                Text("3. Copy SANDBOX Access Token")
                                    .font(.caption2)
                                Text("⚠️ Token typically starts with 'EAAA...'")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                            .foregroundColor(.secondary)
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Get Production Token:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text("1. Go to Square Dashboard (squareup.com)")
                                    .font(.caption2)
                                Text("2. Apps → Manage → Your App")
                                    .font(.caption2)
                                Text("3. Copy PRODUCTION Access Token")
                                    .font(.caption2)
                                Text("⚠️ Token typically starts with 'EQ...' or other prefix")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location ID (Optional)")
                            .font(.headline)
                        TextField("Square Location ID", text: $manualLocationId)
                            .textFieldStyle(.roundedBorder)
                        Text("Will be auto-fetched if left empty")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Square Credentials")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Start with Sandbox", systemImage: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Test with sandbox credentials first before using production")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Square Setup")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showManualSetup = false
                        // Reset sheet state
                        showSheetError = false
                        sheetErrorMessage = ""
                        isConnecting = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveManualConfiguration()
                    } label: {
                        if isConnecting {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Connecting...")
                            }
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(manualAccessToken.isEmpty || isConnecting)
                }
            }
            .alert("Connection Error", isPresented: $showSheetError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(sheetErrorMessage)
            }
            .onDisappear {
                // Reset state when sheet closes
                showSheetError = false
                sheetErrorMessage = ""
                isConnecting = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveManualConfiguration() {
        isConnecting = true
        
        Task {
            do {
                // Validate token format based on environment
                let tokenPrefix = String(manualAccessToken.prefix(4))
                let isSandboxToken = tokenPrefix.lowercased().starts(with: "eaaa") // Sandbox tokens typically start with EAAA
                let isProductionToken = tokenPrefix.lowercased().starts(with: "eq") || tokenPrefix.lowercased().starts(with: "ea") // Production tokens start with EQ or EA (not EAAA)
                
                if manualEnvironment == .sandbox && !isSandboxToken && isProductionToken {
                    await MainActor.run {
                        sheetErrorMessage = """
                        ⚠️ Token Mismatch Detected
                        
                        You selected SANDBOX environment but your access token appears to be a PRODUCTION token.
                        
                        Fix:
                        • Switch environment to "Production (Live)" OR
                        • Use a sandbox access token from Square Developer Dashboard
                        
                        Sandbox tokens typically start with "EAAA..."
                        Production tokens typically start with "EQ..." or other prefixes
                        """
                        showSheetError = true
                        isConnecting = false
                    }
                    return
                }
                
                if manualEnvironment == .production && isSandboxToken {
                    await MainActor.run {
                        sheetErrorMessage = """
                        ⚠️ Token Mismatch Detected
                        
                        You selected PRODUCTION environment but your access token appears to be a SANDBOX token.
                        
                        Fix:
                        • Switch environment to "Sandbox (Testing)" OR
                        • Use a production access token from Square Dashboard
                        
                        Sandbox tokens typically start with "EAAA..."
                        Production tokens typically start with "EQ..." or other prefixes
                        """
                        showSheetError = true
                        isConnecting = false
                    }
                    return
                }
                
                // Create configuration with real credentials
                let config = SquareConfiguration(context: context)
                config.id = UUID()
                config.accessToken = manualAccessToken
                config.merchantId = "merchant_" + UUID().uuidString // Will be fetched from API
                config.locationId = manualLocationId.isEmpty ? nil : manualLocationId
                config.environment = manualEnvironment
                config.createdAt = Date()
                config.updatedAt = Date()
                
                // Save and set configuration
                try syncManager.saveConfiguration(config)
                SquareAPIService.shared.setConfiguration(config)
                
                // Try to fetch locations to validate token
                do {
                    let fetchedLocations = try await SquareAPIService.shared.listLocations()
                    
                    await MainActor.run {
                        self.locations = fetchedLocations
                        
                        // Auto-set first location if none specified
                        if manualLocationId.isEmpty, let firstLocation = fetchedLocations.first {
                            config.locationId = firstLocation.id
                            config.locationName = firstLocation.name
                            selectedLocationId = firstLocation.id
                        }
                        
                        // Fetch merchant info if available
                        try? context.save()
                        
                        self.configuration = config
                        isConnecting = false
                        showManualSetup = false // Close sheet on success
                        
                        // Show success message in main view
                        errorMessage = "✅ Successfully connected to Square \(manualEnvironment == .sandbox ? "Sandbox" : "Production")!\n\nFound \(fetchedLocations.count) location(s)."
                        showError = true
                    }
                } catch {
                    // Token invalid or other error
                    await MainActor.run {
                        context.delete(config)
                        
                        // Provide more helpful error message
                        let errorMsg = error.localizedDescription
                        if errorMsg.contains("validation") || errorMsg.contains("Unauthorized") {
                            sheetErrorMessage = """
                            ❌ Connection Failed
                            
                            \(errorMsg)
                            
                            Common Issues:
                            
                            1️⃣ Wrong Environment
                            • Sandbox token with Production selected
                            • Production token with Sandbox selected
                            
                            2️⃣ Token Issues
                            • Expired or revoked access token
                            • Token missing required permissions
                            • Copied token incorrectly (check for spaces)
                            
                            3️⃣ How to Fix
                            • Verify environment matches your token type
                            • Get fresh token from Square Dashboard
                            • Ensure token has PAYMENTS, INVENTORY, and MERCHANT permissions
                            
                            Current Selection: \(manualEnvironment == .sandbox ? "Sandbox (Testing)" : "Production (Live)")
                            """
                        } else {
                            sheetErrorMessage = "Failed to connect: \(errorMsg)\n\nPlease check your access token and try again."
                        }
                        showSheetError = true
                        isConnecting = false
                        // Keep sheet open so user can fix the issue
                    }
                }
            } catch {
                await MainActor.run {
                    sheetErrorMessage = "Failed to connect: \(error.localizedDescription)\n\nPlease check your access token and try again."
                    showSheetError = true
                    isConnecting = false
                    // Keep sheet open
                }
            }
        }
    }
    
    private func connectToSquare() {
        // This method is now replaced by manual setup
        showManualSetup = true
    }
    
    private func disconnectSquare() {
        if let config = configuration {
            context.delete(config)
            try? context.save()
            self.configuration = nil
            self.locations = []
        }
    }
    
    private func performFullSync() {
        // Check configuration first
        guard configuration != nil else {
            errorMessage = "❌ Not Connected\n\nPlease enter your Square credentials first:\n1. Click 'Enter Square Credentials'\n2. Paste your access token\n3. Click 'Connect'\n\nThen try syncing again."
            showError = true
            return
        }
        
        Task {
            do {
                try await syncManager.syncAllItems()
                errorMessage = "✅ Sync completed successfully!"
                showError = true
            } catch {
                errorMessage = "❌ Sync failed: \(error.localizedDescription)\n\nCheck your credentials and connection."
                showError = true
            }
        }
    }
    
    private func importFromSquare() {
        // Check configuration first
        guard configuration != nil else {
            errorMessage = "❌ Not Connected\n\nPlease enter your Square credentials first:\n1. Click 'Enter Square Credentials'\n2. Paste your access token\n3. Click 'Connect'\n\nThen try importing again."
            showError = true
            return
        }
        
        Task {
            do {
                try await syncManager.importAllFromSquare()
                errorMessage = "✅ Import completed successfully!"
                showError = true
            } catch {
                errorMessage = "❌ Import failed: \(error.localizedDescription)\n\nCheck your credentials and connection."
                showError = true
            }
        }
    }
    
    private func exportToSquare() {
        // Check configuration first
        guard configuration != nil else {
            errorMessage = "❌ Not Connected\n\nPlease enter your Square credentials first:\n1. Click 'Enter Square Credentials'\n2. Paste your access token\n3. Click 'Connect'\n\nThen try exporting again."
            showError = true
            return
        }
        
        Task {
            do {
                try await syncManager.exportAllToSquare()
                errorMessage = "✅ Export completed successfully!"
                showError = true
            } catch {
                errorMessage = "❌ Export failed: \(error.localizedDescription)\n\nCheck your credentials and connection."
                showError = true
            }
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
            selectedLocationId = config.locationId ?? ""
            // CRITICAL: Set configuration in API service for sync operations
            SquareAPIService.shared.setConfiguration(config)
            print("✅ Configuration loaded: Merchant \(config.merchantId ?? "unknown"), Environment: \(config.environment.displayName)")
        } else {
            print("⚠️ No configuration found - please enter Square credentials")
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
        try? context.save()
    }
    
    private func updateEnvironment(_ environment: SquareEnvironment) {
        guard let config = configuration else { return }
        config.environment = environment
        config.updatedAt = Date()
        try? context.save()
    }
    
    private func updateSyncEnabled(_ enabled: Bool) {
        guard let config = configuration else { return }
        config.syncEnabled = enabled
        config.updatedAt = Date()
        try? context.save()
        
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
        try? context.save()
        
        if config.syncEnabled {
            syncManager.startAutoSync(interval: interval)
        }
    }
    
    private func updateSyncDirection(_ direction: SyncDirection) {
        guard let config = configuration else { return }
        config.defaultSyncDirection = direction
        config.updatedAt = Date()
        try? context.save()
    }
    
    private func updateConflictResolution(_ strategy: ConflictResolutionStrategy) {
        guard let config = configuration else { return }
        config.defaultConflictResolution = strategy
        config.updatedAt = Date()
        try? context.save()
    }
}

#Preview {
    NavigationStack {
        SquareInventorySyncSettingsView(context: CoreDataManager.shared.viewContext)
    }
}
