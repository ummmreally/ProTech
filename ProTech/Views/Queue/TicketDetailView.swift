//
//  TicketDetailView.swift
//  ProTech
//
//  Detailed view for a service ticket
//

import SwiftUI
import CoreData

struct TicketDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ticket: Ticket
    
    @FetchRequest var customer: FetchedResults<Customer>
    @State private var showingStatusUpdate = false
    @State private var newStatus: String = ""
    @State private var notes: String = ""
    
    init(ticket: Ticket) {
        self.ticket = ticket
        if let customerId = ticket.customerId {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", customerId as CVarArg)
            )
        } else {
            _customer = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
        _notes = State(initialValue: ticket.notes ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Customer Info
                Section("Customer") {
                    if let customer = customer.first {
                        LabeledContent("Name") {
                            Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                        }
                        if let phone = customer.phone {
                            LabeledContent("Phone") {
                                Text(phone)
                            }
                        }
                        if let email = customer.email {
                            LabeledContent("Email") {
                                Text(email)
                            }
                        }
                    }
                }
                
                // Ticket Info
                Section("Ticket Information") {
                    LabeledContent("Ticket #") {
                        Text(ticket.ticketNumber == 0 ? "—" : "\(ticket.ticketNumber)")
                            .font(.headline)
                    }

                    LabeledContent("Status") {
                        StatusPicker(status: Binding(
                            get: { ticket.status ?? "waiting" },
                            set: { updateStatus($0) }
                        ))
                    }
                    
                    LabeledContent("Priority") {
                        Text(Priority(rawValue: ticket.priority ?? "normal")?.displayName ?? "Normal")
                            .foregroundColor(Priority(rawValue: ticket.priority ?? "normal")?.color ?? .blue)
                    }
                    
                    if let checkedIn = ticket.checkedInAt {
                        LabeledContent("Checked In") {
                            Text(checkedIn, format: .dateTime.month().day().hour().minute())
                        }
                    }
                    
                    if let estimated = ticket.estimatedCompletion {
                        LabeledContent("Est. Completion") {
                            Text(estimated, format: .dateTime.month().day().hour().minute())
                        }
                    }
                }
                
                // Device Info
                Section("Device") {
                    if let deviceType = ticket.deviceType {
                        LabeledContent("Type") {
                            HStack {
                                Image(systemName: deviceIcon(deviceType))
                                Text(deviceType)
                            }
                        }
                    }
                    
                    if let model = ticket.deviceModel {
                        LabeledContent("Model") {
                            Text(model)
                        }
                    }
                }
                
                // Issue Description
                Section("Issue Description") {
                    Text(ticket.issueDescription ?? "No description provided")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Notes
                Section("Technician Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                    
                    Button("Save Notes") {
                        saveNotes()
                    }
                    .disabled(notes == ticket.notes)
                }
                
                // Actions
                Section("Actions") {
                    if ticket.status == "waiting" {
                        Button {
                            updateStatus("in_progress")
                        } label: {
                            Label("Start Working", systemImage: "play.fill")
                        }
                    }
                    
                    if ticket.status == "in_progress" {
                        Button {
                            updateStatus("completed")
                        } label: {
                            Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                        }
                    }
                    
                    if ticket.status == "completed" {
                        Button {
                            updateStatus("picked_up")
                        } label: {
                            Label("Customer Picked Up", systemImage: "hand.thumbsup.fill")
                        }
                    }
                    
                    Button(role: .destructive) {
                        deleteTicket()
                    } label: {
                        Label("Delete Ticket", systemImage: "trash")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Ticket Details")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 700)
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
    
    private func updateStatus(_ newStatus: String) {
        ticket.status = newStatus
        ticket.updatedAt = Date()
        
        if newStatus == "in_progress" && ticket.startedAt == nil {
            ticket.startedAt = Date()
        }
        
        if newStatus == "completed" && ticket.completedAt == nil {
            ticket.completedAt = Date()
        }
        
        if newStatus == "picked_up" && ticket.pickedUpAt == nil {
            ticket.pickedUpAt = Date()
        }
        
        CoreDataManager.shared.save()
    }
    
    private func saveNotes() {
        ticket.notes = notes
        ticket.updatedAt = Date()
        CoreDataManager.shared.save()
    }
    
    private func deleteTicket() {
        CoreDataManager.shared.viewContext.delete(ticket)
        CoreDataManager.shared.save()
        dismiss()
    }
}

// MARK: - Status Picker

struct StatusPicker: View {
    @Binding var status: String
    
    var body: some View {
        Picker("Status", selection: $status) {
            ForEach([TicketStatus.waiting, .inProgress, .completed, .pickedUp], id: \.rawValue) { ticketStatus in
                HStack {
                    Image(systemName: ticketStatus.icon)
                    Text(ticketStatus.displayName)
                }
                .tag(ticketStatus.rawValue)
            }
        }
        .pickerStyle(.menu)
    }
}
