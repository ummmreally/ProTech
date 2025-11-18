//
//  SyncStatusView.swift
//  ProTech
//
//  Sync status indicators and controls for Supabase sync
//

import SwiftUI

// MARK: - Sync Status Badge

struct SyncStatusBadge: View {
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    @StateObject private var customerSyncer = CustomerSyncer()
    @StateObject private var ticketSyncer = TicketSyncer()
    @StateObject private var inventorySyncer = InventorySyncer()
    
    var body: some View {
        HStack(spacing: 6) {
            // Network status icon
            Image(systemName: offlineQueue.isOnline ? "wifi" : "wifi.slash")
                .foregroundColor(offlineQueue.isOnline ? .green : .orange)
                .font(.system(size: 12))
            
            // Sync status
            if offlineQueue.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 14, height: 14)
            } else if !offlineQueue.pendingOperations.isEmpty {
                Label("\(offlineQueue.pendingOperations.count)", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .help(statusText)
    }
    
    private var statusText: String {
        if !offlineQueue.isOnline {
            return "Offline - \(offlineQueue.pendingOperations.count) operations pending"
        } else if offlineQueue.isSyncing {
            return "Syncing..."
        } else if !offlineQueue.pendingOperations.isEmpty {
            return "\(offlineQueue.pendingOperations.count) operations pending"
        } else {
            return "All data synced"
        }
    }
}

// MARK: - Sync Status Bar

struct SyncStatusBar: View {
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    @State private var showDetails = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main status bar
            HStack {
                // Network indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(offlineQueue.isOnline ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(offlineQueue.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sync progress
                if offlineQueue.isSyncing {
                    HStack(spacing: 8) {
                        ProgressView(value: offlineQueue.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 100)
                        
                        Text("\(Int(offlineQueue.syncProgress * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                    }
                } else if !offlineQueue.pendingOperations.isEmpty {
                    Button(action: { 
                        Task {
                            await offlineQueue.processPendingQueue()
                        }
                    }) {
                        Label("Sync Now (\(offlineQueue.pendingOperations.count))", 
                              systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                    }
                    .buttonStyle(.link)
                }
                
                Spacer()
                
                // Details toggle
                Button(action: { showDetails.toggle() }) {
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Expanded details
            if showDetails {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    if let error = offlineQueue.lastSyncError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Last error: \(error.localizedDescription)")
                                .font(.caption)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button("Retry") {
                                Task {
                                    await offlineQueue.processPendingQueue()
                                }
                            }
                            .buttonStyle(.link)
                            .font(.caption)
                        }
                    }
                    
                    if !offlineQueue.pendingOperations.isEmpty {
                        Text("Pending Operations:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ForEach(offlineQueue.pendingOperations.prefix(5)) { operation in
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("\(operation.entityType) - \(operation.type.rawValue)")
                                    .font(.caption)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                if operation.retryCount > 0 {
                                    Text("Retry \(operation.retryCount)")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        if offlineQueue.pendingOperations.count > 5 {
                            Text("... and \(offlineQueue.pendingOperations.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
    }
    
    private func iconForOperation(_ operation: SyncOperation) -> String {
        switch operation {
        case .create:
            return "plus.circle"
        case .update:
            return "arrow.triangle.2.circlepath"
        case .delete:
            return "trash.circle"
        case .batchImport:
            return "arrow.down.circle"
        case .batchExport:
            return "arrow.up.circle"
        case .webhookReceived:
            return "bell.fill"
        case .conflictResolved:
            return "checkmark.shield"
        case .mappingCreated:
            return "link.circle"
        case .mappingDeleted:
            return "link.circle.fill"
        }
    }
}

// MARK: - Pull to Refresh

struct PullToRefresh: ViewModifier {
    @Binding var isRefreshing: Bool
    let onRefresh: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if isRefreshing {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Syncing...")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .shadow(radius: 2)
                    .offset(y: -10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .pullToRefresh)) { _ in
                Task {
                    isRefreshing = true
                    await onRefresh()
                    isRefreshing = false
                }
            }
    }
}

extension View {
    func pullToRefresh(isRefreshing: Binding<Bool>, onRefresh: @escaping () async -> Void) -> some View {
        self.modifier(PullToRefresh(isRefreshing: isRefreshing, onRefresh: onRefresh))
    }
}

// MARK: - Offline Mode Banner

struct OfflineBanner: View {
    @StateObject private var offlineQueue = OfflineQueueManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        if !offlineQueue.isOnline {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 14))
                    
                    Text("Offline Mode")
                        .font(.system(size: 13, weight: .medium))
                    
                    if !offlineQueue.pendingOperations.isEmpty {
                        Text("• \(offlineQueue.pendingOperations.count) pending")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "info.circle")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundColor(.orange)
                .background(Color.orange.opacity(0.15))
                
                if isExpanded {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What works offline:")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        ForEach([
                            "✓ View existing data",
                            "✓ Create new records",
                            "✓ Edit information",
                            "✓ Basic search"
                        ], id: \.self) { feature in
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Changes will sync when reconnected")
                            .font(.caption)
                            .italic()
                            .padding(.top, 4)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.05))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
    }
}

// MARK: - Sync Conflict Resolution

private struct GenericConflictResolutionSheet: View {
    let localItem: String
    let remoteItem: String
    let onResolve: (ConflictResolution) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Sync Conflict Detected")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("The same record was modified in multiple places")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Comparison
            HStack(spacing: 20) {
                // Local version
                VStack(alignment: .leading, spacing: 8) {
                    Label("Local Version", systemImage: "laptopcomputer")
                        .font(.headline)
                    
                    Text(localItem)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Remote version
                VStack(alignment: .leading, spacing: 8) {
                    Label("Server Version", systemImage: "cloud")
                        .font(.headline)
                    
                    Text(remoteItem)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Actions
            HStack(spacing: 12) {
                Button("Keep Local") {
                    onResolve(.useLocal)
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Keep Server") {
                    onResolve(.useRemote)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Merge") {
                    onResolve(.merge)
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(30)
        .frame(width: 600)
    }
}

// MARK: - Live Status Indicator

private struct SyncLiveStatusIndicator: View {
    @State private var isAnimating = false
    let isLive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isLive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(isAnimating && isLive ? 1.2 : 1.0)
                .animation(
                    isLive ? Animation.easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true) : .default,
                    value: isAnimating
                )
            
            Text(isLive ? "Live" : "Offline")
                .font(.caption)
                .foregroundColor(isLive ? .green : .secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pullToRefresh = Notification.Name("pullToRefresh")
}
