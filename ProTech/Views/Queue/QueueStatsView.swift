//
//  QueueStatsView.swift
//  ProTech
//
//  Real-time queue statistics and metrics
//

import SwiftUI
import CoreData

struct QueueStatsView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: true)]
    ) private var allTickets: FetchedResults<Ticket>
    
    var waitingCount: Int {
        allTickets.filter { $0.status == "waiting" }.count
    }
    
    var inProgressCount: Int {
        allTickets.filter { $0.status == "in_progress" }.count
    }
    
    var completedTodayCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return allTickets.filter {
            guard let completedAt = $0.completedAt else { return false }
            return completedAt >= today && $0.status == "completed"
        }.count
    }
    
    var averageWaitTime: String {
        let waitingTickets = allTickets.filter { $0.status == "waiting" || $0.status == "in_progress" }
        guard !waitingTickets.isEmpty else { return "—" }
        
        let totalMinutes = waitingTickets.compactMap { ticket -> Int? in
            guard let checkedIn = ticket.checkedInAt else { return nil }
            return Int(Date().timeIntervalSince(checkedIn) / 60)
        }.reduce(0, +)
        
        let average = totalMinutes / waitingTickets.count
        
        if average < 60 {
            return "\(average)m"
        } else {
            let hours = average / 60
            let minutes = average % 60
            return "\(hours)h \(minutes)m"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                QueueStatCard(
                    title: "Waiting",
                    value: "\(waitingCount)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                QueueStatCard(
                    title: "In Progress",
                    value: "\(inProgressCount)",
                    icon: "wrench.and.screwdriver.fill",
                    color: .purple
                )
            }
            
            HStack(spacing: 16) {
                QueueStatCard(
                    title: "Completed Today",
                    value: "\(completedTodayCount)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
                
                QueueStatCard(
                    title: "Avg Wait Time",
                    value: averageWaitTime,
                    icon: "timer",
                    color: .blue
                )
            }
        }
        .padding()
    }
}

struct QueueStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}
