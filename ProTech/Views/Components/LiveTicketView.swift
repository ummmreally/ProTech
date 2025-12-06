//
//  LiveTicketView.swift
//  ProTech
//
//  Real-time ticket status updates with Supabase subscriptions
//

import SwiftUI
import Combine
@preconcurrency import UserNotifications

struct LiveTicketView: View {
    let ticket: Ticket
    
    @StateObject private var liveUpdater = TicketLiveUpdater()
    @State private var currentStatus: String
    @State private var showStatusAnimation = false
    @State private var lastUpdated = Date()
    
    init(ticket: Ticket) {
        self.ticket = ticket
        self._currentStatus = State(initialValue: ticket.status ?? "pending")
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator with live updates
            statusBadge
            
            // Ticket info
            VStack(alignment: .leading, spacing: 4) {
                Text("Ticket #\(ticket.ticketNumber)")
                    .font(.headline)
                
                Text(ticket.customerDisplayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let device = ticket.deviceModel {
                    Text(device)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Live indicator
            if liveUpdater.isConnected {
                LiveStatusIndicator(isLive: true)
            }
            
            // Last updated
            VStack(alignment: .trailing, spacing: 2) {
                Text("Updated")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(lastUpdated, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(showStatusAnimation ? statusColor : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.5), value: showStatusAnimation)
        )
        .onAppear {
            if let id = ticket.id {
                liveUpdater.startMonitoring(ticketId: id)
            }
        }
        .onDisappear {
            liveUpdater.stopMonitoring()
        }
        .onChange(of: liveUpdater.currentStatus) { _, newStatus in
            if let status = newStatus, status != currentStatus {
                withAnimation {
                    currentStatus = status
                    showStatusAnimation = true
                    lastUpdated = Date()
                }
                
                // Flash animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showStatusAnimation = false
                }
            }
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.5), lineWidth: showStatusAnimation ? 8 : 0)
                        .scaleEffect(showStatusAnimation ? 2 : 1)
                        .opacity(showStatusAnimation ? 0 : 1)
                        .animation(.easeOut(duration: 0.5), value: showStatusAnimation)
                )
            
            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch currentStatus.lowercased() {
        case "pending": return .orange
        case "in_progress": return .blue
        case "waiting_parts": return .purple
        case "ready": return .green
        case "completed": return .gray
        case "cancelled": return .red
        default: return .gray
        }
    }
    
    private var statusText: String {
        switch currentStatus.lowercased() {
        case "pending": return "Pending"
        case "in_progress": return "In Progress"
        case "waiting_parts": return "Waiting Parts"
        case "ready": return "Ready"
        case "completed": return "Completed"
        case "cancelled": return "Cancelled"
        default: return "Unknown"
        }
    }
}

// MARK: - Ticket Live Updater

@MainActor
class TicketLiveUpdater: ObservableObject {
    @Published var currentStatus: String?
    @Published var isConnected = false
    @Published var lastUpdate: Date?
    
    private let supabase = SupabaseService.shared
    // TODO: Uncomment when Supabase Realtime types are available
    // private var channel: RealtimeChannel?
    private var ticketId: UUID?
    
    func startMonitoring(ticketId: UUID) {
        self.ticketId = ticketId
        // TODO: Implement proper Supabase Realtime ticket monitoring
        print("Live ticket monitoring not yet implemented for: \(ticketId)")
    }
    
    func stopMonitoring() {
        isConnected = false
    }
    
    private func sendStatusNotification(status: String) {
        guard #available(macOS 11.0, *) else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let center = UNUserNotificationCenter.current()
            let content = UNMutableNotificationContent()
            content.title = "Ticket Status Update"
            content.body = "Ticket is now \(status)"
            content.sound = .default
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request, withCompletionHandler: nil)
        }
    }
}

// MARK: - Live Tickets Dashboard

struct LiveTicketsDashboard: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)
        ],
        predicate: NSPredicate(format: "status != %@", "completed")
    )
    private var activeTickets: FetchedResults<Ticket>
    
    @State private var isRefreshing = false
    @StateObject private var ticketSyncer = TicketSyncer()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("Active Tickets")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    SyncStatusBadge()
                    
                    Button(action: {
                        Task {
                            await refreshTickets()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.bordered)
                    .disabled(isRefreshing)
                }
                .padding(.horizontal)
                
                // Tickets grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(activeTickets) { ticket in
                        LiveTicketView(ticket: ticket)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            Task {
                await ticketSyncer.subscribeToChanges()
            }
        }
    }
    
    private func refreshTickets() async {
        isRefreshing = true
        do {
            try await ticketSyncer.download()
        } catch {
            print("Failed to refresh tickets: \(error)")
        }
        isRefreshing = false
    }
}

// MARK: - Ticket Status Timeline

struct TicketStatusTimeline: View {
    let ticket: Ticket
    @State private var statusHistory: [StatusChange] = []
    
    struct StatusChange: Identifiable {
        let id = UUID()
        let status: String
        let timestamp: Date
        let employee: String?
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status History")
                .font(.headline)
            
            ForEach(statusHistory) { change in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline dot
                    Circle()
                        .fill(colorForStatus(change.status))
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(change.status.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        if let employee = change.employee {
                            Text("by \(employee)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(change.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            loadStatusHistory()
        }
    }
    
    private func loadStatusHistory() {
        // In production, this would query the actual status history from Supabase
        // For now, we'll use mock data
        statusHistory = [
            StatusChange(status: "pending", timestamp: Date().addingTimeInterval(-7200), employee: "John Doe"),
            StatusChange(status: "in_progress", timestamp: Date().addingTimeInterval(-3600), employee: "Jane Smith"),
            StatusChange(status: "ready", timestamp: Date().addingTimeInterval(-1800), employee: "Jane Smith")
        ]
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "in_progress": return .blue
        case "waiting_parts": return .purple
        case "ready": return .green
        case "completed": return .gray
        case "cancelled": return .red
        default: return .gray
        }
    }
}

#Preview {
    LiveTicketsDashboard()
}
