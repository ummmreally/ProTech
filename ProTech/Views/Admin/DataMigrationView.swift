//
//  DataMigrationView.swift
//  ProTech
//
//  UI for managing Core Data to Supabase migration
//

import SwiftUI

struct DataMigrationView: View {
    @StateObject private var migrationService = DataMigrationService.shared
    @StateObject private var supabase = SupabaseService.shared
    @State private var showConfirmation = false
    @State private var showReport = false
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            Divider()
            
            // Content
            TabView(selection: $selectedTab) {
                migrationTab
                    .tabItem {
                        Label("Migration", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .tag(0)
                
                optionsTab
                    .tabItem {
                        Label("Options", systemImage: "gearshape")
                    }
                    .tag(1)
                
                statusTab
                    .tabItem {
                        Label("Status", systemImage: "chart.bar")
                    }
                    .tag(2)
                
                errorsTab
                    .tabItem {
                        Label("Errors", systemImage: "exclamationmark.triangle")
                    }
                    .tag(3)
            }
            .padding()
        }
        .frame(width: 800, height: 600)
        .sheet(isPresented: $showReport) {
            MigrationReportView()
        }
        .alert("Confirm Migration", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Start Migration", role: .destructive) {
                Task {
                    await migrationService.startMigration()
                }
            }
        } message: {
            Text("This will migrate all selected data to Supabase. This process cannot be undone automatically. Make sure you have a backup.")
        }
    }
    
    // MARK: - Header
    
    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Data Migration Tool")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Migrate Core Data to Supabase")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Connection status
                VStack(alignment: .trailing) {
                    HStack {
                        Circle()
                            .fill(supabase.currentShopId != nil ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(supabase.currentShopId != nil ? "Connected" : "Disconnected")
                            .font(.caption)
                    }
                    
                    if let shopId = supabase.currentShopId {
                        Text("Shop: \(shopId)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            // Progress bar
            if migrationService.isMigrating {
                VStack(spacing: 4) {
                    ProgressView(value: migrationService.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text(migrationService.currentPhase.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(migrationService.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Migration Tab
    
    private var migrationTab: some View {
        VStack(spacing: 20) {
            // Pre-migration checklist
            GroupBox("Pre-Migration Checklist") {
                VStack(alignment: .leading, spacing: 12) {
                    ChecklistItem(
                        title: "Supabase Connected",
                        isCompleted: supabase.currentShopId != nil
                    )
                    
                    ChecklistItem(
                        title: "Backup Created",
                        isCompleted: migrationService.options.createBackup
                    )
                    
                    ChecklistItem(
                        title: "Data Validated",
                        isCompleted: migrationService.statistics.totalRecords > 0
                    )
                    
                    ChecklistItem(
                        title: "Migration Options Configured",
                        isCompleted: true
                    )
                }
                .padding()
            }
            
            // Migration summary
            GroupBox("Migration Summary") {
                HStack(spacing: 40) {
                    MigrationStatCard(
                        label: "Customers",
                        value: "\(migrationService.statistics.totalCustomers)",
                        color: .blue
                    )
                    
                    MigrationStatCard(
                        label: "Tickets",
                        value: "\(migrationService.statistics.totalTickets)",
                        color: .green
                    )
                    
                    MigrationStatCard(
                        label: "Inventory",
                        value: "\(migrationService.statistics.totalInventory)",
                        color: .orange
                    )
                    
                    MigrationStatCard(
                        label: "Employees",
                        value: "\(migrationService.statistics.totalEmployees)",
                        color: .purple
                    )
                }
                .padding()
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Validate Data") {
                    Task {
                        await validateData()
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("View Last Report") {
                    showReport = true
                }
                .buttonStyle(.bordered)
                .disabled(!hasLastReport())
                
                Button("Start Migration") {
                    showConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(migrationService.isMigrating || supabase.currentShopId == nil)
            }
        }
        .padding()
    }
    
    // MARK: - Options Tab
    
    private var optionsTab: some View {
        Form {
            Section("Data to Migrate") {
                Toggle("Customers", isOn: $migrationService.options.migrateCustomers)
                Toggle("Tickets", isOn: $migrationService.options.migrateTickets)
                Toggle("Inventory", isOn: $migrationService.options.migrateInventory)
                Toggle("Employees", isOn: $migrationService.options.migrateEmployees)
            }
            
            Section("Migration Options") {
                Toggle("Skip already synced records", isOn: $migrationService.options.skipExisting)
                    .help("Skip records that have already been synced to Supabase")
                
                Toggle("Continue on errors", isOn: $migrationService.options.continueOnError)
                    .help("Continue migration even if some records fail")
                
                Toggle("Use batch operations", isOn: $migrationService.options.useBatchOperations)
                    .help("Upload multiple records at once for better performance")
                
                Toggle("Create backup before migration", isOn: $migrationService.options.createBackup)
                    .help("Create a backup of Core Data before starting migration")
            }
            
            Section("Advanced") {
                Button("Reset Sync Status") {
                    resetSyncStatus()
                }
                .buttonStyle(.bordered)
                .help("Mark all records as unsynced")
                
                Button("Rollback Migration") {
                    Task {
                        await migrationService.rollbackMigration()
                    }
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .help("Rollback the migration and mark all records as unsynced")
            }
        }
        .padding()
    }
    
    // MARK: - Status Tab
    
    private var statusTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall progress
                GroupBox("Overall Progress") {
                    VStack(spacing: 16) {
                        CircularProgressView(
                            progress: overallProgress,
                            label: "\(Int(overallProgress * 100))%",
                            color: progressColor
                        )
                        
                        Text("\(migrationService.statistics.totalMigrated) of \(migrationService.statistics.totalRecords) records migrated")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Entity progress
                GroupBox("Entity Progress") {
                    VStack(spacing: 12) {
                        EntityProgressRow(
                            entity: "Customers",
                            migrated: migrationService.statistics.migratedCustomers,
                            total: migrationService.statistics.totalCustomers,
                            failed: migrationService.statistics.failedCustomers
                        )
                        
                        EntityProgressRow(
                            entity: "Tickets",
                            migrated: migrationService.statistics.migratedTickets,
                            total: migrationService.statistics.totalTickets,
                            failed: migrationService.statistics.failedTickets
                        )
                        
                        EntityProgressRow(
                            entity: "Inventory",
                            migrated: migrationService.statistics.migratedInventory,
                            total: migrationService.statistics.totalInventory,
                            failed: migrationService.statistics.failedInventory
                        )
                        
                        EntityProgressRow(
                            entity: "Employees",
                            migrated: migrationService.statistics.migratedEmployees,
                            total: migrationService.statistics.totalEmployees,
                            failed: migrationService.statistics.failedEmployees
                        )
                    }
                    .padding()
                }
                
                // Phase status
                GroupBox("Migration Phase") {
                    HStack {
                        Image(systemName: phaseIcon)
                            .font(.system(size: 24))
                            .foregroundColor(phaseColor)
                        
                        VStack(alignment: .leading) {
                            Text(migrationService.currentPhase.description)
                                .font(.headline)
                            
                            Text(migrationService.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
    }
    
    // MARK: - Errors Tab
    
    private var errorsTab: some View {
        VStack {
            if migrationService.errors.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("No Errors")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Migration completed without errors")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(migrationService.errors, id: \.timestamp) { error in
                    ErrorRow(error: error)
                }
                
                HStack {
                    Text("\(migrationService.errors.count) errors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Export Errors") {
                        exportErrors()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear") {
                        migrationService.errors.removeAll()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var overallProgress: Double {
        guard migrationService.statistics.totalRecords > 0 else { return 0 }
        return Double(migrationService.statistics.totalMigrated) / Double(migrationService.statistics.totalRecords)
    }
    
    private var progressColor: Color {
        switch migrationService.currentPhase {
        case .completed: return .green
        case .failed: return .red
        default: return .blue
        }
    }
    
    private var phaseIcon: String {
        switch migrationService.currentPhase {
        case .idle: return "clock"
        case .preparing: return "gear"
        case .validating: return "checkmark.shield"
        case .migratingEmployees: return "person.3"
        case .migratingCustomers: return "person.2"
        case .migratingInventory: return "shippingbox"
        case .migratingTickets: return "ticket"
        case .verifying: return "magnifyingglass"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private var phaseColor: Color {
        switch migrationService.currentPhase {
        case .completed: return .green
        case .failed: return .red
        default: return .blue
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateData() async {
        // Run validation
        // This would be implemented in the migration service
    }
    
    private func resetSyncStatus() {
        // Reset sync status for all records
    }
    
    private func hasLastReport() -> Bool {
        UserDefaults.standard.data(forKey: "LastMigrationReport") != nil
    }
    
    private func exportErrors() {
        // Export errors to file
        let errors = migrationService.errors.map { error in
            "\(error.timestamp): \(error.phase) - \(error.message)"
        }.joined(separator: "\n")
        
        // Save to file
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.text]
        savePanel.nameFieldStringValue = "migration_errors.txt"
        
        if savePanel.runModal() == .OK,
           let url = savePanel.url {
            try? errors.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Supporting Views

struct ChecklistItem: View {
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
            
            Text(title)
                .foregroundColor(isCompleted ? .primary : .secondary)
            
            Spacer()
        }
    }
}

private struct MigrationStatCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EntityProgressRow: View {
    let entity: String
    let migrated: Int
    let total: Int
    let failed: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(migrated) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(entity)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(migrated)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if failed > 0 {
                    Text("(\(failed) failed)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(failed > 0 ? .orange : .blue)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let label: String
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            Text(label)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(width: 150, height: 150)
    }
}

struct ErrorRow: View {
    let error: MigrationError
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text(error.message)
                    .font(.subheadline)
                
                HStack {
                    Text(error.phase.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(error.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MigrationReportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            Text("Migration Report")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Report content would go here
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 600, height: 400)
    }
}

#Preview {
    DataMigrationView()
}
