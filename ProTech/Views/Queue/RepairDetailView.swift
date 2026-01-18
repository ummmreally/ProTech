//
//  RepairDetailView.swift
//  ProTech
//
//  Comprehensive repair detail page with tabs
//

import SwiftUI
import CoreData

struct RepairDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject var ticket: Ticket
    @FetchRequest var customer: FetchedResults<Customer>
    
    @State private var selectedTab: RepairTab = .overview
    @State private var notes: String = ""
    
    // SMS integration
    @State private var showingSMSModal = false
    @State private var smsMessage = ""
    @State private var pendingStatusChange: String?
    
    @State private var currentStage: RepairStage?
    
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
        VStack(spacing: 0) {
            // Header with customer info
            headerSection
            
            // Visual Stage Tracker
            RepairStageTracker(
                currentStage: $currentStage,
                ticketStatus: ticket.status ?? "waiting"
            )
            .padding(.bottom, 8)
            .background(Color.gray.opacity(0.05))
            
            Divider()
            
            // Tab picker
            Picker("View", selection: $selectedTab) {
                ForEach(RepairTab.allCases, id: \.self) { tab in
                    Label(tab.title, systemImage: tab.icon).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Tab content
            TabView(selection: $selectedTab) {
                ForEach(RepairTab.allCases, id: \.self) { tab in
                    Group {
                        switch tab {
                        case .overview:
                            overviewTab
                        case .progress:
                            progressTab
                        case .parts:
                            partsTab
                        case .notes:
                            notesTab
                        case .timeline:
                            timelineTab
                        }
                    }
                    .tag(tab)
                }
            }
            .tabViewStyle(.automatic)
        }
        .navigationTitle("Ticket #\(ticket.ticketNumber)")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                // Status picker in toolbar
                StatusPicker(status: Binding(
                    get: { ticket.status ?? "waiting" },
                    set: { updateStatus($0) }
                ))
                
                Button {
                    printDymoLabel()
                } label: {
                    Label("Print Label", systemImage: "barcode")
                }
                
                if TwilioService.shared.isConfigured && customer.first != nil {
                    Menu {
                        Button {
                            prepareCustomSMS()
                        } label: {
                            Label("Send Custom SMS", systemImage: "message")
                        }
                        
                        if ticket.status == "in_progress" {
                            Button {
                                prepareReadyForPickupSMS()
                            } label: {
                                Label("Notify Ready for Pickup", systemImage: "checkmark.message")
                            }
                        }
                    } label: {
                        Label("SMS", systemImage: "message.fill")
                    }
                }
            }
        }
        .onAppear {
            loadCurrentStage()
        }
        .sheet(isPresented: $showingSMSModal) {
            if let customer = customer.first {
                SMSConfirmationModal(
                    isPresented: $showingSMSModal,
                    customer: customer,
                    defaultMessage: smsMessage,
                    onSend: { message in
                        sendSMS(message: message)
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                // Customer avatar and info
                VStack(alignment: .leading, spacing: 8) {
                    if let customer = customer.first {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(statusColor.gradient)
                                .frame(width: 60, height: 60)
                                .overlay {
                                    Text("\(customer.firstName?.prefix(1) ?? "")\(customer.lastName?.prefix(1) ?? "")")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(.white)
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(customer.firstName ?? "") \(customer.lastName ?? "")")
                                    .font(.title2)
                                    .bold()
                                
                                if let phone = customer.phone {
                                    Label(phone, systemImage: "phone.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                if let email = customer.email {
                                    Label(email, systemImage: "envelope.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Unknown Customer")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Ticket status badge
                VStack(alignment: .trailing, spacing: 8) {
                    StatusBadge(status: ticket.status ?? "waiting")
                    
                    if let deviceType = ticket.deviceType {
                        HStack(spacing: 4) {
                            Image(systemName: deviceIcon(deviceType))
                            Text(deviceType)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    
                    if let checkedIn = ticket.checkedInAt {
                        Text("Checked in: \(timeAgo(checkedIn))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Device Information
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Device Information", systemImage: "info.circle.fill")
                            .font(.headline)
                        
                        if let deviceType = ticket.deviceType {
                            DetailInfoRow(label: "Type", value: deviceType, icon: deviceIcon(deviceType))
                        }
                        
                        if let model = ticket.deviceModel {
                            DetailInfoRow(label: "Model", value: model, icon: "cpu")
                        }
                        
                        if let serialNumber = ticket.deviceSerialNumber {
                            DetailInfoRow(label: "Serial Number", value: serialNumber, icon: "number")
                        }
                    }
                }
                
                // Issue Description
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Issue Description", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                        
                        Text(ticket.issueDescription ?? "No description provided")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Timestamps
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Timeline", systemImage: "clock.fill")
                            .font(.headline)
                        
                        if let checkedIn = ticket.checkedInAt {
                            DetailInfoRow(label: "Checked In", value: checkedIn.formatted(date: .abbreviated, time: .shortened), icon: "calendar")
                        }
                        
                        if let started = ticket.startedAt {
                            DetailInfoRow(label: "Work Started", value: started.formatted(date: .abbreviated, time: .shortened), icon: "play.fill")
                        }
                        
                        if let completed = ticket.completedAt {
                            DetailInfoRow(label: "Completed", value: completed.formatted(date: .abbreviated, time: .shortened), icon: "checkmark.circle.fill")
                        }
                        
                        if let pickedUp = ticket.pickedUpAt {
                            DetailInfoRow(label: "Picked Up", value: pickedUp.formatted(date: .abbreviated, time: .shortened), icon: "hand.thumbsup.fill")
                        }
                        
                        if let estimated = ticket.estimatedCompletion {
                            DetailInfoRow(label: "Est. Completion", value: estimated.formatted(date: .abbreviated, time: .shortened), icon: "timer")
                        }
                    }
                }
                
                // Quick Actions
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Quick Actions", systemImage: "bolt.fill")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            if ticket.status == "waiting" {
                                Button {
                                    updateStatus("in_progress")
                                } label: {
                                    Label("Start Work", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            if ticket.status == "in_progress" {
                                Button {
                                    if TwilioService.shared.isConfigured && customer.first?.phone != nil {
                                        prepareReadyForPickupSMS()
                                    } else {
                                        updateStatus("completed")
                                    }
                                } label: {
                                    Label("Mark Complete", systemImage: "checkmark.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.green)
                            }
                            
                            if ticket.status == "completed" {
                                Button {
                                    updateStatus("picked_up")
                                } label: {
                                    Label("Picked Up", systemImage: "hand.thumbsup.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.blue)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Progress Tab
    
    private var progressTab: some View {
        RepairProgressView(ticket: ticket)
    }
    
    // MARK: - Parts Tab
    
    private var partsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Parts used from inventory
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Parts Used", systemImage: "wrench.and.screwdriver.fill")
                                .font(.headline)
                            
                            Spacer()
                            
                            if ticket.id != nil {
                                NavigationLink {
                                    if let ticketId = ticket.id {
                                        PartsPickerView(ticketId: ticketId, ticketNumber: ticket.ticketNumber)
                                    }
                                } label: {
                                    Label("Add Parts", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                }
                            }
                        }
                        
                        if let ticketId = ticket.id {
                            PartsUsedList(ticketId: ticketId)
                        } else {
                            Text("No parts added yet")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Time tracking
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Time Tracking", systemImage: "timer")
                            .font(.headline)
                        
                        if ticket.id != nil {
                            TimerControlPanel(ticket: ticket)
                        } else {
                            Text("Save ticket to enable time tracking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let ticketId = ticket.id,
                           TimeTrackingService.shared.hasActiveTimer(for: ticketId) {
                            CompactTimerWidget()
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Notes Tab
    
    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add New Note")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $notes)
                    .font(.body)
                    .padding(8)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(8)
                    .frame(height: 100)
                
                HStack {
                    Text("Type your note here...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button {
                        addNote()
                    } label: {
                        Label("Add Note", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.vertical, 8)
            
            // Notes History
            Text("Notes History")
                .font(.headline)
                .padding(.horizontal)
            
            if let ticketId = ticket.id {
                NotesHistoryList(ticketId: ticketId)
            } else {
                Text("No notes yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Timeline Tab
    
    private var timelineTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Repair Timeline")
                    .font(.headline)
                
                // Timeline events
                VStack(alignment: .leading, spacing: 20) {
                    if let checkedIn = ticket.checkedInAt {
                        TimelineEvent(
                            title: "Customer Checked In",
                            date: checkedIn,
                            icon: "person.badge.plus",
                            color: .blue
                        )
                    }
                    
                    if let started = ticket.startedAt {
                        TimelineEvent(
                            title: "Work Started",
                            date: started,
                            icon: "play.fill",
                            color: .purple
                        )
                    }
                    
                    if let completed = ticket.completedAt {
                        TimelineEvent(
                            title: "Repair Completed",
                            date: completed,
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    
                    if let pickedUp = ticket.pickedUpAt {
                        TimelineEvent(
                            title: "Device Picked Up",
                            date: pickedUp,
                            icon: "hand.thumbsup.fill",
                            color: .orange
                        )
                    }
                }
                
                // SMS history if available
                if let ticketId = ticket.id {
                    Divider()
                        .padding(.vertical)
                    
                    Text("SMS History")
                        .font(.headline)
                    
                    SMSHistoryList(ticketId: ticketId)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    
    private var statusColor: Color {
        TicketStatus(rawValue: ticket.status ?? "waiting")?.color ?? .gray
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
        
        if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
    
    private func updateStatus(_ newStatus: String) {
        ticket.status = newStatus
        ticket.updatedAt = Date()
        ticket.cloudSyncStatus = "pending"
        
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
        
        // Sync to Supabase in background
        Task { @MainActor in
            do {
                let syncer = TicketSyncer()
                try await syncer.upload(ticket)
                ticket.cloudSyncStatus = "synced"
                try? CoreDataManager.shared.viewContext.save()
            } catch {
                ticket.cloudSyncStatus = "failed"
                try? CoreDataManager.shared.viewContext.save()
                print("⚠️ Ticket sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveNotes() {
        ticket.notes = notes
        ticket.updatedAt = Date()
        CoreDataManager.shared.save()
    }
    
    private func addNote() {
        guard let ticketId = ticket.id else { return }
        
        let trimmedNote = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }
        
        let ticketNote = TicketNote(context: viewContext)
        ticketNote.id = UUID()
        ticketNote.ticketId = ticketId
        ticketNote.content = trimmedNote
        ticketNote.technicianName = getCurrentTechnicianName()
        ticketNote.createdAt = Date()
        
        // Also update the main ticket notes field with the latest note
        ticket.notes = trimmedNote
        ticket.updatedAt = Date()
        
        CoreDataManager.shared.save()
        
        // Clear the text field
        notes = ""
    }
    
    private func getCurrentTechnicianName() -> String {
        return authService.currentEmployeeName
    }
    
    private func loadCurrentStage() {
        // Map ticket status to repair stage for the visual tracker
        if let status = ticket.status {
            switch status {
            case "waiting":
                currentStage = .diagnostic
            case "diagnosing":
                currentStage = .diagnostic
            case "in_progress":
                currentStage = .repair
            case "testing":
                currentStage = .testing
            case "completed":
                currentStage = .qualityCheck
            case "picked_up":
                currentStage = .cleanup
            default:
                currentStage = .diagnostic
            }
        } else {
            currentStage = .diagnostic
        }
    }
    
    private func printDymoLabel() {
        // Print the device label using ticket information
        DymoPrintService.shared.printDeviceLabel(
            ticket: ticket,
            customer: customer.first
        )
    }
    
    // MARK: - SMS Functions
    
    private func prepareReadyForPickupSMS() {
        guard let customer = customer.first else { return }
        
        let customerName = customer.firstName ?? "Customer"
        let deviceType = ticket.deviceType ?? "device"
        
        smsMessage = SMSConfirmationModal.readyForPickupMessage(
            customerName: customerName,
            ticketNumber: ticket.ticketNumber,
            deviceType: deviceType
        )
        pendingStatusChange = "completed"
        showingSMSModal = true
    }
    
    private func prepareCustomSMS() {
        guard let customer = customer.first else { return }
        
        let customerName = customer.firstName ?? "Customer"
        smsMessage = "Hi \(customerName), "
        pendingStatusChange = nil
        showingSMSModal = true
    }
    
    private func sendSMS(message: String) {
        guard let customer = customer.first,
              let phone = customer.phone else {
            return
        }
        
        Task {
            do {
                let result = try await TwilioService.shared.sendSMS(to: phone, body: message)
                
                // Save to database
                await saveSMSToDatabase(result: result, customerId: customer.id)
                
                // Update status if pending
                await MainActor.run {
                    if let newStatus = pendingStatusChange {
                        updateStatus(newStatus)
                        pendingStatusChange = nil
                    }
                }
                
            } catch {
                print("SMS Error: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveSMSToDatabase(result: SMSResult, customerId: UUID?) async {
        let context = CoreDataManager.shared.viewContext
        
        await context.perform {
            let smsMessage = SMSMessage(context: context)
            smsMessage.id = UUID()
            smsMessage.customerId = customerId
            smsMessage.ticketId = self.ticket.id
            smsMessage.direction = "outbound"
            smsMessage.body = result.body
            smsMessage.status = result.status
            smsMessage.twilioSid = result.sid
            smsMessage.sentAt = Date()
            
            try? context.save()
        }
    }
}

// MARK: - Repair Tab Enum

enum RepairTab: String, CaseIterable {
    case overview = "Overview"
    case progress = "Progress"
    case parts = "Parts"
    case notes = "Notes"
    case timeline = "Timeline"
    
    var title: String {
        self.rawValue
    }
    
    var icon: String {
        switch self {
        case .overview: return "info.circle"
        case .progress: return "chart.line.uptrend.xyaxis"
        case .parts: return "wrench.and.screwdriver"
        case .notes: return "note.text"
        case .timeline: return "clock.arrow.circlepath"
        }
    }
}

// MARK: - Supporting Views

struct DetailInfoRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .bold()
        }
        .font(.subheadline)
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " ").uppercased())
            .font(.caption)
            .bold()
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    var backgroundColor: Color {
        switch status.lowercased() {
        case "waiting":
            return .orange
        case "in_progress":
            return .purple
        case "completed":
            return .green
        case "picked_up":
            return .gray
        default:
            return .blue
        }
    }
}

struct TimelineEvent: View {
    let title: String
    let date: Date
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.caption)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SMSHistoryList: View {
    @FetchRequest var messages: FetchedResults<SMSMessage>
    
    init(ticketId: UUID) {
        _messages = FetchRequest<SMSMessage>(
            sortDescriptors: [NSSortDescriptor(keyPath: \SMSMessage.sentAt, ascending: false)],
            predicate: NSPredicate(format: "ticketId == %@", ticketId as CVarArg)
        )
    }
    
    var body: some View {
        if messages.isEmpty {
            Text("No SMS messages sent")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(messages.prefix(10)) { message in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: message.direction == "outbound" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .foregroundColor(message.direction == "outbound" ? .blue : .green)
                            
                            Text(message.direction == "outbound" ? "Sent" : "Received")
                                .font(.caption)
                                .bold()
                            
                            Spacer()
                            
                            if let sentAt = message.sentAt {
                                Text(sentAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(message.body ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct NotesHistoryList: View {
    @FetchRequest var notes: FetchedResults<TicketNote>
    
    init(ticketId: UUID) {
        _notes = FetchRequest<TicketNote>(
            sortDescriptors: [NSSortDescriptor(keyPath: \TicketNote.createdAt, ascending: false)],
            predicate: NSPredicate(format: "ticketId == %@", ticketId as CVarArg)
        )
    }
    
    var body: some View {
        ScrollView {
            if notes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No notes yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(notes) { note in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Circle()
                                    .fill(Color.blue.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        Text(note.technicianName?.prefix(1).uppercased() ?? "T")
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.white)
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(note.technicianName ?? "Unknown")
                                        .font(.subheadline)
                                        .bold()
                                    
                                    if let createdAt = note.createdAt {
                                        Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            Text(note.content ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.blue.opacity(0.05))
                                .cornerRadius(8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
