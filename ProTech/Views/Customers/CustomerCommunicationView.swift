//
//  CustomerCommunicationView.swift
//  ProTech
//
//  Complete communication history and quick messaging
//

import SwiftUI
import CoreData

struct CustomerCommunicationView: View {
    @ObservedObject var customer: Customer
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    
    @FetchRequest var smsMessages: FetchedResults<SMSMessage>
    @State private var communicationLog: [CommunicationEntry] = []
    @State private var showingSMSComposer = false
    @State private var showingEmailComposer = false
    @State private var showingAddNote = false
    @State private var filterType: CommunicationType = .all
    
    init(customer: Customer) {
        self.customer = customer
        _smsMessages = FetchRequest<SMSMessage>(
            sortDescriptors: [NSSortDescriptor(keyPath: \SMSMessage.sentAt, ascending: false)],
            predicate: NSPredicate(format: "customerId == %@", customer.id! as CVarArg)
        )
    }
    
    var filteredLog: [CommunicationEntry] {
        if filterType == .all {
            return communicationLog
        }
        return communicationLog.filter { $0.type == filterType }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Communication History")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Text("\(filteredLog.count) item\(filteredLog.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            // Filter
            Picker("Filter", selection: $filterType) {
                ForEach(CommunicationType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            Divider()
            
            // Communication list
            if filteredLog.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No communication history")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredLog) { entry in
                            CommunicationCard(entry: entry)
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            // Quick actions
            HStack(spacing: 12) {
                if subscriptionManager.isProSubscriber && TwilioService.shared.isConfigured {
                    Button {
                        showingSMSComposer = true
                    } label: {
                        Label("Send SMS", systemImage: "message.fill")
                    }
                    .buttonStyle(.bordered)
                }
                
                Button {
                    showingEmailComposer = true
                } label: {
                    Label("Send Email", systemImage: "envelope.fill")
                }
                .buttonStyle(.bordered)
                
                Button {
                    showingAddNote = true
                } label: {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .onAppear {
            loadCommunicationLog()
        }
        .sheet(isPresented: $showingSMSComposer) {
            SMSComposerView(customer: customer)
        }
        .sheet(isPresented: $showingEmailComposer) {
            EmailComposerView(customer: customer)
        }
        .sheet(isPresented: $showingAddNote) {
            AddCommunicationNoteView(customer: customer) {
                loadCommunicationLog()
            }
        }
    }
    
    private func loadCommunicationLog() {
        var entries: [CommunicationEntry] = []
        
        // Add SMS messages
        for message in smsMessages {
            entries.append(CommunicationEntry(
                id: message.id ?? UUID(),
                type: .sms,
                content: message.body ?? "",
                timestamp: message.sentAt ?? Date(),
                direction: message.direction == "outbound" ? .outgoing : .incoming,
                status: message.status
            ))
        }
        
        // Add notes from customer
        if let notesData = customer.notes?.data(using: .utf8),
           let notes = try? JSONDecoder().decode([CustomerNote].self, from: notesData) {
            for note in notes {
                entries.append(CommunicationEntry(
                    id: note.id,
                    type: .note,
                    content: note.text,
                    timestamp: note.timestamp,
                    direction: .internal,
                    status: nil
                ))
            }
        }
        
        // Sort by timestamp
        communicationLog = entries.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Communication Type

enum CommunicationType: String, CaseIterable {
    case all = "all"
    case sms = "sms"
    case email = "email"
    case call = "call"
    case note = "note"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .sms: return "SMS"
        case .email: return "Email"
        case .call: return "Calls"
        case .note: return "Notes"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .sms: return "message"
        case .email: return "envelope"
        case .call: return "phone"
        case .note: return "note.text"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .blue
        case .sms: return .green
        case .email: return .orange
        case .call: return .purple
        case .note: return .gray
        }
    }
}

// MARK: - Communication Entry

struct CommunicationEntry: Identifiable {
    let id: UUID
    let type: CommunicationType
    let content: String
    let timestamp: Date
    let direction: CommunicationDirection
    let status: String?
}

enum CommunicationDirection {
    case incoming
    case outgoing
    case internal
}

// MARK: - Communication Card

struct CommunicationCard: View {
    let entry: CommunicationEntry
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: entry.type.icon)
                    .foregroundColor(entry.type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.type.displayName)
                            .font(.headline)
                        
                        if entry.direction == .outgoing {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        } else if entry.direction == .incoming {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text(entry.timestamp, format: .dateTime.month().day().year().hour().minute())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let status = entry.status {
                    Text(status.uppercased())
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor(status))
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            
            Text(entry.content)
                .font(.body)
                .lineLimit(isExpanded ? nil : 2)
        }
        .padding()
        .background(entry.type.color.opacity(0.05))
        .cornerRadius(10)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "sent", "delivered": return .green
        case "failed": return .red
        case "queued", "sending": return .orange
        default: return .gray
        }
    }
}

// MARK: - Email Composer

struct EmailComposerView: View {
    @Environment(\.dismiss) private var dismiss
    let customer: Customer
    
    @State private var subject = ""
    @State private var body = ""
    @State private var template: EmailTemplate = .custom
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    LabeledContent("To") {
                        Text(customer.email ?? "No email")
                    }
                }
                
                Section("Template") {
                    Picker("Use Template", selection: $template) {
                        ForEach(EmailTemplate.allCases, id: \.self) { template in
                            Text(template.displayName).tag(template)
                        }
                    }
                    .onChange(of: template) { _, newValue in
                        applyTemplate(newValue)
                    }
                }
                
                Section("Message") {
                    TextField("Subject", text: $subject)
                    
                    TextEditor(text: $body)
                        .frame(minHeight: 200)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Send Email")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendEmail()
                    }
                    .disabled(subject.isEmpty || body.isEmpty || customer.email == nil)
                }
            }
        }
        .frame(width: 600, height: 600)
    }
    
    private func applyTemplate(_ template: EmailTemplate) {
        let customerName = "\(customer.firstName ?? "") \(customer.lastName ?? "")"
        
        switch template {
        case .custom:
            break
        case .repairComplete:
            subject = "Your Device is Ready for Pickup"
            body = """
            Hi \(customerName),
            
            Great news! Your device repair has been completed and is ready for pickup.
            
            Please bring your ticket receipt when you come to collect your device.
            
            Thank you for choosing us!
            
            Best regards,
            \(UserDefaults.standard.string(forKey: "companyName") ?? "ProTech")
            """
        case .statusUpdate:
            subject = "Update on Your Device Repair"
            body = """
            Hi \(customerName),
            
            We wanted to give you an update on your device repair.
            
            [Add status update here]
            
            If you have any questions, please don't hesitate to contact us.
            
            Best regards,
            \(UserDefaults.standard.string(forKey: "companyName") ?? "ProTech")
            """
        case .followUp:
            subject = "How is Your Repaired Device?"
            body = """
            Hi \(customerName),
            
            We hope your repaired device is working perfectly!
            
            We'd love to hear about your experience. If you have any concerns or feedback, please let us know.
            
            Thank you for your business!
            
            Best regards,
            \(UserDefaults.standard.string(forKey: "companyName") ?? "ProTech")
            """
        }
    }
    
    private func sendEmail() {
        // Open default email client
        if let email = customer.email,
           let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            NSWorkspace.shared.open(url)
        }
        dismiss()
    }
}

