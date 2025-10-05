//
//  LoyaltyTiersTab.swift
//  ProTech
//
//  Manage VIP tiers
//

import SwiftUI
import CoreData

struct LoyaltyTiersTab: View {
    let program: LoyaltyProgram
    @FetchRequest var tiers: FetchedResults<LoyaltyTier>
    @State private var showingAddTier = false
    
    init(program: LoyaltyProgram) {
        self.program = program
        
        if let programId = program.id {
            _tiers = FetchRequest<LoyaltyTier>(
                sortDescriptors: [NSSortDescriptor(keyPath: \LoyaltyTier.sortOrder, ascending: true)],
                predicate: NSPredicate(format: "programId == %@", programId as CVarArg)
            )
        } else {
            _tiers = FetchRequest<LoyaltyTier>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("VIP Tiers")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button {
                    showingAddTier = true
                } label: {
                    Label("Add Tier", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(tiers) { tier in
                        TierCard(tier: tier)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddTier) {
            AddTierView(program: program)
        }
    }
}

struct TierCard: View {
    @ObservedObject var tier: LoyaltyTier
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(tierColor.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "rosette")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.name ?? "Unnamed Tier")
                        .font(.title3)
                        .bold()
                    
                    Text("\(tier.pointsMultiplier, specifier: "%.1f")x points multiplier")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    isEditing = true
                } label: {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            HStack {
                Label("Minimum Points", systemImage: "star.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(tier.pointsRequired)")
                    .font(.headline)
            }
        }
        .padding()
        .background(tierColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tierColor, lineWidth: 2)
        )
        .sheet(isPresented: $isEditing) {
            EditTierView(tier: tier)
        }
    }
    
    private var tierColor: Color {
        if let colorHex = tier.color {
            return Color(hex: colorHex)
        }
        return .blue
    }
}

struct AddTierView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let program: LoyaltyProgram
    
    @State private var name = ""
    @State private var pointsRequired = ""
    @State private var pointsMultiplier = "1.0"
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tier Information") {
                    TextField("Tier Name (e.g., Bronze, Gold)", text: $name)
                    
                    TextField("Minimum Points Required", text: $pointsRequired)
                    
                    TextField("Points Multiplier (e.g., 1.5)", text: $pointsMultiplier)
                    
                    ColorPicker("Tier Color", selection: $selectedColor)
                }
                
                Section("Preview") {
                    HStack {
                        Circle()
                            .fill(selectedColor.gradient)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "rosette")
                                    .foregroundColor(.white)
                            }
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Tier Name" : name)
                                .font(.headline)
                            Text("\(pointsMultiplier)x points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add Tier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTier()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 500, height: 450)
    }
    
    private var isValid: Bool {
        !name.isEmpty && Int32(pointsRequired) != nil && Double(pointsMultiplier) != nil
    }
    
    private func addTier() {
        guard let programId = program.id,
              let points = Int32(pointsRequired),
              let multiplier = Double(pointsMultiplier) else {
            return
        }
        
        let tier = LoyaltyTier(context: viewContext)
        tier.id = UUID()
        tier.programId = programId
        tier.name = name
        tier.pointsRequired = points
        tier.pointsMultiplier = multiplier
        tier.color = selectedColor.toHex()
        tier.sortOrder = Int16(getTierCount() + 1)
        tier.createdAt = Date()
        
        CoreDataManager.shared.save()
        dismiss()
    }
    
    private func getTierCount() -> Int {
        guard let programId = program.id else { return 0 }
        
        let request: NSFetchRequest<LoyaltyTier> = LoyaltyTier.fetchRequest()
        request.predicate = NSPredicate(format: "programId == %@", programId as CVarArg)
        
        return (try? viewContext.count(for: request)) ?? 0
    }
}

struct EditTierView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var tier: LoyaltyTier
    
    @State private var name = ""
    @State private var pointsRequired = ""
    @State private var pointsMultiplier = ""
    @State private var selectedColor = Color.blue
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tier Information") {
                    TextField("Tier Name", text: $name)
                    
                    TextField("Minimum Points Required", text: $pointsRequired)
                    
                    TextField("Points Multiplier", text: $pointsMultiplier)
                    
                    ColorPicker("Tier Color", selection: $selectedColor)
                }
            }
            .navigationTitle("Edit Tier")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTier()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            loadTierData()
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Int32(pointsRequired) != nil && Double(pointsMultiplier) != nil
    }
    
    private func loadTierData() {
        name = tier.name ?? ""
        pointsRequired = "\(tier.pointsRequired)"
        pointsMultiplier = "\(tier.pointsMultiplier)"
        if let colorHex = tier.color {
            selectedColor = Color(hex: colorHex)
        }
    }
    
    private func saveTier() {
        guard let points = Int32(pointsRequired),
              let multiplier = Double(pointsMultiplier) else {
            return
        }
        
        tier.name = name
        tier.pointsRequired = points
        tier.pointsMultiplier = multiplier
        tier.color = selectedColor.toHex()
        
        CoreDataManager.shared.save()
        dismiss()
    }
}
