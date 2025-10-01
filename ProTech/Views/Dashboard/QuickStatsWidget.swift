//
//  QuickStatsWidget.swift
//  ProTech
//
//  Real-time dashboard widgets with live data
//

import SwiftUI
import CoreData

struct QuickStatsWidget: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Customer.createdAt, ascending: false)]
    ) private var customers: FetchedResults<Customer>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.checkedInAt, ascending: false)]
    ) private var tickets: FetchedResults<Ticket>
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            // Today's Check-ins
            StatWidget(
                title: "Today's Check-ins",
                value: "\(todayCheckIns)",
                icon: "person.badge.plus",
                color: .blue,
                trend: checkInTrend
            )
            
            // Active Repairs
            StatWidget(
                title: "Active Repairs",
                value: "\(activeRepairs)",
                icon: "wrench.and.screwdriver",
                color: .orange,
                trend: nil
            )
            
            // Ready for Pickup
            StatWidget(
                title: "Ready for Pickup",
                value: "\(readyForPickup)",
                icon: "checkmark.circle",
                color: .green,
                trend: nil
            )
            
            // This Week
            StatWidget(
                title: "This Week",
                value: "\(thisWeekTickets)",
                icon: "calendar",
                color: .purple,
                trend: weeklyTrend
            )
            
            // Revenue (Estimate)
            StatWidget(
                title: "Est. Revenue",
                value: "$\(estimatedRevenue)",
                icon: "dollarsign.circle",
                color: .green,
                trend: revenueTrend
            )
            
            // Avg Turnaround
            StatWidget(
                title: "Avg Turnaround",
                value: averageTurnaround,
                icon: "clock",
                color: .indigo,
                trend: nil
            )
        }
    }
    
    // MARK: - Computed Stats
    
    private var todayCheckIns: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return tickets.filter {
            guard let checkedIn = $0.checkedInAt else { return false }
            return checkedIn >= today
        }.count
    }
    
    private var activeRepairs: Int {
        tickets.filter { $0.status == "in_progress" }.count
    }
    
    private var readyForPickup: Int {
        tickets.filter { $0.status == "completed" }.count
    }
    
    private var thisWeekTickets: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return tickets.filter {
            guard let checkedIn = $0.checkedInAt else { return false }
            return checkedIn >= weekAgo
        }.count
    }
    
    private var estimatedRevenue: String {
        // Calculate from completed tickets this month
        let monthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        let completedThisMonth = tickets.filter {
            guard let completed = $0.completedAt else { return false }
            return completed >= monthStart
        }
        
        // Estimate $150 per repair (you could parse actual costs from notes)
        let revenue = completedThisMonth.count * 150
        return String(revenue)
    }
    
    private var averageTurnaround: String {
        let completed = tickets.filter { $0.completedAt != nil && $0.checkedInAt != nil }
        guard !completed.isEmpty else { return "—" }
        
        let totalHours = completed.compactMap { ticket -> Int? in
            guard let checkedIn = ticket.checkedInAt,
                  let completedAt = ticket.completedAt else { return nil }
            return Int(completedAt.timeIntervalSince(checkedIn) / 3600)
        }.reduce(0, +)
        
        let avgHours = totalHours / completed.count
        
        if avgHours < 24 {
            return "\(avgHours)h"
        } else {
            return "\(avgHours / 24)d"
        }
    }
    
    private var checkInTrend: StatTrend? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayStart = Calendar.current.startOfDay(for: yesterday)
        let yesterdayEnd = Calendar.current.date(byAdding: .day, value: 1, to: yesterdayStart) ?? Date()
        
        let yesterdayCount = tickets.filter {
            guard let checkedIn = $0.checkedInAt else { return false }
            return checkedIn >= yesterdayStart && checkedIn < yesterdayEnd
        }.count
        
        if todayCheckIns > yesterdayCount {
            let increase = ((Double(todayCheckIns - yesterdayCount) / Double(max(yesterdayCount, 1))) * 100)
            return .up(String(format: "%.0f%%", increase))
        } else if todayCheckIns < yesterdayCount {
            let decrease = ((Double(yesterdayCount - todayCheckIns) / Double(yesterdayCount)) * 100)
            return .down(String(format: "%.0f%%", decrease))
        }
        return nil
    }
    
    private var weeklyTrend: StatTrend? {
        let lastWeekStart = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let lastWeekEnd = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let lastWeekCount = tickets.filter {
            guard let checkedIn = $0.checkedInAt else { return false }
            return checkedIn >= lastWeekStart && checkedIn < lastWeekEnd
        }.count
        
        if thisWeekTickets > lastWeekCount {
            let increase = ((Double(thisWeekTickets - lastWeekCount) / Double(max(lastWeekCount, 1))) * 100)
            return .up(String(format: "%.0f%%", increase))
        } else if thisWeekTickets < lastWeekCount {
            let decrease = ((Double(lastWeekCount - thisWeekTickets) / Double(lastWeekCount)) * 100)
            return .down(String(format: "%.0f%%", decrease))
        }
        return nil
    }
    
    private var revenueTrend: StatTrend? {
        // Compare to last month
        let thisMonthStart = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        let lastMonthStart = Calendar.current.date(byAdding: .month, value: -1, to: thisMonthStart) ?? Date()
        
        let lastMonthCompleted = tickets.filter {
            guard let completed = $0.completedAt else { return false }
            return completed >= lastMonthStart && completed < thisMonthStart
        }.count
        
        let thisMonthCompleted = tickets.filter {
            guard let completed = $0.completedAt else { return false }
            return completed >= thisMonthStart
        }.count
        
        if thisMonthCompleted > lastMonthCompleted {
            let increase = ((Double(thisMonthCompleted - lastMonthCompleted) / Double(max(lastMonthCompleted, 1))) * 100)
            return .up(String(format: "%.0f%%", increase))
        } else if thisMonthCompleted < lastMonthCompleted {
            let decrease = ((Double(lastMonthCompleted - thisMonthCompleted) / Double(lastMonthCompleted)) * 100)
            return .down(String(format: "%.0f%%", decrease))
        }
        return nil
    }
}

// MARK: - Stat Widget

struct StatWidget: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: StatTrend?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(10)
                
                Spacer()
                
                if let trend = trend {
                    HStack(spacing: 4) {
                        Image(systemName: trend.icon)
                            .font(.caption2)
                        Text(trend.text)
                            .font(.caption2)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(trend.color.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Stat Trend

enum StatTrend {
    case up(String)
    case down(String)
    
    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        }
    }
    
    var text: String {
        switch self {
        case .up(let value): return value
        case .down(let value): return value
        }
    }
}
