//
//  CheckInQueueView.swift
//  ProTech
//
//  Check-in queue for customers who checked in via portal
//

import SwiftUI
import CoreData

struct CheckInQueueView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CheckIn.checkedInAt, ascending: true)],
        predicate: NSPredicate(format: "status == %@", "waiting"),
        animation: .default
    ) private var waitingCheckIns: FetchedResults<CheckIn>
    
    @State private var selectedCheckIn: CheckIn?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customer Check-In Queue")
                        .font(.largeTitle)
                        .bold()
                    Text("\(waitingCheckIns.count) customer\(waitingCheckIns.count == 1 ? "" : "s") waiting")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh button
                Button {
                    viewContext.refreshAllObjects()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Queue List
            if waitingCheckIns.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("No customers waiting")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Customers who check in from the portal will appear here")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(waitingCheckIns) { checkIn in
                            CheckInCard(
                                checkIn: checkIn,
                                onStartRepair: {
                                    selectedCheckIn = checkIn
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(item: $selectedCheckIn) { checkIn in
            StartRepairFromCheckInView(checkIn: checkIn) {
                selectedCheckIn = nil
            }
        }
    }
}

// MARK: - Check-In Card

struct CheckInCard: View {
    @ObservedObject var checkIn: CheckIn
    @FetchRequest var customer: FetchedResults<Customer>
    let onStartRepair: () -> Void
    
    init(checkIn: CheckIn, onStartRepair: @escaping () -> Void) {
        self.checkIn = checkIn
        self.onStartRepair = onStartRepair
        _customer = FetchRequest<Customer>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", checkIn.customerId! as CVarArg)
        )
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Customer Avatar/Icon
            VStack {
                Circle()
                    .fill(Color.blue.gradient)
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
            }
            
            // Customer & Device Info
            VStack(alignment: .leading, spacing: 8) {
                if let customer = customer.first {
                    Text(customer.displayName)
                        .font(.title3)
                        .bold()
                    
                    if let email = customer.email {
                        HStack(spacing: 4) {
                            Image(systemName: "envelope.fill")
                                .font(.caption)
                            Text(email)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if let phone = customer.phone {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .font(.caption)
                            Text(phone)
                                .font(.subheadline)
                        }
                        .foregroundColor(.secondary)
                    }
                } else {
                    Text("Unknown Customer")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let device = checkIn.deviceType {
                    HStack(spacing: 4) {
                        Image(systemName: deviceIcon(device))
                            .font(.subheadline)
                        Text(device)
                            .font(.subheadline)
                        if let model = checkIn.deviceModel {
                            Text("• \(model)")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(.blue)
                }
                
                if let issue = checkIn.issueDescription {
                    Text(issue)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            // Time & Action
            VStack(alignment: .trailing, spacing: 12) {
                if let checkedIn = checkIn.checkedInAt {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Checked in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(timeAgo(checkedIn))
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text(checkedIn, format: .dateTime.hour().minute())
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button {
                    onStartRepair()
                } label: {
                    Label("Start Repair", systemImage: "wrench.and.screwdriver.fill")
                        .font(.subheadline)
                        .bold()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
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
    
    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        
        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
}

// MARK: - Start Repair Form

struct StartRepairFromCheckInView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var checkIn: CheckIn
    @FetchRequest var customer: FetchedResults<Customer>
    let onComplete: () -> Void
    
    @State private var deviceType: String
    @State private var deviceModel: String
    @State private var issueDescription: String
    @State private var priority: String = "normal"
    @State private var estimatedCompletion: Date = Date().addingTimeInterval(3600 * 24)
    @State private var isCreating = false
    
    init(checkIn: CheckIn, onComplete: @escaping () -> Void) {
        self.checkIn = checkIn
        self.onComplete = onComplete
        _customer = FetchRequest<Customer>(
            sortDescriptors: [],
            predicate: NSPredicate(format: "id == %@", checkIn.customerId! as CVarArg)
        )
        _deviceType = State(initialValue: checkIn.deviceType ?? "")
        _deviceModel = State(initialValue: checkIn.deviceModel ?? "")
        _issueDescription = State(initialValue: checkIn.issueDescription ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Customer") {
                    if let customer = customer.first {
                        LabeledContent("Name", value: customer.displayName)
                        if let email = customer.email {
                            LabeledContent("Email", value: email)
                        }
                        if let phone = customer.phone {
                            LabeledContent("Phone", value: phone)
                        }
                    }
                }
                
                Section("Device") {
                    TextField("Device Type", text: $deviceType)
                    TextField("Device Model", text: $deviceModel)
                }
                
                Section("Repair Details") {
                    TextField("Issue Description", text: $issueDescription, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag("low")
                        Text("Normal").tag("normal")
                        Text("High").tag("high")
                        Text("Urgent").tag("urgent")
                    }
                    
                    DatePicker("Estimated Completion", selection: $estimatedCompletion, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(footer: Text("A new repair ticket will be created for this check-in.")) {
                    Button {
                        createTicket()
                    } label: {
                        if isCreating {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Creating Repair...")
                            }
                        } else {
                            Text("Create Repair")
                        }
                    }
                    .disabled(isCreating || deviceType.isEmpty || issueDescription.isEmpty)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Start Repair")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .frame(width: 600, height: 520)
    }
    
    private func createTicket() {
        guard let customerId = checkIn.customerId else { return }
        
        isCreating = true
        
        // Create new ticket
        let ticket = Ticket(context: viewContext)
        ticket.id = UUID()
        ticket.customerId = customerId
        ticket.deviceType = deviceType
        ticket.deviceModel = deviceModel
        ticket.issueDescription = issueDescription
        ticket.status = "in_progress"
        ticket.priority = priority
        ticket.checkedInAt = checkIn.checkedInAt
        ticket.startedAt = Date()
        ticket.estimatedCompletion = estimatedCompletion
        ticket.createdAt = Date()
        ticket.updatedAt = Date()
        ticket.cloudSyncStatus = "pending"
        
        // Get next ticket number
        let fetchRequest: NSFetchRequest<Ticket> = Ticket.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Ticket.ticketNumber, ascending: false)]
        fetchRequest.fetchLimit = 1
        
        if let lastTicket = try? viewContext.fetch(fetchRequest).first {
            ticket.ticketNumber = lastTicket.ticketNumber + 1
        } else {
            ticket.ticketNumber = 1001
        }
        
        // Update check-in status
        checkIn.status = "started"
        checkIn.ticketId = ticket.id
        
        do {
            try viewContext.save()
            
            // Sync to Supabase in background
            Task { @MainActor in
                do {
                    let syncer = TicketSyncer()
                    try await syncer.upload(ticket)
                    ticket.cloudSyncStatus = "synced"
                    try? viewContext.save()
                } catch {
                    ticket.cloudSyncStatus = "failed"
                    try? viewContext.save()
                    print("⚠️ Ticket sync failed: \(error.localizedDescription)")
                }
            }
            
            isCreating = false
            onComplete()
        } catch {
            print("Error creating ticket: \(error)")
            isCreating = false
        }
    }
}

#Preview {
    CheckInQueueView()
}
