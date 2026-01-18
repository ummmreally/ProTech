//
//  RepairProgressView.swift
//  ProTech
//
//  Track repair progress with stages and updates
//

import SwiftUI
import CoreData

struct RepairProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var ticket: Ticket
    @State private var currentStage: RepairStage = .diagnostic
    @State private var stageNotes: [RepairStage: String] = [:]
    @State private var completedStages: Set<RepairStage> = []
    @State private var partsOrdered: [RepairPart] = []
    @State private var showingAddPart = false
    @State private var laborHours: Double = 0
    @State private var progressRecord: RepairProgress?
    @State private var stageRecords: [RepairStage: RepairStageRecord] = [:]
    @State private var partUsageMap: [UUID: RepairPartUsage] = [:]
    @State private var hasLoadedProgress = false
    
    // SMS integration
    @State private var showingSMSModal = false
    @State private var smsMessage = ""
    @State private var pendingStatusChange: String?
    @State private var customer: Customer?
    
    @FetchRequest var customerRequest: FetchedResults<Customer>
    
    init(ticket: Ticket) {
        self.ticket = ticket
        if let customerId = ticket.customerId {
            _customerRequest = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(format: "id == %@", customerId as CVarArg)
            )
        } else {
            _customerRequest = FetchRequest<Customer>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Progress Header
                progressHeader
                
                // Repair Stages
                repairStagesSection
                
                // Parts & Materials
                partsSection
                
                // Labor Tracking
                laborSection
                
                // Status Updates
                statusUpdatesSection
            }
            .padding()
        }
        .onAppear {
            loadProgress()
            customer = customerRequest.first
        }
        .sheet(isPresented: $showingSMSModal) {
            if let customer = customer {
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
        .onChange(of: partsOrdered) { _, _ in
            if hasLoadedProgress {
                saveProgress()
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Repair Progress")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Text("\(completedStages.count)/\(RepairStage.allCases.count) Complete")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(completedStages.count), total: Double(RepairStage.allCases.count))
                .tint(.green)
            
            HStack {
                Image(systemName: currentStage.icon)
                    .foregroundColor(currentStage.color)
                Text("Current: \(currentStage.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    // MARK: - Repair Stages
    
    private var repairStagesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repair Stages")
                .font(.headline)
            
            ForEach(RepairStage.allCases, id: \.self) { stage in
                RepairStageCard(
                    stage: stage,
                    isCompleted: completedStages.contains(stage),
                    isCurrent: currentStage == stage,
                    notes: stageNotes[stage] ?? "",
                    onToggle: {
                        toggleStage(stage)
                    },
                    onNotesChange: { notes in
                        updateNotes(notes, for: stage)
                    }
                )
            }
        }
    }
    
    // MARK: - Parts Section
    
    private var partsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Parts & Materials")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddPart = true
                } label: {
                    Label("Add Part", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            if partsOrdered.isEmpty {
                HStack {
                    Image(systemName: "cube.box")
                        .foregroundColor(.secondary)
                    Text("No parts added yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(8)
            } else {
                ForEach(partsOrdered) { part in
                    PartRow(part: part, onDelete: {
                        deletePart(part)
                    })
                }
                
                // Total cost
                HStack {
                    Text("Total Parts Cost:")
                        .font(.headline)
                    Spacer()
                    Text("$\(totalPartsCost, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingAddPart) {
            AddPartView(parts: $partsOrdered, defaultStage: currentStage)
        }
    }
    
    // MARK: - Labor Section
    
    private var laborSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Labor")
                .font(.headline)
            
            HStack {
                Text("Hours:")
                Stepper("\(laborHours, specifier: "%.1f")", value: $laborHours, in: 0...100, step: 0.5)
                    .onChange(of: laborHours) { _, _ in
                        saveProgress()
                    }
            }
            
            if laborHours > 0 {
                HStack {
                    Text("Labor Cost:")
                    Spacer()
                    Text("$\(laborCost, specifier: "%.2f")")
                        .foregroundColor(.blue)
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Status Updates
    
    private var statusUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Status Update")
                .font(.headline)
            
            HStack(spacing: 12) {
                Button {
                    updateStatus("in_progress")
                } label: {
                    Label("Start Work", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
                .disabled(ticket.status == "in_progress")
                
                Button {
                    // Check if SMS should be sent
                    if TwilioService.shared.isConfigured && customer?.phone != nil {
                        prepareReadyForPickupSMS()
                    } else {
                        updateStatus("completed")
                    }
                } label: {
                    Label("Mark Complete", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(ticket.status == "completed")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var totalPartsCost: Double {
        partsOrdered.reduce(0) { $0 + $1.totalCost }
    }
    
    private var laborCost: Double {
        laborHours * 75.0 // $75/hour rate
    }
    
    // MARK: - Methods
    
    private func toggleStage(_ stage: RepairStage) {
        guard let record = stageRecords[stage] else {
            return
        }

        if completedStages.contains(stage) {
            completedStages.remove(stage)
            record.isCompleted = false
            record.completedAt = nil
            currentStage = stage
            markStageAsCurrent(stage)
        } else {
            completedStages.insert(stage)
            record.isCompleted = true
            if record.startedAt == nil {
                record.startedAt = Date()
            }
            if record.completedAt == nil {
                record.completedAt = Date()
            }

            if let nextStage = RepairStage.allCases.first(where: { !completedStages.contains($0) }) {
                currentStage = nextStage
                markStageAsCurrent(nextStage)
            } else {
                currentStage = stage
                markStageAsCurrent(stage)
            }
        }

        record.notes = stageNotes[stage] ?? record.notes
        record.lastUpdated = Date()
        saveProgress()
        
        // AUTOMATION TRIGGERS
        if completedStages.contains(stage) {
            // Stage Completed Logic
            switch stage {
            case .diagnostic:
                // Ensure ticket is technically "In Progress" if diagnostics are done
                if ticket.status == "waiting" {
                    updateStatus("in_progress")
                }
                
            case .qualityCheck, .cleanup:
                // If Quality Check or Cleanup is done, prompt for Ready for Pickup
                if !completedStages.contains(.cleanup) || stage == .cleanup {
                     // Check if Customer is setup for SMS
                    if TwilioService.shared.isConfigured && customer?.phone != nil {
                        prepareReadyForPickupSMS()
                    } else if ticket.status != "completed" {
                         // Auto-complete if no SMS
                        updateStatus("completed")
                    }
                }
            default:
                break
            }
        } else {
           // Stage Un-checked (reverted)
           // Potentially revert status but usually safer to leave as is manually
        }
        
        // Auto-start "In Progress" if any stage is clicked
        if ticket.status == "waiting" {
            updateStatus("in_progress")
        }
    }
    
    private func deletePart(_ part: RepairPart) {
        partsOrdered.removeAll { $0.id == part.id }
        saveProgress()
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
    
    private func loadProgress() {
        guard let ticketId = ticket.id else { return }

        do {
            let request: NSFetchRequest<RepairProgress> = RepairProgress.fetchRequest()
            request.predicate = NSPredicate(format: "ticketId == %@", ticketId as CVarArg)
            request.fetchLimit = 1

            let progress = try viewContext.fetch(request).first ?? createProgress(for: ticketId)
            progressRecord = progress

            laborHours = progress.laborHours
            if let stageKey = progress.currentStage, let storedStage = RepairStage(rawValue: stageKey) {
                currentStage = storedStage
            }

            try loadStageRecords(for: progress)
            try loadPartUsages(for: progress)

            var noteDictionary: [RepairStage: String] = [:]
            var completedSet: Set<RepairStage> = []
            for stage in RepairStage.allCases {
                let record = stageRecords[stage]
                noteDictionary[stage] = record?.notes ?? ""
                if record?.isCompleted == true {
                    completedSet.insert(stage)
                }
            }
            stageNotes = noteDictionary
            completedStages = completedSet

            if progress.currentStage == nil,
               let nextStage = RepairStage.allCases.first(where: { !completedStages.contains($0) }) {
                currentStage = nextStage
            }

            markStageAsCurrent(currentStage)
            hasLoadedProgress = true
            CoreDataManager.shared.save()
        } catch {
            print("Failed to load repair progress: \(error.localizedDescription)")
        }
    }

    private func saveProgress() {
        guard let ticketId = ticket.id else { return }

        let progress = progressRecord ?? createProgress(for: ticketId)
        if progress.id == nil {
            progress.id = UUID()
        }

        progress.ticketId = ticketId
        progress.currentStage = currentStage.rawValue
        progress.laborHours = laborHours
        progress.updatedAt = Date()
        if progress.createdAt == nil {
            progress.createdAt = Date()
        }

        for stage in RepairStage.allCases {
            guard let record = stageRecords[stage] else { continue }

            record.progressId = progress.id
            record.stageKey = stage.rawValue
            record.notes = stageNotes[stage] ?? ""
            record.isCompleted = completedStages.contains(stage)
            if record.isCompleted {
                if record.startedAt == nil { record.startedAt = Date() }
                if record.completedAt == nil { record.completedAt = Date() }
            } else {
                record.completedAt = nil
            }
            record.lastUpdated = Date()
        }

        syncParts(with: progress)

        ticket.updatedAt = Date()
        progressRecord = progress
        CoreDataManager.shared.save()
    }

    private func createProgress(for ticketId: UUID) -> RepairProgress {
        let progress = RepairProgress(context: viewContext)
        progress.id = UUID()
        progress.ticketId = ticketId
        progress.currentStage = RepairStage.diagnostic.rawValue
        progress.laborHours = 0
        progress.laborRate = 75
        progress.createdAt = Date()
        progress.updatedAt = Date()
        return progress
    }

    private func loadStageRecords(for progress: RepairProgress) throws {
        guard let progressId = progress.id else { return }

        let request: NSFetchRequest<RepairStageRecord> = RepairStageRecord.fetchRequest()
        request.predicate = NSPredicate(format: "progressId == %@", progressId as CVarArg)
        let existing = try viewContext.fetch(request)

        var recordMap: [RepairStage: RepairStageRecord] = [:]
        for record in existing {
            if let key = record.stageKey, let stage = RepairStage(rawValue: key) {
                recordMap[stage] = record
            }
        }

        for (index, stage) in RepairStage.allCases.enumerated() {
            if recordMap[stage] == nil {
                let newRecord = RepairStageRecord(context: viewContext)
                newRecord.id = UUID()
                newRecord.progressId = progressId
                newRecord.stageKey = stage.rawValue
                newRecord.sortOrder = Int16(index)
                newRecord.isCompleted = false
                newRecord.lastUpdated = Date()
                recordMap[stage] = newRecord
            }
        }

        stageRecords = recordMap
    }

    private func loadPartUsages(for progress: RepairProgress) throws {
        guard let progressId = progress.id else { return }

        let request: NSFetchRequest<RepairPartUsage> = RepairPartUsage.fetchRequest()
        request.predicate = NSPredicate(format: "progressId == %@", progressId as CVarArg)
        let usages = try viewContext.fetch(request)

        partUsageMap = Dictionary(uniqueKeysWithValues: usages.compactMap { usage in
            guard let usageId = usage.id else { return nil }
            return (usageId, usage)
        })

        partsOrdered = usages.compactMap { usage in
            guard let usageId = usage.id else { return nil }
            let stage = RepairStage(rawValue: usage.stageKey ?? "") ?? .diagnostic
            return RepairPart(
                id: usageId,
                name: usage.name ?? "",
                partNumber: usage.partNumber ?? "",
                cost: usage.unitCost,
                quantity: Int(usage.quantity),
                stage: stage
            )
        }.sorted { lhs, rhs in
            if lhs.stage == rhs.stage {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.stage.sortOrder < rhs.stage.sortOrder
        }
    }

    private func syncParts(with progress: RepairProgress) {
        guard let progressId = progress.id else { return }

        var unusedIdentifiers = Set(partUsageMap.keys)

        for part in partsOrdered {
            if let usage = partUsageMap[part.id] {
                usage.name = part.name
                usage.partNumber = part.partNumber
                usage.unitCost = part.cost
                usage.quantity = Int32(part.quantity)
                usage.stageKey = part.stage.rawValue
                usage.progressId = progressId
                usage.updatedAt = Date()
                unusedIdentifiers.remove(part.id)
            } else {
                let usage = RepairPartUsage(context: viewContext)
                usage.id = part.id
                usage.progressId = progressId
                usage.stageKey = part.stage.rawValue
                usage.name = part.name
                usage.partNumber = part.partNumber
                usage.unitCost = part.cost
                usage.quantity = Int32(part.quantity)
                usage.createdAt = Date()
                usage.updatedAt = Date()
                partUsageMap[part.id] = usage
            }
        }

        for identifier in unusedIdentifiers {
            if let usage = partUsageMap[identifier] {
                viewContext.delete(usage)
                partUsageMap.removeValue(forKey: identifier)
            }
        }
    }

    private func markStageAsCurrent(_ stage: RepairStage) {
        guard let record = stageRecords[stage] else { return }
        if record.startedAt == nil {
            record.startedAt = Date()
        }
        record.lastUpdated = Date()
    }

    private func updateNotes(_ notes: String, for stage: RepairStage) {
        stageNotes[stage] = notes
        if let record = stageRecords[stage] {
            record.notes = notes
            record.lastUpdated = Date()
        }
        saveProgress()
    }
    
    // MARK: - SMS Functions
    
    private func prepareReadyForPickupSMS() {
        guard let customer = customer else { return }
        
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
    
    private func sendSMS(message: String) {
        guard let customer = customer,
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
                // Silently fail or handle error
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

// MARK: - Repair Stage

enum RepairStage: String, CaseIterable {
    case diagnostic = "diagnostic"
    case partsOrdering = "parts_ordering"
    case disassembly = "disassembly"
    case repair = "repair"
    case testing = "testing"
    case reassembly = "reassembly"
    case qualityCheck = "quality_check"
    case cleanup = "cleanup"
    
    var displayName: String {
        switch self {
        case .diagnostic: return "Diagnostic"
        case .partsOrdering: return "Parts Ordering"
        case .disassembly: return "Disassembly"
        case .repair: return "Repair"
        case .testing: return "Testing"
        case .reassembly: return "Reassembly"
        case .qualityCheck: return "Quality Check"
        case .cleanup: return "Cleanup"
        }
    }
    
    var icon: String {
        switch self {
        case .diagnostic: return "stethoscope"
        case .partsOrdering: return "shippingbox"
        case .disassembly: return "wrench"
        case .repair: return "hammer"
        case .testing: return "checkmark.shield"
        case .reassembly: return "arrow.triangle.2.circlepath"
        case .qualityCheck: return "checkmark.seal"
        case .cleanup: return "sparkles"
        }
    }
    
    var color: Color {
        switch self {
        case .diagnostic: return .blue
        case .partsOrdering: return .orange
        case .disassembly: return .purple
        case .repair: return .red
        case .testing: return .green
        case .reassembly: return .indigo
        case .qualityCheck: return .mint
        case .cleanup: return .cyan
        }
    }

    var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}

// MARK: - Repair Stage Card

struct RepairStageCard: View {
    let stage: RepairStage
    let isCompleted: Bool
    let isCurrent: Bool
    let notes: String
    let onToggle: () -> Void
    let onNotesChange: (String) -> Void
    
    @State private var isExpanded = false
    @State private var editedNotes: String
    
    init(stage: RepairStage, isCompleted: Bool, isCurrent: Bool, notes: String, onToggle: @escaping () -> Void, onNotesChange: @escaping (String) -> Void) {
        self.stage = stage
        self.isCompleted = isCompleted
        self.isCurrent = isCurrent
        self.notes = notes
        self.onToggle = onToggle
        self.onNotesChange = onNotesChange
        _editedNotes = State(initialValue: notes)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundColor(isCompleted ? .green : .gray)
                }
                .buttonStyle(.plain)
                
                Image(systemName: stage.icon)
                    .foregroundColor(stage.color)
                
                Text(stage.displayName)
                    .font(.headline)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
                
                if isCurrent {
                    Text("CURRENT")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(stage.color.opacity(0.2))
                        .foregroundColor(stage.color)
                        .cornerRadius(4)
                }
                
                Spacer()
                
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
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $editedNotes)
                        .frame(minHeight: 60)
                        .padding(4)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(6)
                        .onChange(of: editedNotes) { _, newValue in
                            onNotesChange(newValue)
                        }
                }
            }
        }
        .padding()
        .background(isCompleted ? Color.green.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isCurrent ? stage.color : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Repair Part

struct RepairPart: Identifiable, Equatable {
    let id: UUID
    var name: String
    var partNumber: String
    var cost: Double
    var quantity: Int
    var stage: RepairStage

    init(id: UUID = UUID(), name: String, partNumber: String, cost: Double, quantity: Int, stage: RepairStage) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.cost = cost
        self.quantity = quantity
        self.stage = stage
    }

    var totalCost: Double {
        cost * Double(quantity)
    }
}

// MARK: - Part Row

struct PartRow: View {
    let part: RepairPart
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(part.name)
                    .font(.body)
                Text("Part #: \(part.partNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(part.stage.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(part.stage.color.opacity(0.15))
                    .foregroundColor(part.stage.color)
                    .cornerRadius(6)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(part.totalCost, specifier: "%.2f")")
                    .font(.body)
                    .bold()
                Text("Qty: \(part.quantity) @ $\(part.cost, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Add Part View

struct AddPartView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var parts: [RepairPart]
    let defaultStage: RepairStage
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var cost = ""
    @State private var quantity = 1
    @State private var stage: RepairStage

    init(parts: Binding<[RepairPart]>, defaultStage: RepairStage) {
        self._parts = parts
        self.defaultStage = defaultStage
        _stage = State(initialValue: defaultStage)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Part Information") {
                    TextField("Part Name", text: $name)
                    TextField("Part Number", text: $partNumber)
                    TextField("Cost", text: $cost)
                        .help("Enter cost per unit")
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
                    Picker("Stage", selection: $stage) {
                        ForEach(RepairStage.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                }
                
                if let costValue = Double(cost), costValue > 0 {
                    Section("Total") {
                        HStack {
                            Text("Total Cost:")
                            Spacer()
                            Text("$\(costValue * Double(quantity), specifier: "%.2f")")
                                .bold()
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Part")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPart()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private var isValid: Bool {
        guard let costValue = Double(cost) else { return false }
        return !name.isEmpty && !partNumber.isEmpty && costValue >= 0
    }
    
    private func addPart() {
        guard let costValue = Double(cost) else { return }
        
        let part = RepairPart(
            name: name,
            partNumber: partNumber,
            cost: costValue,
            quantity: quantity,
            stage: stage
        )

        parts.append(part)
        parts.sort { lhs, rhs in
            if lhs.stage == rhs.stage {
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            return lhs.stage.sortOrder < rhs.stage.sortOrder
        }
        dismiss()
    }
}
