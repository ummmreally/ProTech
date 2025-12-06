//
//  TodayScheduleWidget.swift
//  ProTech
//
//  Today's appointments and schedule widget
//

import SwiftUI
import CoreData

struct TodayScheduleWidget: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var appointments: [Appointment] = []
    @State private var todayPickups: [Ticket] = []
    
    private let metricsService = DashboardMetricsService.shared
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Today's Schedule")
                    .font(AppTheme.Typography.headline)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
            
            if appointments.isEmpty && todayPickups.isEmpty {
                // Empty State
                VStack(spacing: AppTheme.Spacing.md) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Scheduled Items")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundColor(.secondary)
                    Text("All clear for today!")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        // Appointments
                        ForEach(appointments) { appointment in
                            AppointmentScheduleRow(appointment: appointment, dateFormatter: dateFormatter)
                        }
                        
                        // Today's Pickups
                        if !todayPickups.isEmpty {
                            Divider()
                                .padding(.vertical, 4)
                            
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Ready for Pickup")
                                    .font(.caption)
                                    .bold()
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            
                            ForEach(todayPickups, id: \.id) { ticket in
                                PickupScheduleRow(ticket: ticket)
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .glassCard()
        .task {
            await loadSchedule()
        }
    }
    
    private func loadSchedule() async {
        await MainActor.run {
            appointments = metricsService.getTodayAppointments()
            todayPickups = metricsService.getTodayPickups()
        }
    }
}

struct AppointmentScheduleRow: View {
    let appointment: Appointment
    let dateFormatter: DateFormatter
    @Environment(\.managedObjectContext) private var viewContext
    
    var customer: Customer? {
        guard let customerId = appointment.customerId else { return nil }
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Time
            if let scheduledDate = appointment.scheduledDate {
                Text(dateFormatter.string(from: scheduledDate))
                    .font(AppTheme.Typography.caption)
                    .bold()
                    .frame(width: 60, alignment: .leading)
            }
            
            // Icon
            Image(systemName: appointment.typeDisplayIcon)
                .foregroundColor(appointment.typeDisplayColor)
                .frame(width: 24)
            
            // Details
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(appointment.typeDisplayName)
                    .font(AppTheme.Typography.subheadline)
                    .bold()
                if let customer = customer {
                    Text(customer.displayName)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Badge
            statusBadge
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if let status = appointment.status {
            Text(status.capitalized)
                .font(AppTheme.Typography.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.15))
                .foregroundColor(statusColor)
                .cornerRadius(6)
        }
    }
    
    private var statusColor: Color {
        switch appointment.status {
        case "confirmed": return .green
        case "scheduled": return .blue
        case "completed": return .gray
        default: return .orange
        }
    }
}

struct PickupScheduleRow: View {
    let ticket: Ticket
    @Environment(\.managedObjectContext) private var viewContext
    
    var customer: Customer? {
        guard let customerId = ticket.customerId else { return nil }
        let request: NSFetchRequest<Customer> = Customer.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", customerId as CVarArg)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Repair #\(ticket.ticketNumber)")
                    .font(AppTheme.Typography.subheadline)
                    .bold()
                if let customer = customer {
                    Text(customer.displayName)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
                if let device = ticket.deviceType {
                    Text(device)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("Ready")
                .font(AppTheme.Typography.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.15))
                .foregroundColor(.green)
                .cornerRadius(6)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.cardBackground.opacity(0.5))
        .cornerRadius(AppTheme.cardCornerRadius)
    }
}

// MARK: - Appointment Extensions
// Note: typeDisplayIcon and typeDisplayColor are now defined in Appointment.swift