enum EmailTemplate: String, CaseIterable {
    case custom = "custom"
    case repairComplete = "repair_complete"
    case statusUpdate = "status_update"
    case followUp = "follow_up"
    
    var displayName: String {
        switch self {
        case .custom: return "Custom"
        case .repairComplete: return "Repair Complete"
        case .statusUpdate: return "Status Update"
        case .followUp: return "Follow-up"
        }
    }
}

// MARK: - Add Communication Note

struct AddCommunicationNoteView: View {
    @Environment(\.dismiss) private var dismiss
    let customer: Customer
    let onSave: () -> Void
    
    @State private var noteType: CommunicationType = .note
    @State private var content = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Communication Type", selection: $noteType) {
                        ForEach([CommunicationType.note, .call, .email], id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Details") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if content.isEmpty {
                                Text("Enter details...")
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Communication")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func saveNote() {
        // Add to customer notes
        var notes: [CustomerNote] = []
        if let notesData = customer.notes?.data(using: .utf8),
           let existingNotes = try? JSONDecoder().decode([CustomerNote].self, from: notesData) {
            notes = existingNotes
        }
        
        let newNote = CustomerNote(
            id: UUID(),
            text: "[\(noteType.displayName)] \(content)",
            timestamp: Date()
        )
        notes.insert(newNote, at: 0)
        
        if let encoded = try? JSONEncoder().encode(notes),
           let jsonString = String(data: encoded, encoding: .utf8) {
            customer.notes = jsonString
            customer.updatedAt = Date()
            CoreDataManager.shared.save()
        }
        
        onSave()
        dismiss()
    }
}
