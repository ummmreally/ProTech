//
//  CustomerRepairHistoryCard.swift
//  ProTech
//
//  Displays customer's repair ticket history in POS
//

import SwiftUI

struct CustomerRepairHistoryCard: View {
    let repairs: [Ticket]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.blue)
                Text("Recent Repairs")
                    .font(.headline)
                    .foregroundColor(Color(hex: "212121"))
                Spacer()
                Text("(\(repairs.count))")
                    .font(.caption)
                    .foregroundColor(Color(hex: "757575"))
            }
            
            if repairs.isEmpty {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 32))
                        .foregroundColor(Color(hex: "757575").opacity(0.4))
                    Text("No repair history")
                        .font(.caption)
                        .foregroundColor(Color(hex: "757575"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // Repairs list
                VStack(spacing: 8) {
                    ForEach(repairs.prefix(5)) { ticket in
                        RepairHistoryRow(ticket: ticket)
                    }
                    
                    if repairs.count > 5 {
                        Text("+ \(repairs.count - 5) more repairs")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "757575"))
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct RepairHistoryRow: View {
    let ticket: Ticket
    
    var body: some View {
        HStack(spacing: 10) {
            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("#\(ticket.ticketNumber)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "212121"))
                    
                    if let device = ticket.deviceType {
                        Text("•")
                            .foregroundColor(Color(hex: "757575"))
                        Text(device)
                            .font(.caption)
                            .foregroundColor(Color(hex: "757575"))
                    }
                }
                
                if let date = ticket.createdAt {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(Color(hex: "757575"))
                }
            }
            
            Spacer()
            
            // Status badge
            Text(statusText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor)
                .cornerRadius(8)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch ticket.status {
        case "completed", "picked_up":
            return "checkmark.circle.fill"
        case "in_progress", "diagnostic":
            return "arrow.triangle.2.circlepath"
        case "waiting_parts", "waiting_approval":
            return "clock.fill"
        default:
            return "circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch ticket.status {
        case "completed", "picked_up":
            return Color(hex: "00C853")
        case "in_progress", "diagnostic":
            return .blue
        case "waiting_parts", "waiting_approval":
            return .orange
        default:
            return .gray
        }
    }
    
    private var statusText: String {
        switch ticket.status {
        case "completed":
            return "Done"
        case "picked_up":
            return "Picked Up"
        case "in_progress":
            return "In Progress"
        case "diagnostic":
            return "Diagnosing"
        case "waiting_parts":
            return "Waiting Parts"
        case "waiting_approval":
            return "Need Approval"
        default:
            return ticket.status?.capitalized ?? "Unknown"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    CustomerRepairHistoryCard(repairs: [])
        .padding()
}
