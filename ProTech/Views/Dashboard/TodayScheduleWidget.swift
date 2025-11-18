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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("Today's Schedule")
                    .font(.headline)
                
                Spacer()
                
                Text(Date(), style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if appointments.isEmpty && todayPickups.isEmpty {
                // Empty State
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("No Scheduled Items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("All clear for today!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
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
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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
        HStack(spacing: 12) {
            // Time
            if let scheduledDate = appointment.scheduledDate {
                Text(dateFormatter.string(from: scheduledDate))
                    .font(.caption)
                    .bold()
                    .frame(width: 60, alignment: .leading)
            }
            
            // Icon
            Image(systemName: appointment.typeDisplayIcon)
                .foregroundColor(appointment.typeDisplayColor)
                .frame(width: 24)
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(appointment.typeDisplayName)
                    .font(.subheadline)
                    .bold()
                if let customer = customer {
                    Text(customer.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Badge
            statusBadge
        }
        .padding(12)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        if let status = appointment.status {
            Text(status.capitalized)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(4)
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
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Repair #\(ticket.ticketNumber)")
                    .font(.subheadline)
                    .bold()
                if let customer = customer {
                    Text(customer.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let device = ticket.deviceType {
                    Text(device)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("Ready")
                .font(.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Appointment Extensions
// Note: typeDisplayIcon and typeDisplayColor are now defined in Appointment.swift
