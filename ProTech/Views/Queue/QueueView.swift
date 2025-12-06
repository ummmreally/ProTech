//
//  QueueView.swift
//  ProTech
//
//  Queue management for customer check-ins and repairs
//

import SwiftUI
import CoreData

struct QueueView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: true)],
        predicate: NSPredicate(format: "status == %@ OR status == %@", "waiting", "in_progress"),
        animation: .default
    ) private var activeTickets: FetchedResults<Ticket>
    
    @State private var showingCheckIn = false
    @State private var selectedTicket: Ticket?
    @State private var filterStatus: TicketStatus = .all
    
    var filteredTickets: [Ticket] {
        if filterStatus == .all {
            return Array(activeTickets)
        } else {
            return activeTickets.filter { $0.status == filterStatus.rawValue }
        }
    }
    
    // Count tickets by status
    func countForStatus(_ status: TicketStatus) -> Int {
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
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Service Queue")
                        .font(AppTheme.Typography.largeTitle)
                        .bold()
                    Text("\(filteredTickets.count) customer\(filteredTickets.count == 1 ? "" : "s") waiting")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingCheckIn = true
                } label: {
                    Label("Check In Customer", systemImage: "person.badge.plus")
                }
                .buttonStyle(PremiumButtonStyle(variant: .primary))
            }
            .padding(AppTheme.Spacing.xl)
            
            // Filter with counts
            Picker("Filter", selection: $filterStatus) {
                ForEach(TicketStatus.allCases, id: \.self) { status in
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
            
            // Queue List
            if filteredTickets.isEmpty {
                VStack(spacing: AppTheme.Spacing.xl) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("All caught up!")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(.secondary)
                    Text("No customers in queue")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.secondary)
                    
                    Button {
                        showingCheckIn = true
                    } label: {
                        Label("Check In Customer", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(PremiumButtonStyle(variant: .primary))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(filteredTickets) { ticket in
                            QueueTicketCard(
                                ticket: ticket,
                                onQuickView: {
                                    selectedTicket = ticket
                                }
                            )
                        }
                    }
                    .padding(AppTheme.Spacing.xl)
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

// MARK: - Ticket Status Enum

enum TicketStatus: String, CaseIterable {
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

// MARK: - Queue Ticket Card

struct QueueTicketCard: View {
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
            HStack(spacing: AppTheme.Spacing.lg) {
                // Status indicator
                VStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(statusColor.gradient)
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: statusIcon)
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    
                    Text(ticketNumber)
                        .font(AppTheme.Typography.caption2)
                        .bold()
                        .foregroundColor(.secondary)
                }
                
                // Customer info
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    if let customer = customer.first {
                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            .font(AppTheme.Typography.headline)
                    } else {
                        Text("Unknown Customer")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    if let device = ticket.deviceType {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: deviceIcon(device))
                            Text(device)
                        }
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let issue = ticket.issueDescription {
                        Text(issue)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Time info and Quick View button
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                    if let checkedIn = ticket.checkedInAt {
                        Text(timeAgo(checkedIn))
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Text(checkedIn, format: .dateTime.hour().minute())
                            .font(AppTheme.Typography.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    QueueView.QueueStatusBadge(status: ticket.status ?? "waiting")
                    
                    // Quick View button
                    Button {
                        onQuickView()
                    } label: {
                        Label("Quick View", systemImage: "eye")
                            .font(AppTheme.Typography.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(OutlinedButtonStyle(color: statusColor))
                    .controlSize(.small)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.cardBackground)
            .cornerRadius(AppTheme.cardCornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(statusColor.opacity(0.2), lineWidth: 1.5)
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
        TicketStatus(rawValue: ticket.status ?? "waiting")?.color ?? .gray
    }
    
    private var statusIcon: String {
        TicketStatus(rawValue: ticket.status ?? "waiting")?.icon ?? "clock.fill"
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

// MARK: - Status Badge (reuse from SMS view)

extension QueueView {
    struct QueueStatusBadge: View {
        let status: String
        
        var body: some View {
            Text(status.replacingOccurrences(of: "_", with: " ").uppercased())
                .font(AppTheme.Typography.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(6)
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
}
