//
//  RepairsView.swift
//  ProTech
//
//  Repairs management view (formerly QueueView)
//

import SwiftUI
import CoreData

struct RepairsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: true)],
        predicate: NSPredicate(format: "status == %@ OR status == %@", "waiting", "in_progress"),
        animation: .default
    ) private var activeTickets: FetchedResults<Ticket>
    
    @State private var showingCheckIn = false
    @State private var selectedTicket: Ticket?
    @State private var filterStatus: RepairStatus = .all
    
    var filteredTickets: [Ticket] {
        if filterStatus == .all {
            return Array(activeTickets)
        } else {
            return activeTickets.filter { $0.status == filterStatus.rawValue }
        }
    }
    
    // Count tickets by status
    func countForStatus(_ status: RepairStatus) -> Int {
        if status == .all {
            return activeTickets.count
        } else {
            return activeTickets.filter { $0.status == status.rawValue }.count
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Repairs")
                        .font(.largeTitle)
                        .bold()
                    Text("\(filteredTickets.count) active repair\(filteredTickets.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingCheckIn = true
                } label: {
                    Label("Check In Customer", systemImage: "person.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Filter with counts
            Picker("Filter", selection: $filterStatus) {
                ForEach(RepairStatus.allCases, id: \.self) { status in
                    let count = countForStatus(status)
                    if count > 0 {
                        Text("\(status.displayName) (\(count))").tag(status)
                    } else {
                        Text(status.displayName).tag(status)
                    }
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
                .padding(.top)
            
            // Repairs List
            if filteredTickets.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No active repairs")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Check In Customer", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTickets) { ticket in
                            RepairTicketCard(
                                ticket: ticket,
                                onQuickView: {
                                    selectedTicket = ticket
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            CheckInCustomerView()
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailView(ticket: ticket)
        }
    }
}

// MARK: - Repair Status Enum

enum RepairStatus: String, CaseIterable {
    case all = "all"
    case waiting = "waiting"
    case inProgress = "in_progress"
    case completed = "completed"
    case pickedUp = "picked_up"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .waiting: return "Waiting"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .pickedUp: return "Picked Up"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .waiting: return .orange
        case .inProgress: return .purple
        case .completed: return .green
        case .pickedUp: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "line.3.horizontal"
        case .waiting: return "clock.fill"
        case .inProgress: return "wrench.and.screwdriver.fill"
        case .completed: return "checkmark.circle.fill"
        case .pickedUp: return "hand.thumbsup.fill"
        }
    }
}

// MARK: - Repair Ticket Card

struct RepairTicketCard: View {
    @ObservedObject var ticket: Ticket
    @FetchRequest var customer: FetchedResults<Customer>
    let onQuickView: () -> Void
    
    init(ticket: Ticket, onQuickView: @escaping () -> Void) {
        self.ticket = ticket
        self.onQuickView = onQuickView
        _customer = FetchRequest<Customer>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", ticket.customerId! as CVarArg)
        )
    }
    
    var body: some View {
        NavigationLink(destination: RepairDetailView(ticket: ticket)) {
            HStack(spacing: 16) {
                // Status indicator
                VStack {
                    Circle()
                        .fill(statusColor.gradient)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: statusIcon)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    
                    Text(ticketNumber)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                }
                
                // Customer info
                VStack(alignment: .leading, spacing: 6) {
                    if let customer = customer.first {
                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            .font(.headline)
                    } else {
                        Text("Unknown Customer")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let device = ticket.deviceType {
                        HStack(spacing: 4) {
                            Image(systemName: deviceIcon(device))
                            Text(device)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let issue = ticket.issueDescription {
                        Text(issue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Time info and Quick View button
                VStack(alignment: .trailing, spacing: 4) {
                    if let checkedIn = ticket.checkedInAt {
                        Text(timeAgo(checkedIn))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(checkedIn, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    RepairStatusBadge(status: ticket.status ?? "waiting")
                    
                    // Quick View button
                    Button {
                        onQuickView()
                    } label: {
                        Label("Quick View", systemImage: "eye")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var ticketNumber: String {
        let number = ticket.ticketNumber
        if number != 0 {
            return "#\(number)"
        }
        return "#\(String(ticket.id?.uuidString.prefix(4) ?? ""))"
    }
    
    private var statusColor: Color {
        RepairStatus(rawValue: ticket.status ?? "waiting")?.color ?? .gray
    }
    
    private var statusIcon: String {
        RepairStatus(rawValue: ticket.status ?? "waiting")?.icon ?? "clock.fill"
    }
    
    private func deviceIcon(_ device: String) -> String {
        switch device.lowercased() {
        case let d where d.contains("iphone"): return "iphone"
        case let d where d.contains("ipad"): return "ipad"
        case let d where d.contains("mac"): return "laptopcomputer"
        case let d where d.contains("watch"): return "applewatch"
        default: return "apps.iphone"
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        
        if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
}

// MARK: - Status Badge

struct RepairStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").uppercased())
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    var backgroundColor: Color {
        switch status.lowercased() {
        case "waiting":
            return .orange
        case "in_progress":
            return .purple
        case "completed":
            return .green
        case "picked_up":
            return .gray
        default:
            return .blue
        }
    }
}

#Preview {
    RepairsView()
}
