//
//  CustomerDetailView.swift
//  ProTech
//
//  Customer detail view with edit and actions
//

import SwiftUI
import CoreData

struct CustomerDetailView: View {
    @ObservedObject private var customer: Customer
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @FetchRequest private var appointments: FetchedResults<Appointment>
    @FetchRequest private var tickets: FetchedResults<Ticket>
    @State private var isEditing = false
    @State private var showingSMSComposer = false
    @State private var showingUpgrade = false
    @State private var isTwilioConfigured = false
    @State private var selectedAppointment: Appointment?
    @State private var selectedTicket: Ticket?

    init(customer: Customer) {
        self._customer = ObservedObject(wrappedValue: customer)

        if let id = customer.id {
            _appointments = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \Appointment.scheduledDate, ascending: true)],
                predicate: NSPredicate(format: "customerId == %@", id as CVarArg)
            )
            _tickets = FetchRequest(
                sortDescriptors: [NSSortDescriptor(keyPath: \Ticket.createdAt, ascending: false)],
                predicate: NSPredicate(format: "customerId == %@", id as CVarArg)
            )
        } else {
            _appointments = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
            _tickets = FetchRequest(sortDescriptors: [], predicate: NSPredicate(value: false))
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with avatar
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 80, height: 80)
                        .overlay {
                            Text(initials)
                                .font(.largeTitle)
                                .foregroundColor(.white)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                            .font(.title)
                            .bold()
                        if let createdAt = customer.createdAt {
                            Text("Customer since \(createdAt, format: .dateTime.month().day().year())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Loyalty Program
                LoyaltyWidget(customer: customer)
                    .padding(.horizontal)
                
                // Contact Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        if let phone = customer.phone {
                            HStack {
                                Label(phone, systemImage: "phone.fill")
                                Spacer()
                                if subscriptionManager.isProSubscriber && isTwilioConfigured {
                                    Button {
                                        showingSMSComposer = true
                                    } label: {
                                        Image(systemName: "message.fill")
                                    }
                                }
                            }
                        }
                        
                        if let email = customer.email {
                            Label(email, systemImage: "envelope.fill")
                        }
                        
                        if let address = customer.address {
                            Label {
                                Text(address)
                            } icon: {
                                Image(systemName: "mappin.circle.fill")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } label: {
                    Text("Contact Information")
                        .font(.headline)
                }
                .padding(.horizontal)

                if !tickets.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(tickets) { ticket in
                                Button {
                                    selectedTicket = ticket
                                } label: {
                                    CustomerRepairRow(ticket: ticket)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Repairs")
                                .font(.headline)
                            Spacer()
                            Text("\(tickets.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }

                if !appointments.isEmpty {
                    GroupBox {
                        VStack(spacing: 12) {
                            ForEach(appointments) { appointment in
                                Button {
                                    selectedAppointment = appointment
                                } label: {
                                    CustomerAppointmentRow(appointment: appointment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } label: {
                        HStack {
                            Text("Appointments")
                                .font(.headline)
                            Spacer()
                            Text("\(appointments.count)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Notes
                if let notes = customer.notes, !notes.isEmpty {
                    GroupBox {
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } label: {
                        Text("Notes")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                }
                
                // Actions
                GroupBox {
                    VStack(spacing: 8) {
                        ActionButton(title: "Edit Customer", icon: "pencil") {
                            isEditing = true
                        }
                        
                        if subscriptionManager.isProSubscriber {
                            ActionButton(title: "Create Intake Form", icon: "doc.text") {
                                // Navigate to forms
                            }
                            
                            ActionButton(title: "Send SMS", icon: "message") {
                                if isTwilioConfigured {
                                    showingSMSComposer = true
                                } else {
                                    // Show Twilio setup
                                    NotificationCenter.default.post(name: .openTwilioTutorial, object: nil)
                                }
                            }
                        } else {
                            ActionButton(title: "Upgrade for SMS & Forms", icon: "star.fill") {
                                showingUpgrade = true
                            }
                            .foregroundColor(.orange)
                        }
                    }
                } label: {
                    Text("Actions")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Customer Details")
        .sheet(isPresented: $isEditing) {
            EditCustomerView(customer: customer)
        }
        .sheet(isPresented: $showingSMSComposer) {
            SMSComposerView(customer: customer)
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
                .frame(width: 600, height: 700)
        }
        .sheet(item: $selectedAppointment) { appointment in
            AppointmentDetailView(appointment: appointment)
        }
        .sheet(item: $selectedTicket) { ticket in
            TicketDetailView(ticket: ticket)
        }
        .task {
            // Cache the Twilio configuration lookup so the view body
            // isn't repeatedly hitting the Keychain on every render.
            isTwilioConfigured = TwilioService.shared.isConfigured
        }
    }
    
    private var initials: String {
        let first = customer.firstName?.prefix(1).uppercased() ?? ""
        let last = customer.lastName?.prefix(1).uppercased() ?? ""
        return first + last
    }
}

private struct CustomerAppointmentRow: View {
    let appointment: Appointment

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.typeDisplayName)
                    .font(.headline)

                if let scheduledDate = appointment.scheduledDate {
                    Text(dateFormatter.string(from: scheduledDate))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let notes = appointment.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Text(appointment.status?.capitalized ?? "")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.2))
                .foregroundColor(statusColor)
                .cornerRadius(6)
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
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

private struct CustomerRepairRow: View {
    let ticket: Ticket

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Ticket #\(ticket.ticketNumber)")
                    .font(.headline)

                if let deviceType = ticket.deviceType, !deviceType.isEmpty {
                    Text(deviceType)
                        .font(.subheadline)
                }

                if let issue = ticket.issueDescription, !issue.isEmpty {
                    Text(issue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let createdAt = ticket.createdAt {
                    Text("Opened: \(dateFormatter.string(from: createdAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(ticket.status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)

                if let priority = ticket.priority, !priority.isEmpty {
                    Text(priority.capitalized)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(priorityColor.opacity(0.15))
                        .foregroundColor(priorityColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private var statusColor: Color {
        switch ticket.status {
        case "waiting":
            return .orange
        case "in_progress":
            return .blue
        case "completed":
            return .green
        case "picked_up":
            return .gray
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }

    private var priorityColor: Color {
        switch ticket.priority?.lowercased() {
        case "urgent":
            return .red
        case "high":
            return .orange
        case "low":
            return .blue
        default:
            return .gray
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
