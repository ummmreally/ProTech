//
//  AppointmentDetailView.swift
//  ProTech
//
//  Appointment detail view
//

import SwiftUI
import CoreData

struct AppointmentDetailView: View {
    let appointment: Appointment
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    private enum PortalEstimateEvent {
        case approved
        case declined
    }
    
    private struct EstimatePortalAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }
    
    @State private var portalAlert: EstimatePortalAlert?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appointment.typeDisplayName)
                            .font(.title)
                            .bold()
                        
                        HStack {
                            Image(systemName: statusIcon)
                                .foregroundColor(statusColor)
                            Text(appointment.status?.capitalized ?? "Unknown")
                                .foregroundColor(statusColor)
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    
                    // Date & Time
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            if let scheduledDate = appointment.scheduledDate {
                                HStack {
                                    Text("Scheduled")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dateFormatter.string(from: scheduledDate))
                                        .bold()
                                }
                            }
                            
                            HStack {
                                Text("Duration")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(appointment.formattedDuration)
                                    .bold()
                            }
                            
                            if let endDate = appointment.endDate {
                                HStack {
                                    Text("Ends")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dateFormatter.string(from: endDate))
                                        .bold()
                                }
                            }
                        }
                    } label: {
                        Label("Schedule", systemImage: "calendar")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    // Notes
                    if let notes = appointment.notes, !notes.isEmpty {
                        GroupBox {
                            Text(notes)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Status Information
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Confirmation Sent")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: appointment.confirmationSent ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundColor(appointment.confirmationSent ? .green : .gray)
                            }
                            
                            HStack {
                                Text("Reminder Sent")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Image(systemName: appointment.reminderSent ? "checkmark.circle.fill" : "xmark.circle")
                                    .foregroundColor(appointment.reminderSent ? .green : .gray)
                            }
                            
                            if let completedAt = appointment.completedAt {
                                HStack {
                                    Text("Completed")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dateFormatter.string(from: completedAt))
                                        .bold()
                                }
                            }
                            
                            if let cancelledAt = appointment.cancelledAt {
                                HStack {
                                    Text("Cancelled")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(dateFormatter.string(from: cancelledAt))
                                        .bold()
                                        .foregroundColor(.red)
                                }
                            }
                            
                            if let reason = appointment.cancellationReason, !reason.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Cancellation Reason")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(reason)
                                        .font(.body)
                                }
                            }
                        }
                    } label: {
                        Label("Status Details", systemImage: "info.circle")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Appointment Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .alert(item: $portalAlert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message), dismissButton: .default(Text("OK")))
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateApproved)) { notification in
            handleEstimateNotification(notification, event: .approved)
        }
        .onReceive(NotificationCenter.default.publisher(for: .estimateDeclined)) { notification in
            handleEstimateNotification(notification, event: .declined)
        }
    }

    private var statusIcon: String {
        switch appointment.status {
        case "confirmed":
            return "checkmark.circle.fill"
        case "scheduled":
            return "calendar.circle.fill"
        case "completed":
            return "checkmark.circle.fill"
        case "cancelled":
            return "xmark.circle.fill"
        case "no_show":
            return "exclamationmark.triangle.fill"
        default:
            return "circle"
        }
    }
    
    private var statusColor: Color {
        switch appointment.status {
        case "confirmed":
            return .green
        case "scheduled":
            return .blue
        case "completed":
            return .gray
        case "cancelled":
            return .red
        case "no_show":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - Portal Notification Handling

extension AppointmentDetailView {
    @MainActor
    private func handleEstimateNotification(_ notification: Notification, event: PortalEstimateEvent) {
        guard let estimateIdValue = notification.userInfo?["estimateId"] else { return }
        let estimateId: UUID?
        if let uuid = estimateIdValue as? UUID {
            estimateId = uuid
        } else if let uuidString = estimateIdValue as? String {
            estimateId = UUID(uuidString: uuidString)
        } else {
            estimateId = nil
        }
        
        guard
            let estimateId,
            let estimate = fetchEstimate(by: estimateId),
            shouldDisplayAlert(for: estimate)
        else {
            return
        }
        
        let estimateNumber = estimate.formattedEstimateNumber
        switch event {
        case .approved:
            portalAlert = EstimatePortalAlert(
                title: "Estimate Approved",
                message: "\(estimateNumber) was approved via the customer portal."
            )
        case .declined:
            let reason = (notification.userInfo?["reason"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            let reasonText: String
            if let reason, !reason.isEmpty {
                reasonText = " Reason: \(reason)."
            } else {
                reasonText = ""
            }
            portalAlert = EstimatePortalAlert(
                title: "Estimate Declined",
                message: "\(estimateNumber) was declined via the customer portal.\(reasonText)"
            )
        }
    }
    
    private func fetchEstimate(by id: UUID) -> Estimate? {
        let request: NSFetchRequest<Estimate> = Estimate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return try? viewContext.fetch(request).first
    }
    
    private func shouldDisplayAlert(for estimate: Estimate) -> Bool {
        if let appointmentTicketId = appointment.ticketId, let estimateTicketId = estimate.ticketId, appointmentTicketId == estimateTicketId {
            return true
        }
        
        if let appointmentCustomerId = appointment.customerId, let estimateCustomerId = estimate.customerId, appointmentCustomerId == estimateCustomerId {
            return true
        }
        
        return false
    }
}
