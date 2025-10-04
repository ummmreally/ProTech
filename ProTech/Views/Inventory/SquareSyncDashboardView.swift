//
//  SquareSyncDashboardView.swift
//  ProTech
//
//  Dashboard for Square inventory synchronization
//

import SwiftUI
import CoreData
import Charts

struct SquareSyncDashboardView: View {
    @StateObject private var syncManager: SquareInventorySyncManager
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SyncLog.timestamp, ascending: false)],
        animation: .default
    )
    private var syncLogs: FetchedResults<SyncLog>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SquareSyncMapping.lastSyncedAt, ascending: false)],
        animation: .default
    )
    private var mappings: FetchedResults<SquareSyncMapping>
    
    @State private var showingImportSheet = false
    @State private var showingExportSheet = false
    @State private var showingConflicts = false
    @State private var conflicts: [SyncConflict] = []
    @State private var statistics: SyncStatistics?
    
    init(context: NSManagedObjectContext = CoreDataManager.shared.viewContext) {
        _syncManager = StateObject(wrappedValue: SquareInventorySyncManager(context: context))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    statusCard
                    
                    // Statistics Cards
                    statisticsCards
                    
                    // Sync Progress
                    if syncManager.syncStatus == .syncing {
                        syncProgressCard
                    }
                    
                    // Quick Actions
                    quickActionsCard
                    
                    // Sync History
                    syncHistoryCard
                }
                .padding()
            }
            .navigationTitle("Square Sync")
            
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task {
                            await performFullSync()
                        }
                    } label: {
                        Label("Sync All Items", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button {
                        showingImportSheet = true
                    } label: {
                        Label("Import from Square", systemImage: "arrow.down.circle")
                    }
                    
                    Button {
                        showingExportSheet = true
                    } label: {
                        Label("Export to Square", systemImage: "arrow.up.circle")
                    }
                    
                    Divider()
                    
                    Button {
                        Task {
                            await checkConflicts()
                        }
                    } label: {
                        Label("Check for Conflicts", systemImage: "exclamationmark.triangle")
                    }
                } label: {
                    Label("Actions", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportFromSquareSheet(syncManager: syncManager)
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportToSquareSheet(syncManager: syncManager)
        }
        .sheet(isPresented: $showingConflicts) {
            ConflictResolutionSheet(conflicts: conflicts, syncManager: syncManager)
        }
        .task {
            loadStatistics()
        }
    }
    
    // MARK: - View Components
    
    private var statusCard: some View {
        GroupBox {
            HStack(spacing: 16) {
                // Status Icon
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Image(systemName: statusIcon)
                        .font(.title2)
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(syncManager.syncStatus.displayName)
                        .font(.headline)
                    
                    if let operation = syncManager.currentOperation {
                        Text(operation)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let lastSync = syncManager.lastSyncDate {
                        Text("Last synced: \(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Never synced")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if syncManager.syncStatus == .syncing {
                    ProgressView()
                }
            }
            .padding()
        }
    }
    
    private var statisticsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            SquareSyncStatCard(
                title: "Total Items",
                value: "\(statistics?.totalItems ?? 0)",
                icon: "cube.box",
                color: .blue
            )
            
            SquareSyncStatCard(
                title: "Synced",
                value: "\(statistics?.syncedItems ?? 0)",
                icon: "checkmark.circle",
                color: .green
            )
            
            SquareSyncStatCard(
                title: "Pending",
                value: "\(statistics?.pendingItems ?? 0)",
                icon: "clock",
                color: .orange
            )
            
            SquareSyncStatCard(
                title: "Failed",
                value: "\(statistics?.failedItems ?? 0)",
                icon: "exclamationmark.triangle",
                color: .red
            )
        }
    }
    
    private var syncProgressCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Sync Progress")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(syncManager.syncProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: syncManager.syncProgress)
                    .progressViewStyle(.linear)
            }
            .padding()
        }
    }
    
    private var quickActionsCard: some View {
        GroupBox {
            VStack(spacing: 12) {
                HStack {
                    Text("Quick Actions")
                        .font(.headline)
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    SquareSyncActionButton(
                        title: "Sync All",
                        icon: "arrow.triangle.2.circlepath",
                        color: .blue
                    ) {
                        Task {
                            await performFullSync()
                        }
                    }
                    
                    SquareSyncActionButton(
                        title: "Import",
                        icon: "arrow.down.circle",
                        color: .green
                    ) {
                        showingImportSheet = true
                    }
                    
                    SquareSyncActionButton(
                        title: "Export",
                        icon: "arrow.up.circle",
                        color: .purple
                    ) {
                        showingExportSheet = true
                    }
                    
                    SquareSyncActionButton(
                        title: "Conflicts",
                        icon: "exclamationmark.triangle",
                        color: .orange
                    ) {
                        Task {
                            await checkConflicts()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private var syncHistoryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent Activity")
                        .font(.headline)
                    Spacer()
                    if !syncLogs.isEmpty {
                        Text("\(syncLogs.count) events")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if syncLogs.isEmpty {
                    Text("No sync activity yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(syncLogs.prefix(10)) { log in
                        SyncLogRow(log: log)
                        if log.id != syncLogs.prefix(10).last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .idle: return .gray
        case .syncing: return .blue
        case .error: return .red
        case .completed: return .green
        }
    }
    
    private var statusIcon: String {
        switch syncManager.syncStatus {
        case .idle: return "pause.circle"
        case .syncing: return "arrow.triangle.2.circlepath"
        case .error: return "exclamationmark.triangle"
        case .completed: return "checkmark.circle"
        }
    }
    
    // MARK: - Actions
    
    private func performFullSync() async {
        do {
            try await syncManager.syncAllItems()
            loadStatistics()
        } catch {
            print("Sync failed: \(error)")
        }
    }
    
    private func checkConflicts() async {
        do {
            conflicts = try await syncManager.detectConflicts()
            if !conflicts.isEmpty {
                showingConflicts = true
            }
        } catch {
            print("Failed to check conflicts: \(error)")
        }
    }
    
    private func loadStatistics() {
        statistics = syncManager.getSyncStatistics()
    }
}

// MARK: - Supporting Views

struct SquareSyncStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(8)
        }
    }
}

struct SquareSyncActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct SyncLogRow: View {
    let log: SyncLog
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.operation.iconName)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.operation.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let details = log.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if let timestamp = log.timestamp {
                    Text(timestamp.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if log.syncDuration > 0 {
                    Text(String(format: "%.1fs", log.syncDuration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch log.status {
        case .synced: return .green
        case .pending: return .orange
        case .failed: return .red
        case .conflict: return .yellow
        case .disabled: return .gray
        }
    }
}

// MARK: - Import Sheet

struct ImportFromSquareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncManager: SquareInventorySyncManager
    @State private var isImporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Import from Square")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This will import all items from your Square catalog into ProTech. Existing items with matching SKUs will be linked.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if isImporting {
                    SyncProgressBar(
                        progress: syncManager.syncProgress,
                        currentOperation: syncManager.currentOperation
                    )
                    .padding()
                }
                
                Spacer()
                
                Button {
                    performImport()
                } label: {
                    Text(isImporting ? "Importing..." : "Start Import")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
                .padding()
            }
            .padding()
            .navigationTitle("Import")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isImporting)
                }
            }
        }
    }
    
    private func performImport() {
        isImporting = true
        
        Task {
            do {
                try await syncManager.importAllFromSquare()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Import failed: \(error)")
                isImporting = false
            }
        }
    }
}

