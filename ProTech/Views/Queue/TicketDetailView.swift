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
    @EnvironmentObject var authService: AuthenticationService
    @ObservedObject var ticket: Ticket
    
    @FetchRequest var customer: FetchedResults<Customer>
    @State private var showingStatusUpdate = false
    @State private var newStatus: String = ""
    @State private var notes: String = ""
    
    // Barcode integration
    @State private var showingBarcodeScanner = false
    @State private var showingBarcodePrint = false
    
    // Time tracking integration
    @State private var showingTimerWidget = false
    
    // Parts/Inventory integration
    @State private var showingPartsSelector = false
    
    // SMS integration
    @State private var showingSMSModal = false
    @State private var smsMessage = ""
    @State private var pendingStatusChange: String?
    @State private var showingSMSError = false
    @State private var smsErrorMessage = ""
    
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
                // Time Tracking Widget (if timer is active)
                if let ticketId = ticket.id,
                   TimeTrackingService.shared.hasActiveTimer(for: ticketId) {
                    Section {
                        CompactTimerWidget()
                    }
                }
                
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
                
                // Warranty Section
                Section("Warranty") {
                    let status = WarrantyService.shared.getWarrantyStatus(for: ticket)
                    
                    switch status {
                    case .active(let daysRemaining):
                        LabeledContent("Status") {
                            HStack {
                                Image(systemName: "checkmark.shield.fill")
                                    .foregroundColor(.green)
                                Text("Active (\(daysRemaining) days left)")
                                    .foregroundColor(.green)
                            }
                        }
                    case .expired(let expiredOn):
                        LabeledContent("Status") {
                            HStack {
                                Image(systemName: "xmark.shield.fill")
                                    .foregroundColor(.red)
                                Text("Expired on \(expiredOn.formatted(date: .abbreviated, time: .omitted))")
                                    .foregroundColor(.secondary)
                            }
                        }
                    case .none:
                       if ticket.status == "completed" || ticket.status == "picked_up" {
                           Button("Activate 90-Day Warranty") {
                               WarrantyService.shared.activateWarranty(for: ticket, durationDays: 90)
                           }
                           .font(.caption)
                       } else {
                           Text("Warranty applies after completion")
                               .foregroundColor(.secondary)
                       }
                    }
                    
                    if ticket.warrantyDurationDays > 0 {
                         LabeledContent("Duration", value: "\(ticket.warrantyDurationDays) Days")
                    }
                }
                
                // Device Info
                Section("Device") {
                    if let device = ticket.deviceType {
                        LabeledContent("Type", value: device)
                    }
                    if let model = ticket.deviceModel {
                        LabeledContent("Model", value: model)
                    }
                    
                    // Sync status
                    if let syncStatus = ticket.cloudSyncStatus {
                        LabeledContent("Sync Status") {
                            syncStatusBadge(for: syncStatus)
                        }
                    }
                }
                
                // Issue Description
                Section("Issue Description") {
                    Text(ticket.issueDescription ?? "No description provided")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Notes
                Section("Add New Note") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                    
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
                        .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                // Notes History
                Section("Notes History") {
                    if let ticketId = ticket.id {
                        NotesHistoryList(ticketId: ticketId)
                            .frame(height: 200)
                    } else {
                        Text("No notes yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Time Tracking Section
                Section("Time Tracking") {
                    if ticket.id != nil {
                        TimerControlPanel(ticket: ticket)
                    } else {
                        Text("Save ticket to enable time tracking")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Parts & Inventory
                Section("Parts & Inventory") {
                    Button {
                        showingPartsSelector = true
                    } label: {
                        Label("Add Parts Used", systemImage: "wrench.and.screwdriver")
                    }
                    
                    // Show parts already used for this ticket
                    if let ticketId = ticket.id {
                        PartsUsedList(ticketId: ticketId)
                    }
                }
                
                // Quality Control
                QualityControlSection(ticket: ticket)
                
                // Barcode Actions
                Section("Barcode") {
                    Button {
                        showingBarcodePrint = true
                    } label: {
                        Label("Print Ticket Label", systemImage: "barcode")
                    }
                    
                    if ticket.ticketNumber != 0 {
                        HStack {
                            Text("Ticket #\(ticket.ticketNumber)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "qrcode")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Print Documents
                Section("Print Documents") {
                    Button {
                        printCheckInAgreement()
                    } label: {
                        Label("Print Check-In Agreement", systemImage: "doc.text.fill")
                    }
                    
                    Button {
                        printPickupForm()
                    } label: {
                        Label("Print Pickup Form", systemImage: "doc.text.fill")
                    }
                }
                
                // Actions
                Section("Actions") {
                    if ticket.status == "waiting" {
                        Button {
                            updateStatus("in_progress")
                        } label: {
                            Label("Start Working", systemImage: "play.fill")
                        }
                        
                        // Option to notify customer work is starting
                        if TwilioService.shared.isConfigured && customer.first?.phone != nil {
                            Button {
                                prepareWorkStartedSMS()
                            } label: {
                                Label("Notify Work Started", systemImage: "message.fill")
                            }
                        }
                    }
                    
                    if ticket.status == "in_progress" {
                        Button {
                            // Check if SMS should be sent
                            if TwilioService.shared.isConfigured && customer.first?.phone != nil {
                                prepareReadyForPickupSMS()
                            } else {
                                updateStatus("completed")
                            }
                        } label: {
                            Label("Mark as Completed", systemImage: "checkmark.circle.fill")
                        }
                    }
                    
                    if ticket.status == "completed" {
                        Button {
                            printPickupForm()
                        } label: {
                            Label("Print Pickup Form", systemImage: "printer.fill")
                        }
                        
                        Button {
                            updateStatus("picked_up")
                        } label: {
                            Label("Customer Picked Up", systemImage: "hand.thumbsup.fill")
                        }
                        
                        // Option to resend pickup notification
                        if TwilioService.shared.isConfigured && customer.first?.phone != nil {
                            Button {
                                prepareReadyForPickupSMS()
                            } label: {
                                Label("Send Pickup Reminder", systemImage: "message.badge.fill")
                            }
                        }
                    }
                    
                    // Send custom SMS option for any status
                    if TwilioService.shared.isConfigured && customer.first != nil {
                        Divider()
                        Button {
                            prepareCustomSMS()
                        } label: {
                            Label("Send Custom SMS", systemImage: "text.bubble")
                        }
                    }
                    
                    Divider()
                    
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
                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            printDymoLabel()
                        } label: {
                            Label("Print Dymo Label", systemImage: "printer.fill")
                        }
                        
                        Button {
                            showingBarcodePrint = true
                        } label: {
                            Label("Show Barcode", systemImage: "barcode")
                        }
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 600, height: 800)
        .sheet(isPresented: $showingPartsSelector) {
            if let ticketId = ticket.id {
                PartsPickerView(ticketId: ticketId, ticketNumber: ticket.ticketNumber)
            }
        }
        .sheet(isPresented: $showingBarcodePrint) {
            BarcodePrintView(ticket: ticket)
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
        .alert("SMS Error", isPresented: $showingSMSError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(smsErrorMessage)
        }
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
        
        NotificationManager.shared.post(
            title: "Status Updated",
            message: "Ticket #\(ticket.ticketNumber) moved to \(newStatus.replacingOccurrences(of: "_", with: " ").capitalized)",
            type: .info
        )
        
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
    
    // ...
    
    private func addNote() {
        guard let ticketId = ticket.id else { return }
        
        let trimmedNote = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNote.isEmpty else { return }
        
        let context = CoreDataManager.shared.viewContext
        let ticketNote = TicketNote(context: context)
        ticketNote.id = UUID()
        ticketNote.ticketId = ticketId
        ticketNote.content = trimmedNote
        ticketNote.technicianName = getCurrentTechnicianName()
        ticketNote.createdAt = Date()
        
        // Also update the main ticket notes field with the latest note
        ticket.notes = trimmedNote
        ticket.updatedAt = Date()
        
        CoreDataManager.shared.save()
        
        NotificationManager.shared.post(title: "Note Added", message: "Note added to Ticket #\(ticket.ticketNumber)", type: .success)
        
        // Clear the text field
        notes = ""
    }
    
    // ...
    
    private func deleteTicket() {
        let number = ticket.ticketNumber
        CoreDataManager.shared.viewContext.delete(ticket)
        CoreDataManager.shared.save()
        NotificationManager.shared.post(title: "Ticket Deleted", message: "Ticket #\(number) deleted", type: .warning)
        dismiss()
    }
    
    private func syncStatusBadge(for status: String) -> some View {
        HStack(spacing: 4) {
            switch status {
            case "synced":
                Image(systemName: "checkmark.icloud.fill")
                    .foregroundColor(.green)
                Text("Synced")
                    .foregroundColor(.green)
            case "pending":
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.orange)
                Text("Syncing...")
                    .foregroundColor(.orange)
            case "failed":
                Image(systemName: "exclamationmark.icloud.fill")
                    .foregroundColor(.red)
                Text("Sync Failed")
                    .foregroundColor(.red)
                Button("Retry") {
                    retrySyncTicket()
                }
                .buttonStyle(.link)
                .font(.caption)
            default:
                EmptyView()
            }
        }
        .font(.caption)
    }
    
    private func retrySyncTicket() {
        ticket.cloudSyncStatus = "pending"
        CoreDataManager.shared.save()
        
        Task { @MainActor in
            do {
                let syncer = TicketSyncer()
                try await syncer.upload(ticket)
                ticket.cloudSyncStatus = "synced"
                try? CoreDataManager.shared.viewContext.save()
            } catch {
                ticket.cloudSyncStatus = "failed"
                try? CoreDataManager.shared.viewContext.save()
                print("⚠️ Ticket sync retry failed: \(error.localizedDescription)")
            }
        }
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
    
    private func prepareWorkStartedSMS() {
        guard let customer = customer.first else { return }
        
        let customerName = customer.firstName ?? "Customer"
        let deviceType = ticket.deviceType ?? "device"
        
        smsMessage = SMSConfirmationModal.repairStartedMessage(
            customerName: customerName,
            deviceType: deviceType
        )
        pendingStatusChange = nil
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
            smsErrorMessage = "Customer phone number not found."
            showingSMSError = true
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
                
            } catch let error as TwilioError {
                await MainActor.run {
                    smsErrorMessage = error.errorDescription ?? "Unknown error"
                    showingSMSError = true
                }
            } catch {
                await MainActor.run {
                    smsErrorMessage = error.localizedDescription
                    showingSMSError = true
                }
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
    
    // MARK: - Printing
    
    private func printCheckInAgreement() {
        // Use PrintService to generate/print PDF
        if let customer = customer.first {
             PDFService.shared.generateAndPrintCheckInAgreement(ticket: ticket, customer: customer)
        }
    }
    
    private func printPickupForm() {
        if let customer = customer.first {
            PDFService.shared.generateAndPrintPickupForm(ticket: ticket, customer: customer)
        }
    }
    
    private func printDymoLabel() {
        DymoPrintService.shared.printDeviceLabel(
            ticket: ticket,
            customer: customer.first
        )
    }
    
    private func getCurrentTechnicianName() -> String {
        return authService.currentEmployeeName
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

// MARK: - Parts Used List

struct PartsUsedList: View {
    @FetchRequest var adjustments: FetchedResults<StockAdjustment>
    
    init(ticketId: UUID) {
        _adjustments = FetchRequest<StockAdjustment>(
            sortDescriptors: [NSSortDescriptor(keyPath: \StockAdjustment.createdAt, ascending: false)],
            predicate: NSPredicate(format: "reference CONTAINS[c] %@", ticketId.uuidString)
        )
    }
    
    var body: some View {
        if adjustments.isEmpty {
            Text("No parts used yet")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            ForEach(adjustments.prefix(5)) { adjustment in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(adjustment.itemName ?? "Unknown Part")
                            .font(.subheadline)
                        Text("Qty: \(abs(adjustment.quantityChange))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Parts Picker View

struct PartsPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let ticketId: UUID
    let ticketNumber: Int32
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var items: FetchedResults<InventoryItem>
    
    @State private var selectedItems: [UUID: Int] = [:]
    @State private var searchText = ""
    
    var filteredItems: [InventoryItem] {
        if searchText.isEmpty {
            return Array(items)
        }
        return items.filter {
            ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            ($0.partNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search parts...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding()
                
                // Parts List
                List {
                    ForEach(filteredItems, id: \.id) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name ?? "Unknown")
                                    .font(.headline)
                                HStack {
                                    Text("Stock: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(item.isLowStock ? .orange : .secondary)
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(item.partNumber ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if let itemId = item.id {
                                let maxQty = max(0, Int(item.quantity))
                                if maxQty > 0 {
                                    Stepper("Qty: \(selectedItems[itemId] ?? 0)",
                                           value: Binding(
                                            get: { selectedItems[itemId] ?? 0 },
                                            set: { selectedItems[itemId] = max(0, min($0, maxQty)) }
                                           ),
                                           in: 0...maxQty)
                                    .frame(width: 150)
                                } else {
                                    Text("Qty: 0 (Out of Stock)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 150)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Parts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Parts") {
                        addParts()
                    }
                    .disabled(selectedItems.values.allSatisfy { $0 == 0 })
                }
            }
        }
        .frame(width: 600, height: 500)
    }
    
    private func addParts() {
        for (itemId, quantity) in selectedItems where quantity > 0 {
            InventoryService.shared.usePartForTicket(
                itemId: itemId,
                quantity: quantity,
                ticketNumber: ticketNumber
            )
        }
        dismiss()
    }
}

// MARK: - Barcode Print View

struct BarcodePrintView: View {
    @Environment(\.dismiss) private var dismiss
    let ticket: Ticket
    
    @State private var barcodeImage: NSImage?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = barcodeImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 100)
                } else {
                    ProgressView("Generating barcode...")
                }
                
                VStack(spacing: 8) {
                    Text("Ticket #\(ticket.ticketNumber)")
                        .font(.title2)
                        .bold()
                    
                    if let customer = ticket.customerId {
                        Text("Customer: \(customer.uuidString.prefix(8))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let device = ticket.deviceType {
                        Text(device)
                            .font(.subheadline)
                    }
                }
                
                Button {
                    printBarcode()
                } label: {
                    Label("Print Label", systemImage: "printer")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("Ticket Label")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 400, height: 350)
        .onAppear {
            generateBarcode()
        }
    }
    
    private func generateBarcode() {
        let barcodeString = String(format: "T%05d", ticket.ticketNumber)
        barcodeImage = BarcodeGenerator.shared.generateBarcode(from: barcodeString, type: .code128)
    }
    
    private func printBarcode() {
        guard let image = barcodeImage else { return }
        
        // Create print operation
        let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        
        let printInfo = NSPrintInfo.shared
        printInfo.paperSize = NSSize(width: 288, height: 144) // 4x2 inches at 72 DPI
        printInfo.topMargin = 10
        printInfo.bottomMargin = 10
        printInfo.leftMargin = 10
        printInfo.rightMargin = 10
        
        let printOperation = NSPrintOperation(view: imageView, printInfo: printInfo)
        printOperation.showsPrintPanel = true
        printOperation.run()
    }
}
// MARK: - Quality Control Section

struct QualityControlSection: View {
    @ObservedObject var ticket: Ticket
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest var responses: FetchedResults<ChecklistResponse>
    
    init(ticket: Ticket) {
        self.ticket = ticket
        let id = ticket.id ?? UUID()
        _responses = FetchRequest<ChecklistResponse>(
            sortDescriptors: [NSSortDescriptor(keyPath: \ChecklistResponse.item, ascending: true)],
            predicate: NSPredicate(format: "ticketId == %@ AND category == %@", id as CVarArg, "qc")
        )
    }
    
    var body: some View {
        Section("Quality Control Checklist") {
            if responses.isEmpty {
                Button("Start Quality Control") {
                    initializeQC()
                }
            } else {
                ForEach(responses) { response in
                    Toggle(isOn: Binding(
                        get: { response.isPassed },
                        set: { newValue in
                            response.isPassed = newValue
                            response.checkedBy = "Technician" // Should get actual name
                            try? viewContext.save()
                        }
                    )) {
                        Text(response.item ?? "Unknown Item")
                    }
                }
                
                if isFullyPassed {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("QC Passed")
                            .foregroundColor(.green)
                            .bold()
                    }
                }
            }
        }
    }
    
    private var isFullyPassed: Bool {
        !responses.isEmpty && responses.allSatisfy { $0.isPassed }
    }
    
    private func initializeQC() {
        guard let ticketId = ticket.id else { return }
        
        let items = [
            "Display / Touch Screen",
            "Home Button / Face ID",
            "Volume Buttons / Mute Switch",
            "Power Button",
            "Charging Port",
            "Cameras (Front & Rear)",
            "Speakers / Microphone",
            "Wi-Fi / Bluetooth/ Cellular",
            "Proximity Sensor",
            "Cleaned & Sanitized"
        ]
        
        for item in items {
            let response = ChecklistResponse(context: viewContext)
            response.id = UUID()
            response.ticketId = ticketId
            response.category = "qc"
            response.item = item
            response.isPassed = false
            response.createdAt = Date()
        }
        
        try? viewContext.save()
    }
}
