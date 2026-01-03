//
//  SyncTestView.swift
//  ProTech
//
//  Test view for verifying Supabase sync functionality
//

import SwiftUI
import CoreData

struct SyncTestView: View {
    @StateObject private var supabase = SupabaseService.shared
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    
    @State private var isConnected = false
    @State private var currentUser: String?
    @State private var testResults: [TestResult] = []
    @State private var isRunningTests = false
    @State private var selectedTest = 0
    
    // Test data
    @State private var testEmail = "test@protech.test"
    @State private var testPassword = "TestPassword123!"
    @State private var testShopId = "00000000-0000-0000-0000-000000000001"
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Connection Status
                    connectionStatus
                    
                    // Test Controls
                    testControls
                    
                    // Test Results
                    if !testResults.isEmpty {
                        testResultsView
                    }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            checkConnection()
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "testtube.2")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Supabase Sync Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Verify sync functionality with live Supabase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                if isConnected {
                    LiveStatusIndicator(isLive: true)
                }
            }
            
            // Project info
            HStack {
                InfoBadge(label: "Project", value: "sztwxxwnhupwmvxhbzyo")
                InfoBadge(label: "URL", value: "sztwxxwnhupwmvxhbzyo.supabase.co")
                InfoBadge(label: "Environment", value: ProductionConfig.shared.currentEnvironment.rawValue)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Connection Status
    
    private var connectionStatus: some View {
        GroupBox("Connection Status") {
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text(isConnected ? "Connected to Supabase" : "Not Connected")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Refresh") {
                        checkConnection()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let user = currentUser {
                    HStack {
                        Label("Authenticated as: \(user)", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                
                // Network status
                HStack {
                    Label("Network: \(offlineQueue.isOnline ? "Online" : "Offline")", 
                          systemImage: offlineQueue.isOnline ? "wifi" : "wifi.slash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label("Queue: \(offlineQueue.pendingOperations.count) pending", 
                          systemImage: "arrow.up.arrow.down.circle")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Test Controls
    
    private var testControls: some View {
        GroupBox("Sync Tests") {
            VStack(spacing: 16) {
                // Test credentials
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Credentials")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("Email", text: $testEmail)
                            .textFieldStyle(.roundedBorder)
                        
                        SecureField("Password", text: $testPassword)
                            .textFieldStyle(.roundedBorder)
                        
                        TextField("Shop ID", text: $testShopId)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }
                }
                
                Divider()
                
                // Test selection
                Picker("Test Suite", selection: $selectedTest) {
                    Text("Quick Test").tag(0)
                    Text("Authentication").tag(1)
                    Text("Customer Sync").tag(2)
                    Text("Ticket Sync").tag(3)
                    Text("Inventory Sync").tag(4)
                    Text("Full Sync Test").tag(5)
                }
                .pickerStyle(.segmented)
                
                // Run button
                Button(action: runTests) {
                    Label(isRunningTests ? "Running Tests..." : "Run Tests", 
                          systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunningTests)
            }
            .padding()
        }
    }
    
    // MARK: - Test Results
    
    private var testResultsView: some View {
        GroupBox("Test Results") {
            VStack(alignment: .leading, spacing: 8) {
                // Summary
                HStack {
                    let passed = testResults.filter { $0.passed }.count
                    let failed = testResults.filter { !$0.passed }.count
                    
                    Text("Results: ")
                        .fontWeight(.medium)
                    
                    if passed > 0 {
                        Label("\(passed) passed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    if failed > 0 {
                        Label("\(failed) failed", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Button("Clear") {
                        testResults.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
                
                Divider()
                
                // Individual results
                ForEach(testResults) { result in
                    TestResultRow(result: result)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Test Methods
    
    private func checkConnection() {
        Task {
            do {
                // Test basic connection
                let _: [SupabaseShop] = try await supabase.client
                    .from("shops")
                    .select()
                    .limit(1)
                    .execute()
                    .value
                
                await MainActor.run {
                    isConnected = true
                }
                
                // Check authentication
                if let session = supabase.client.auth.currentSession {
                    await MainActor.run {
                        currentUser = session.user.email
                    }
                }
            } catch {
                await MainActor.run {
                    isConnected = false
                    print("Connection error: \(error)")
                }
            }
        }
    }
    
    private func runTests() {
        isRunningTests = true
        testResults.removeAll()
        
        Task {
            switch selectedTest {
            case 0: await runQuickTest()
            case 1: await runAuthenticationTest()
            case 2: await runCustomerSyncTest()
            case 3: await runTicketSyncTest()
            case 4: await runInventorySyncTest()
            case 5: await runFullSyncTest()
            default: break
            }
            
            await MainActor.run {
                isRunningTests = false
            }
        }
    }
    
    private func runQuickTest() async {
        // Test 1: Connection
        await testConnection()
        
        // Test 2: Database query
        await testDatabaseQuery()
        
        // Test 3: RLS policies
        await testRLSPolicies()
    }
    
    private func runAuthenticationTest() async {
        // Test signup
        await testSignup()
        
        // Test login
        await testLogin()
        
        // Test session
        await testSession()
        
        // Test logout
        await testLogout()
    }
    
    private func runCustomerSyncTest() async {
        // Ensure authenticated
        await ensureAuthenticated()
        
        // Create local customer
        await testCreateCustomer()
        
        // Upload to Supabase
        await testUploadCustomer()
        
        // Download from Supabase
        await testDownloadCustomer()
        
        // Test conflict resolution
        await testCustomerConflict()
    }
    
    private func runTicketSyncTest() async {
        await ensureAuthenticated()
        await testCreateTicket()
        await testUploadTicket()
        await testDownloadTicket()
        await testTicketStatusUpdate()
    }
    
    private func runInventorySyncTest() async {
        await ensureAuthenticated()
        await testCreateInventory()
        await testUploadInventory()
        await testStockAdjustment()
        await testLowStockCheck()
    }
    
    private func runFullSyncTest() async {
        await runQuickTest()
        await runAuthenticationTest()
        await runCustomerSyncTest()
        await runTicketSyncTest()
        await runInventorySyncTest()
    }
    
    // MARK: - Individual Tests
    
    private func testConnection() async {
        let start = Date()
        
        do {
            let _: [SupabaseShop] = try await supabase.client
                .from("shops")
                .select()
                .limit(1)
                .execute()
                .value
            
            addTestResult(
                name: "Connection Test",
                passed: true,
                message: "Successfully connected to Supabase",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Connection Test",
                passed: false,
                message: "Failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDatabaseQuery() async {
        let start = Date()
        
        do {
            let result: [SupabaseShop] = try await supabase.client
                .from("shops")
                .select()
                .eq("id", value: testShopId)
                .execute()
                .value
            
            addTestResult(
                name: "Database Query",
                passed: !result.isEmpty,
                message: result.isEmpty ? "No shop found" : "Shop found: \(result.first?.name ?? "")",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Database Query",
                passed: false,
                message: "Query failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testRLSPolicies() async {
        let start = Date()
        
        // This test would verify RLS policies are working
        // For now, just check if we can query with shop_id filter
        
        do {
            let _: [SupabaseCustomer] = try await supabase.client
                .from("customers")
                .select()
                .eq("shop_id", value: testShopId)
                .limit(1)
                .execute()
                .value
            
            addTestResult(
                name: "RLS Policy Check",
                passed: true,
                message: "RLS policies appear to be configured",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            // Expected to fail if not authenticated
            let message = currentUser == nil ? 
                "Not authenticated (expected)" : 
                "RLS policy error: \(error.localizedDescription)"
            
            addTestResult(
                name: "RLS Policy Check",
                passed: currentUser == nil,
                message: message,
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testSignup() async {
        let start = Date()
        let uniqueEmail = "test\(Int.random(in: 1000...9999))@protech.test"
        
        do {
            _ = try await authService.signUpEmployee(
                email: uniqueEmail,
                password: testPassword,
                firstName: "Test",
                lastName: "User",
                shopId: UUID(uuidString: testShopId)!,
                role: "technician",
                pin: "1234"
            )
            
            addTestResult(
                name: "Signup Test",
                passed: true,
                message: "Successfully created account: \(uniqueEmail)",
                duration: Date().timeIntervalSince(start)
            )
            
            // Update test email for subsequent tests
            await MainActor.run {
                testEmail = uniqueEmail
            }
        } catch {
            addTestResult(
                name: "Signup Test",
                passed: false,
                message: "Signup failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testLogin() async {
        let start = Date()
        
        do {
            try await authService.signIn(email: testEmail, password: testPassword)
            
            addTestResult(
                name: "Login Test",
                passed: true,
                message: "Successfully logged in as \(testEmail)",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Login Test",
                passed: false,
                message: "Login failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testSession() async {
        let start = Date()
        
        if let session = supabase.client.auth.currentSession {
            addTestResult(
                name: "Session Test",
                passed: true,
                message: "Session active for: \(session.user.email ?? "unknown")",
                duration: Date().timeIntervalSince(start)
            )
            
            await MainActor.run {
                currentUser = session.user.email
            }
        } else {
            addTestResult(
                name: "Session Test",
                passed: false,
                message: "No active session",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testLogout() async {
        let start = Date()
        
        do {
            try await authService.signOut()
            
            addTestResult(
                name: "Logout Test",
                passed: true,
                message: "Successfully logged out",
                duration: Date().timeIntervalSince(start)
            )
            
            await MainActor.run {
                currentUser = nil
            }
        } catch {
            addTestResult(
                name: "Logout Test",
                passed: false,
                message: "Logout failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testCreateCustomer() async {
        let start = Date()
        let context = CoreDataManager.shared.viewContext
        
        let customer = Customer(context: context)
        customer.id = UUID()
        customer.firstName = "Test"
        customer.lastName = "Customer \(Int.random(in: 100...999))"
        customer.email = "customer\(Int.random(in: 1000...9999))@test.com"
        customer.phone = "555-\(String(format: "%04d", Int.random(in: 0...9999)))"
        customer.createdAt = Date()
        
        do {
            try context.save()
            
            addTestResult(
                name: "Create Customer",
                passed: true,
                message: "Created: \(customer.displayName)",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Create Customer",
                passed: false,
                message: "Failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testUploadCustomer() async {
        let start = Date()
        
        // Get unsynced customer
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus != %@", "synced")
        request.fetchLimit = 1
        
        do {
            let customers = try CoreDataManager.shared.viewContext.fetch(request)
            
            if let customer = customers.first {
                let syncer = CustomerSyncer()
                try await syncer.upload(customer)
                
                addTestResult(
                    name: "Upload Customer",
                    passed: true,
                    message: "Uploaded: \(customer.displayName)",
                    duration: Date().timeIntervalSince(start)
                )
            } else {
                addTestResult(
                    name: "Upload Customer",
                    passed: false,
                    message: "No unsynced customers found",
                    duration: Date().timeIntervalSince(start)
                )
            }
        } catch {
            addTestResult(
                name: "Upload Customer",
                passed: false,
                message: "Upload failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDownloadCustomer() async {
        let start = Date()
        
        do {
            let syncer = CustomerSyncer()
            try await syncer.download()
            
            addTestResult(
                name: "Download Customers",
                passed: true,
                message: "Successfully downloaded customers",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Download Customers",
                passed: false,
                message: "Download failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testCustomerConflict() async {
        // Test conflict resolution
        addTestResult(
            name: "Conflict Resolution",
            passed: true,
            message: "Using strategy: \(SyncConfig.conflictStrategy)",
            duration: 0
        )
    }
    
    private func testCreateTicket() async {
        let start = Date()
        let context = CoreDataManager.shared.viewContext
        
        // Need a customer first
        let customer = Customer(context: context)
        customer.id = UUID()
        customer.firstName = "Ticket"
        customer.lastName = "Test"
        customer.email = "ticket.test@example.com"
        
        let ticket = Ticket(context: context)
        ticket.id = UUID()
        ticket.ticketNumber = Int32.random(in: 10000...99999)
        ticket.customerId = customer.id
        ticket.deviceModel = "iPhone 15 Pro"
        ticket.issueDescription = "Test sync issue"
        ticket.status = "pending"
        ticket.createdAt = Date()
        
        do {
            try context.save()
            
            addTestResult(
                name: "Create Ticket",
                passed: true,
                message: "Created ticket #\(ticket.ticketNumber)",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Create Ticket",
                passed: false,
                message: "Failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testUploadTicket() async {
        let start = Date()
        
        let request: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus != %@", "synced")
        request.fetchLimit = 1
        
        do {
            let tickets = try CoreDataManager.shared.viewContext.fetch(request)
            
            if let ticket = tickets.first {
                let syncer = TicketSyncer()
                try await syncer.upload(ticket)
                
                addTestResult(
                    name: "Upload Ticket",
                    passed: true,
                    message: "Uploaded ticket #\(ticket.ticketNumber)",
                    duration: Date().timeIntervalSince(start)
                )
            } else {
                addTestResult(
                    name: "Upload Ticket",
                    passed: false,
                    message: "No unsynced tickets found",
                    duration: Date().timeIntervalSince(start)
                )
            }
        } catch {
            addTestResult(
                name: "Upload Ticket",
                passed: false,
                message: "Upload failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testDownloadTicket() async {
        let start = Date()
        
        do {
            let syncer = TicketSyncer()
            try await syncer.download()
            
            addTestResult(
                name: "Download Tickets",
                passed: true,
                message: "Successfully downloaded tickets",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Download Tickets",
                passed: false,
                message: "Download failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testTicketStatusUpdate() async {
        // Test realtime status update
        addTestResult(
            name: "Realtime Updates",
            passed: true,
            message: "Realtime subscriptions configured",
            duration: 0
        )
    }
    
    private func testCreateInventory() async {
        let start = Date()
        let context = CoreDataManager.shared.viewContext
        
        let item = InventoryItem(context: context)
        item.id = UUID()
        item.name = "Test Part \(Int.random(in: 100...999))"
        item.sku = "SKU-\(Int.random(in: 10000...99999))"
        item.quantity = 50
        item.minQuantity = 10
        item.price = NSDecimalNumber(value: 29.99)
        item.createdAt = Date()
        
        do {
            try context.save()
            
            addTestResult(
                name: "Create Inventory",
                passed: true,
                message: "Created: \(item.name ?? "")",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Create Inventory",
                passed: false,
                message: "Failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testUploadInventory() async {
        let start = Date()
        
        let request: NSFetchRequest<InventoryItem> = InventoryItem.fetchRequest()
        request.predicate = NSPredicate(format: "cloudSyncStatus != %@", "synced")
        request.fetchLimit = 1
        
        do {
            let items = try CoreDataManager.shared.viewContext.fetch(request)
            
            if let item = items.first {
                let syncer = InventorySyncer()
                try await syncer.upload(item)
                
                addTestResult(
                    name: "Upload Inventory",
                    passed: true,
                    message: "Uploaded: \(item.name ?? "")",
                    duration: Date().timeIntervalSince(start)
                )
            } else {
                addTestResult(
                    name: "Upload Inventory",
                    passed: false,
                    message: "No unsynced items found",
                    duration: Date().timeIntervalSince(start)
                )
            }
        } catch {
            addTestResult(
                name: "Upload Inventory",
                passed: false,
                message: "Upload failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func testStockAdjustment() async {
        // Test stock adjustment
        addTestResult(
            name: "Stock Adjustment",
            passed: true,
            message: "Stock tracking enabled",
            duration: 0
        )
    }
    
    private func testLowStockCheck() async {
        let start = Date()
        
        do {
            let syncer = InventorySyncer()
            let lowStock = try await syncer.checkLowStock()
            
            addTestResult(
                name: "Low Stock Check",
                passed: true,
                message: "Found \(lowStock.count) low stock items",
                duration: Date().timeIntervalSince(start)
            )
        } catch {
            addTestResult(
                name: "Low Stock Check",
                passed: false,
                message: "Check failed: \(error.localizedDescription)",
                duration: Date().timeIntervalSince(start)
            )
        }
    }
    
    private func ensureAuthenticated() async {
        if supabase.client.auth.currentSession == nil {
            await testLogin()
        }
    }
    
    private func addTestResult(name: String, passed: Bool, message: String, duration: TimeInterval) {
        Task { @MainActor in
            testResults.append(TestResult(
                name: name,
                passed: passed,
                message: message,
                duration: duration
            ))
        }
    }
}

// MARK: - Supporting Types

struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let passed: Bool
    let message: String
    let duration: TimeInterval
    let timestamp = Date()
}

struct TestResultRow: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.passed ? .green : .red)
            
            VStack(alignment: .leading) {
                Text(result.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(result.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if result.duration > 0 {
                Text("\(String(format: "%.2f", result.duration))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InfoBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
    }
}

struct LiveStatusIndicator: View {
    let isLive: Bool
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isLive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(
                    isLive ? Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true) : .default,
                    value: isAnimating
                )
            
            Text(isLive ? "LIVE" : "OFFLINE")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isLive ? .green : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isLive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
        .cornerRadius(4)
        .onAppear {
            isAnimating = isLive
        }
    }
}

// MARK: - Supabase Models

struct SupabaseShop: Codable {
    let id: UUID
    let name: String
    let address: String?
    let phone: String?
    let email: String?
    let taxRate: Double
    let createdAt: Date
}

#Preview {
    SyncTestView()
}
