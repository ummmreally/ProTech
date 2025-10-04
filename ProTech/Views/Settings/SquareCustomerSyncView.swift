//
//  SquareCustomerSyncView.swift
//  ProTech
//
//  UI for syncing customers between ProTech and Square
//

import SwiftUI
import CoreData

struct SquareCustomerSyncView: View {
    @StateObject private var syncManager: SquareCustomerSyncManager
    @State private var showingConfirmation = false
    @State private var syncAction: SyncAction = .importFromSquare
    @State private var showingSyncStats = false
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        self.context = context
        _syncManager = StateObject(wrappedValue: SquareCustomerSyncManager(context: context))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Sync Status
                    statusSection
                    
                    // Statistics
                    statisticsSection
                    
                    // Sync Actions
                    actionsSection
                    
                    // Last Sync Info
                    if let lastSync = syncManager.lastSyncDate {
                        lastSyncSection(lastSync)
                    }
                }
                .padding()
            }
            .navigationTitle("Customer Sync")
            .alert("Confirm Sync", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button(syncAction.confirmButtonTitle, role: .destructive) {
                    performSync()
                }
            } message: {
                Text(syncAction.confirmationMessage)
            }
            .sheet(isPresented: $showingSyncStats) {
                syncStatsSheet
            }
            
            // Prominent loading overlay when syncing
            if syncManager.syncStatus == .syncing {
                SyncProgressOverlay(
                    progress: syncManager.syncProgress,
                    currentOperation: syncManager.currentOperation,
                    status: syncManager.syncStatus
                )
                .transition(.opacity)
                .animation(.easeInOut, value: syncManager.syncStatus)
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.badge.gearshape")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Square Customer Sync")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Keep your customers in sync between ProTech and Square")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    private var statusSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("Status:")
                        .fontWeight(.medium)
                    Spacer()
                    statusBadge
                }
                
                if syncManager.syncStatus == .syncing {
                    VStack(alignment: .leading, spacing: 8) {
                        if let operation = syncManager.currentOperation {
                            Text(operation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: syncManager.syncProgress)
                            .progressViewStyle(.linear)
                        
                        Text("\(Int(syncManager.syncProgress * 100))% Complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if case .error(let message) = syncManager.syncStatus {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        } label: {
            Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            switch syncManager.syncStatus {
            case .idle:
                Image(systemName: "circle.fill")
                    .foregroundColor(.gray)
                Text("Idle")
                    .foregroundColor(.secondary)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.8)
                Text("Syncing...")
                    .foregroundColor(.blue)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Completed")
                    .foregroundColor(.green)
            case .error:
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text("Error")
                    .foregroundColor(.red)
            }
        }
        .font(.subheadline)
    }
    
    private var statisticsSection: some View {
        GroupBox {
            VStack(spacing: 12) {
                statRow(label: "Local Customers", value: "\(syncManager.getLocalCustomersCount())", icon: "person.fill", color: .blue)
                statRow(label: "Synced with Square", value: "\(syncManager.getSyncedCustomersCount())", icon: "checkmark.circle.fill", color: .green)
                statRow(label: "Not Synced", value: "\(syncManager.getUnsyncedCustomersCount())", icon: "exclamationmark.circle.fill", color: .orange)
            }
        } label: {
            Label("Statistics", systemImage: "chart.bar.fill")
        }
    }
    
    private func statRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Text("Sync Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Import from Square
            syncButton(
                title: "Import from Square",
                subtitle: "Pull customers from Square to ProTech",
                icon: "square.and.arrow.down.fill",
                color: .blue,
                action: .importFromSquare
            )
            
            // Export to Square
            syncButton(
                title: "Export to Square",
                subtitle: "Push ProTech customers to Square",
                icon: "square.and.arrow.up.fill",
                color: .purple,
                action: .exportToSquare
            )
            
            // Bidirectional Sync
            syncButton(
                title: "Sync All",
                subtitle: "Two-way sync between both systems",
                icon: "arrow.triangle.2.circlepath",
                color: .green,
                action: .syncAll
            )
        }
        .padding(.top)
    }
    
    private func syncButton(title: String, subtitle: String, icon: String, color: Color, action: SyncAction) -> some View {
        Button {
            syncAction = action
            showingConfirmation = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
        }
        .disabled(syncManager.syncStatus == .syncing)
    }
    
    private func lastSyncSection(_ date: Date) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.secondary)
                Text("Last Sync:")
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDate(date))
                    .fontWeight(.medium)
            }
            .font(.subheadline)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(10)
            
            Button {
                showingSyncStats = true
            } label: {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("View Sync History")
                }
                .font(.subheadline)
            }
        }
    }
    
    private var syncStatsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Last Sync Results")
                    .font(.title2)
                    .fontWeight(.bold)
                
                GroupBox {
                    VStack(spacing: 12) {
                        statRow(label: "Imported", value: "\(syncManager.syncStats.imported)", icon: "arrow.down.circle.fill", color: .blue)
                        statRow(label: "Exported", value: "\(syncManager.syncStats.exported)", icon: "arrow.up.circle.fill", color: .purple)
                        statRow(label: "Updated", value: "\(syncManager.syncStats.updated)", icon: "arrow.triangle.2.circlepath", color: .green)
                        statRow(label: "Failed", value: "\(syncManager.syncStats.failed)", icon: "xmark.circle.fill", color: .red)
                        
                        Divider()
                        
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text("\(syncManager.syncStats.total)")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingSyncStats = false
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func performSync() {
        Task {
            do {
                switch syncAction {
                case .importFromSquare:
                    try await syncManager.importAllFromSquare()
                case .exportToSquare:
                    try await syncManager.exportAllToSquare()
                case .syncAll:
                    try await syncManager.syncAll()
                }
            } catch {
                print("Sync error: \(error)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Types

enum SyncAction {
    case importFromSquare
    case exportToSquare
    case syncAll
    
    var confirmButtonTitle: String {
        switch self {
        case .importFromSquare: return "Import"
        case .exportToSquare: return "Export"
        case .syncAll: return "Sync All"
        }
    }
    
    var confirmationMessage: String {
        switch self {
        case .importFromSquare:
            return "This will import customers from Square to ProTech. Existing customers will be updated."
        case .exportToSquare:
            return "This will export ProTech customers to Square. This may create new customers in Square."
        case .syncAll:
            return "This will perform a bidirectional sync between ProTech and Square. Both systems will be updated."
        }
    }
}

#Preview {
    NavigationView {
        SquareCustomerSyncView()
    }
}
