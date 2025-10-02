//
//  CustomerHistoryView.swift
//  ProTech
//
//  View customer repair history and past tickets
//

import SwiftUI
import CoreData

struct CustomerHistoryView: View {
    let customer: Customer
    
    @FetchRequest var tickets: FetchedResults<Ticket>
    
    init(customer: Customer) {
        self.customer = customer
        _tickets = FetchRequest<Ticket>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: false)],
            predicate: NSPredicate(format: "customerId == %@", customer.id! as CVarArg)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Repair History")
                    .font(.title2)
                    .bold()
                Spacer()
                Text("\(tickets.count) repair\(tickets.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tickets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No repair history")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("This customer hasn't checked in any devices yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tickets) { ticket in
                            HistoryTicketCard(ticket: ticket)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - History Ticket Card

struct HistoryTicketCard: View {
    @ObservedObject var ticket: Ticket
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Ticket number and device
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if ticket.ticketNumber != 0 {
                            Text("#\(ticket.ticketNumber)")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                        
                        if let device = ticket.deviceType {
                            HStack(spacing: 4) {
                                Image(systemName: deviceIcon(device))
                                Text(device)
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                    }
                    
                    if let checkedIn = ticket.checkedInAt {
                        Text(checkedIn, format: .dateTime.month().day().year())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status badge
                TicketStatusBadge(status: ticket.status ?? "unknown")
                
                // Expand button
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
            
            // Issue preview
            if let issue = ticket.issueDescription {
                Text(issue)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 2)
                    .foregroundColor(.primary)
            }
            
            // Expanded details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    if let model = ticket.deviceModel {
                        CustomerDetailRow(label: "Model", value: model)
                    }
                    
                    if let priority = ticket.priority {
                        CustomerDetailRow(label: "Priority", value: priority.capitalized)
                    }
                    
                    if let checkedIn = ticket.checkedInAt {
                        CustomerDetailRow(label: "Checked In", value: checkedIn.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    if let completed = ticket.completedAt {
                        CustomerDetailRow(label: "Completed", value: completed.formatted(date: .abbreviated, time: .shortened))
                        
                        // Calculate turnaround time
                        if let checkedIn = ticket.checkedInAt {
                            let duration = completed.timeIntervalSince(checkedIn)
                            let hours = Int(duration / 3600)
                            let days = hours / 24
                            
                            if days > 0 {
                                CustomerDetailRow(label: "Turnaround", value: "\(days) day\(days == 1 ? "" : "s")")
                            } else {
                                CustomerDetailRow(label: "Turnaround", value: "\(hours) hour\(hours == 1 ? "" : "s")")
                            }
                        }
                    }
                    
                    if let notes = ticket.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.body)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
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
}

// MARK: - Detail Row

struct CustomerDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
        }
    }
}

// MARK: - Status Badge

struct TicketStatusBadge: View {
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