// MARK: - Export Sheet

struct ExportToSquareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncManager: SquareInventorySyncManager
    @State private var isExporting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Export to Square")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This will export all ProTech items to your Square catalog. Items already linked will be skipped.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if isExporting {
                    SyncProgressBar(
                        progress: syncManager.syncProgress,
                        currentOperation: syncManager.currentOperation
                    )
                    .padding()
                }
                
                Spacer()
                
                Button {
                    performExport()
                } label: {
                    Text(isExporting ? "Exporting..." : "Start Export")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
                .padding()
            }
            .padding()
            .navigationTitle("Export")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isExporting)
                }
            }
        }
    }
    
    private func performExport() {
        isExporting = true
        
        Task {
            do {
                try await syncManager.exportAllToSquare()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Export failed: \(error)")
                isExporting = false
            }
        }
    }
}

// MARK: - Conflict Resolution Sheet

struct ConflictResolutionSheet: View {
    @Environment(\.dismiss) private var dismiss
    let conflicts: [SyncConflict]
    @ObservedObject var syncManager: SquareInventorySyncManager
    @State private var selectedStrategy: ConflictResolutionStrategy = .mostRecent
    @State private var isResolving = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("\(conflicts.count) Conflict\(conflicts.count == 1 ? "" : "s") Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Choose how to resolve conflicts between ProTech and Square data")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Picker("Resolution Strategy", selection: $selectedStrategy) {
                    ForEach([ConflictResolutionStrategy.mostRecent, .squareWins, .proTechWins, .manual], id: \.self) { strategy in
                        Text(strategy.displayName).tag(strategy)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                Text(selectedStrategy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                List(conflicts, id: \.proTechItem.id) { conflict in
                    ConflictRow(conflict: conflict)
                }
                
                Button {
                    resolveConflicts()
                } label: {
                    Text(isResolving ? "Resolving..." : "Resolve All")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isResolving || selectedStrategy == .manual)
                .padding()
            }
            .navigationTitle("Conflicts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func resolveConflicts() {
        isResolving = true
        
        Task {
            for conflict in conflicts {
                do {
                    try await syncManager.resolveConflict(conflict, strategy: selectedStrategy)
                } catch {
                    print("Failed to resolve conflict: \(error)")
                }
            }
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct ConflictRow: View {
    let conflict: SyncConflict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(conflict.proTechItem.name ?? "Unnamed Item")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ProTech")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(conflict.proTechLastModified.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(.orange)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Square")
                        .font(.caption)
                        .foregroundColor(.purple)
                    Text(conflict.squareLastModified.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if !conflict.conflictingFields.isEmpty {
                Text("Conflicts: \(conflict.conflictingFields.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SquareSyncDashboardView(context: CoreDataManager.shared.viewContext)
    }
}
