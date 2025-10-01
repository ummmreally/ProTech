//
//  RepairProgressView.swift
//  ProTech
//
//  Track repair progress with stages and updates
//

import SwiftUI
import CoreData

struct RepairProgressView: View {
    @ObservedObject var ticket: Ticket
    @State private var currentStage: RepairStage = .diagnostic
    @State private var stageNotes: [RepairStage: String] = [:]
    @State private var completedStages: Set<RepairStage> = []
    @State private var partsOrdered: [RepairPart] = []
    @State private var showingAddPart = false
    @State private var laborHours: Double = 0
    
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
                        stageNotes[stage] = notes
                        saveProgress()
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
            AddPartView(parts: $partsOrdered)
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
                    updateStatus("completed")
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
        partsOrdered.reduce(0) { $0 + $1.cost }
    }
    
    private var laborCost: Double {
        laborHours * 75.0 // $75/hour rate
    }
    
    // MARK: - Methods
    
    private func toggleStage(_ stage: RepairStage) {
        if completedStages.contains(stage) {
            completedStages.remove(stage)
        } else {
            completedStages.insert(stage)
            // Auto-advance current stage
            if let nextStage = RepairStage.allCases.first(where: { !completedStages.contains($0) }) {
                currentStage = nextStage
            }
        }
        saveProgress()
    }
    
    private func deletePart(_ part: RepairPart) {
        partsOrdered.removeAll { $0.id == part.id }
        saveProgress()
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
        
        CoreDataManager.shared.save()
    }
    
    private func loadProgress() {
        // Load from ticket notes or custom fields
        if let notes = ticket.notes {
            // Parse progress data from notes
            // This is simplified - you'd want proper JSON storage
        }
    }
    
    private func saveProgress() {
        // Save progress to ticket
        var progressData: [String: Any] = [:]
        progressData["currentStage"] = currentStage.rawValue
        progressData["completedStages"] = completedStages.map { $0.rawValue }
        progressData["laborHours"] = laborHours
        
        // Save parts
        let partsData = partsOrdered.map { [
            "name": $0.name,
            "partNumber": $0.partNumber,
            "cost": $0.cost,
            "quantity": $0.quantity
        ]}
        progressData["parts"] = partsData
        
        // Convert to JSON and save
        if let jsonData = try? JSONSerialization.data(withJSONObject: progressData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Store in ticket's custom field or notes
            var currentNotes = ticket.notes ?? ""
            currentNotes += "\n\n=== PROGRESS DATA ===\n\(jsonString)"
            ticket.notes = currentNotes
            ticket.updatedAt = Date()
            CoreDataManager.shared.save()
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

struct RepairPart: Identifiable, Codable {
    let id: UUID
    var name: String
    var partNumber: String
    var cost: Double
    var quantity: Int
    
    init(id: UUID = UUID(), name: String, partNumber: String, cost: Double, quantity: Int) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.cost = cost
        self.quantity = quantity
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
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(part.cost, specifier: "%.2f")")
                    .font(.body)
                    .bold()
                Text("Qty: \(part.quantity)")
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
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var cost = ""
    @State private var quantity = 1
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Part Information") {
                    TextField("Part Name", text: $name)
                    TextField("Part Number", text: $partNumber)
                    TextField("Cost", text: $cost)
                        .help("Enter cost per unit")
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...100)
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
        !name.isEmpty && !partNumber.isEmpty && Double(cost) != nil
    }
    
    private func addPart() {
        guard let costValue = Double(cost) else { return }
        
        let part = RepairPart(
            name: name,
            partNumber: partNumber,
            cost: costValue,
            quantity: quantity
        )
        
        parts.append(part)
        dismiss()
    }
}
