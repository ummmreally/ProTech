//
//  LoyaltyRewardsTab.swift
//  ProTech
//
//  Manage loyalty rewards
//

import SwiftUI
import CoreData

struct LoyaltyRewardsTab: View {
    let program: LoyaltyProgram
    @FetchRequest var rewards: FetchedResults<LoyaltyReward>
    @State private var showingAddReward = false
    
    init(program: LoyaltyProgram) {
        self.program = program
        
        if let programId = program.id {
            _rewards = FetchRequest<LoyaltyReward>(
                sortDescriptors: [NSSortDescriptor(keyPath: \LoyaltyReward.sortOrder, ascending: true)],
                predicate: NSPredicate(format: "programId == %@", programId as CVarArg)
            )
        } else {
            _rewards = FetchRequest<LoyaltyReward>(
                sortDescriptors: [],
                predicate: NSPredicate(value: false)
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rewards Catalog")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Button {
                    showingAddReward = true
                } label: {
                    Label("Add Reward", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                    ForEach(rewards) { reward in
                        RewardCard(reward: reward)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingAddReward) {
            AddRewardView(program: program)
        }
    }
}

struct RewardCard: View {
    @ObservedObject var reward: LoyaltyReward
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: rewardIcon)
                    .font(.title)
                    .foregroundColor(reward.isActive ? .green : .gray)
                    .frame(width: 50, height: 50)
                    .background(reward.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(reward.pointsCost)")
                            .font(.title3)
                            .bold()
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                    }
                    
                    Text("points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(reward.name ?? "Unnamed Reward")
                .font(.headline)
            
            if let description = reward.description_ {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Divider()
            
            HStack {
                Label(rewardTypeDisplay, systemImage: "tag.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    isEditing = true
                } label: {
                    Text("Edit")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(reward.isActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 2)
        )
        .sheet(isPresented: $isEditing) {
            EditRewardView(reward: reward)
        }
    }
    
    private var rewardIcon: String {
        switch reward.rewardType {
        case "discount_percent": return "percent"
        case "discount_amount": return "dollarsign.circle"
        case "free_item": return "gift.fill"
        default: return "star.fill"
        }
    }
    
    private var rewardTypeDisplay: String {
        switch reward.rewardType {
        case "discount_percent": return "\(Int(reward.rewardValue))% Off"
        case "discount_amount": return "$\(Int(reward.rewardValue)) Off"
        case "free_item": return "Free Item"
        default: return "Custom Reward"
        }
    }
}

struct AddRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    let program: LoyaltyProgram
    
    @State private var name = ""
    @State private var description = ""
    @State private var pointsCost = ""
    @State private var rewardType = "discount_amount"
    @State private var rewardValue = ""
    
    let rewardTypes = [
        ("discount_amount", "Dollar Amount Off"),
        ("discount_percent", "Percentage Off"),
        ("free_item", "Free Item"),
        ("custom", "Custom Reward")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Points Cost", text: $pointsCost)
                }
                
                Section("Reward Type") {
                    Picker("Type", selection: $rewardType) {
                        ForEach(rewardTypes, id: \.0) { type in
                            Text(type.1).tag(type.0)
                        }
                    }
                    
                    if rewardType != "free_item" {
                        TextField(valueLabel, text: $rewardValue)
                    }
                }
                
                Section("Preview") {
                    HStack {
                        Image(systemName: previewIcon)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            Text(name.isEmpty ? "Reward Name" : name)
                                .font(.headline)
                            Text(description.isEmpty ? "Description" : description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Text(pointsCost.isEmpty ? "0" : pointsCost)
                                .bold()
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle("Add Reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addReward()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 550, height: 550)
    }
    
    private var valueLabel: String {
        switch rewardType {
        case "discount_percent": return "Percentage (e.g., 10 for 10%)"
        case "discount_amount": return "Dollar Amount (e.g., 5 for $5)"
        default: return "Value"
        }
    }
    
    private var previewIcon: String {
        switch rewardType {
        case "discount_percent": return "percent"
        case "discount_amount": return "dollarsign.circle"
        case "free_item": return "gift.fill"
        default: return "star.fill"
        }
    }
    
    private var isValid: Bool {
        guard !name.isEmpty, let _ = Int32(pointsCost) else { return false }
        
        if rewardType == "free_item" {
            return true
        }
        
        return Double(rewardValue) != nil
    }
    
    private func addReward() {
        guard let programId = program.id,
              let points = Int32(pointsCost) else {
            return
        }
        
        let value = rewardType == "free_item" ? 0.0 : (Double(rewardValue) ?? 0.0)
        
        let reward = LoyaltyReward(context: viewContext)
        reward.id = UUID()
        reward.programId = programId
        reward.name = name
        reward.description_ = description
        reward.pointsCost = points
        reward.rewardType = rewardType
        reward.rewardValue = value
        reward.isActive = true
        reward.sortOrder = Int16(getRewardCount() + 1)
        reward.createdAt = Date()
        reward.updatedAt = Date()
        
        CoreDataManager.shared.save()
        dismiss()
    }
    
    private func getRewardCount() -> Int {
        guard let programId = program.id else { return 0 }
        
        let request: NSFetchRequest<LoyaltyReward> = LoyaltyReward.fetchRequest()
        request.predicate = NSPredicate(format: "programId == %@", programId as CVarArg)
        
        return (try? viewContext.count(for: request)) ?? 0
    }
}

struct EditRewardView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var reward: LoyaltyReward
    
    @State private var name = ""
    @State private var description = ""
    @State private var pointsCost = ""
    @State private var rewardValue = ""
    @State private var isActive = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reward Details") {
                    TextField("Reward Name", text: $name)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    
                    TextField("Points Cost", text: $pointsCost)
                    
                    if reward.rewardType != "free_item" {
                        TextField("Value", text: $rewardValue)
                    }
                    
                    Toggle("Active", isOn: $isActive)
                }
            }
            .navigationTitle("Edit Reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveReward()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 500, height: 450)
        .onAppear {
            loadRewardData()
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && Int32(pointsCost) != nil
    }
    
    private func loadRewardData() {
        name = reward.name ?? ""
        description = reward.description_ ?? ""
        pointsCost = "\(reward.pointsCost)"
        rewardValue = "\(reward.rewardValue)"
        isActive = reward.isActive
    }
    
    private func saveReward() {
        guard let points = Int32(pointsCost) else { return }
        
        reward.name = name
        reward.description_ = description
        reward.pointsCost = points
        reward.rewardValue = Double(rewardValue) ?? 0.0
        reward.isActive = isActive
        reward.updatedAt = Date()
        
        CoreDataManager.shared.save()
        dismiss()
    }
}
