import SwiftUI
import CoreData

struct AddInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var sku = ""
    @State private var category = InventoryCategory.components
    @State private var quantity: Int = 0
    @State private var costPrice: Double = 0.0
    @State private var sellingPrice: Double = 0.0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Item Name *", text: $name)
                    TextField("Part Number", text: $partNumber)
                    TextField("SKU", text: $sku)
                    
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                
                Section("Inventory") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Cost Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $costPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Selling Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $sellingPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if sellingPrice > 0 && costPrice > 0 {
                        let margin = ((sellingPrice - costPrice) / sellingPrice) * 100
                        HStack {
                            Text("Profit Margin")
                            Spacer()
                            Text(String(format: "%.1f%%", margin))
                                .foregroundColor(margin > 0 ? .green : .red)
                        }
                    }
                }
                
            }
            .formStyle(.grouped)
            .navigationTitle("Add Inventory Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveItem()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }
    
    private func saveItem() {
        do {
            let item = InventoryItem(context: viewContext)
            item.id = UUID()
            item.name = name
            item.partNumber = partNumber.isEmpty ? nil : partNumber
            item.sku = sku.isEmpty ? nil : sku
            item.category = category.rawValue
            item.quantity = Int32(quantity)
            item.minQuantity = 5 // Default
            item.cost = NSDecimalNumber(value: costPrice)
            item.price = NSDecimalNumber(value: sellingPrice)
            item.isActive = true
            item.createdAt = Date()
            item.updatedAt = Date()
            item.cloudSyncStatus = "pending"
            
            try viewContext.save()
            
            // Sync to Supabase in background
            Task { @MainActor in
                do {
                    let syncer = InventorySyncer()
                    try await syncer.upload(item)
                    item.cloudSyncStatus = "synced"
                    try? viewContext.save()
                } catch {
                    item.cloudSyncStatus = "failed"
                    try? viewContext.save()
                    print("⚠️ Inventory sync failed: \(error.localizedDescription)")
                }
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct EditInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: InventoryItem
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var sku = ""
    @State private var category = InventoryCategory.components
    @State private var quantity: Int = 0
    @State private var costPrice: Double = 0.0
    @State private var sellingPrice: Double = 0.0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Item Name *", text: $name)
                    TextField("Part Number", text: $partNumber)
                    TextField("SKU", text: $sku)
                    
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                }
                
                Section("Inventory") {
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Pricing") {
                    HStack {
                        Text("Cost Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $costPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Selling Price")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $sellingPrice, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    if sellingPrice > 0 && costPrice > 0 {
                        let margin = ((sellingPrice - costPrice) / sellingPrice) * 100
                        HStack {
                            Text("Profit Margin")
                            Spacer()
                            Text(String(format: "%.1f%%", margin))
                                .foregroundColor(margin > 0 ? .green : .red)
                        }
                    }
                }
                
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadItemData()
            }
        }
        .frame(minWidth: 600, minHeight: 600)
    }
    
    private func loadItemData() {
        name = item.name ?? ""
        partNumber = item.partNumber ?? ""
        sku = item.sku ?? ""
        if let cat = item.category, let inventoryCat = InventoryCategory(rawValue: cat) {
            category = inventoryCat
        }
        quantity = Int(item.quantity)
        costPrice = item.costDouble
        sellingPrice = item.priceDouble
    }
    
    private func saveChanges() {
        do {
            item.name = name
            item.partNumber = partNumber.isEmpty ? nil : partNumber
            item.sku = sku.isEmpty ? nil : sku
            item.category = category.rawValue
            item.quantity = Int32(quantity)
            item.minQuantity = 5 // Default
            item.cost = NSDecimalNumber(value: costPrice)
            item.price = NSDecimalNumber(value: sellingPrice)
            item.updatedAt = Date()
            item.cloudSyncStatus = "pending"
            
            try viewContext.save()
            
            // Sync to Supabase in background
            Task { @MainActor in
                do {
                    let syncer = InventorySyncer()
                    try await syncer.upload(item)
                    item.cloudSyncStatus = "synced"
                    try? viewContext.save()
                } catch {
                    item.cloudSyncStatus = "failed"
                    try? viewContext.save()
                    print("⚠️ Inventory sync failed: \(error.localizedDescription)")
                }
            }
            
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct StockAdjustmentSheet: View {
    private enum AdjustmentMode: String, CaseIterable, Identifiable {
        case add
        case remove
        case set
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .add: return "Add"
            case .remove: return "Remove"
            case .set: return "Set Quantity"
            }
        }
        
        var defaultReason: String {
            switch self {
            case .add: return "Stock received"
            case .remove: return "Manual deduction"
            case .set: return "Inventory recount"
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var item: InventoryItem
    private let onComplete: (() -> Void)?
    
    @State private var mode: AdjustmentMode = .add
    @State private var quantityChange: Int = 1
    @State private var targetQuantity: Int = 0
    @State private var reason: String = ""
    @State private var reference: String = ""
    @State private var notes: String = ""
    
    init(item: InventoryItem, onComplete: (() -> Void)? = nil) {
        self._item = ObservedObject(wrappedValue: item)
        self.onComplete = onComplete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Inventory Item")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Current Stock: \(currentQuantity)")
                    .foregroundColor(.secondary)
            }
            
            Picker("Adjustment", selection: $mode) {
                ForEach(AdjustmentMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) {
                reason = mode.defaultReason
                if mode == .set {
                    targetQuantity = currentQuantity
                }
            }
            
            Group {
                if mode == .set {
                    Stepper(value: $targetQuantity, in: 0...100_000) {
                        HStack {
                            Text("New Quantity")
                            Spacer()
                            Text("\(targetQuantity)")
                                .font(.headline)
                        }
                    }
                } else {
                    Stepper(value: $quantityChange, in: 1...50_000) {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text("\(quantityChange)")
                                .font(.headline)
                        }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Resulting Quantity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack {
                    Text("\(resultingQuantity)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(resultingQuantity < 0 ? .red : .primary)
                    Spacer()
                    if resultingQuantity < 0 {
                        Text("Warning: negative stock")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            Group {
                TextField("Reason", text: $reason)
                TextField("Reference (optional)", text: $reference)
                TextField("Notes (optional)", text: $notes)
            }
            
            Spacer()
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Record Adjustment") {
                    performAdjustment()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValidAdjustment)
            }
        }
        .padding(24)
        .frame(width: 440, height: 420)
        .onAppear {
            targetQuantity = currentQuantity
            reason = mode.defaultReason
        }
    }
    
    private var currentQuantity: Int {
        Int(item.quantity)
    }
    
    private var changeAmount: Int {
        switch mode {
        case .add:
            return quantityChange
        case .remove:
            return -quantityChange
        case .set:
            return targetQuantity - currentQuantity
        }
    }
    
    private var resultingQuantity: Int {
        switch mode {
        case .set:
            return targetQuantity
        default:
            return currentQuantity + changeAmount
        }
    }
    
    private var adjustmentType: StockAdjustmentType {
        switch mode {
        case .add: return .add
        case .remove: return .remove
        case .set: return .recount
        }
    }
    
    private var isValidAdjustment: Bool {
        switch mode {
        case .add, .remove:
            return quantityChange > 0
        case .set:
            return targetQuantity >= 0 && targetQuantity != currentQuantity
        }
    }
    
    private func performAdjustment() {
        guard isValidAdjustment, changeAmount != 0 else { return }
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReference = reference.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        InventoryService.shared.adjustStock(
            item: item,
            change: changeAmount,
            type: adjustmentType,
            reason: trimmedReason.isEmpty ? adjustmentType.displayName : trimmedReason,
            reference: trimmedReference.isEmpty ? nil : trimmedReference,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes
        )
        
        // Sync to Supabase in background
        Task { @MainActor in
            item.cloudSyncStatus = "pending"
            do {
                let syncer = InventorySyncer()
                try await syncer.upload(item)
                item.cloudSyncStatus = "synced"
            } catch {
                item.cloudSyncStatus = "failed"
                print("⚠️ Inventory adjustment sync failed: \(error.localizedDescription)")
            }
        }
        
        onComplete?()
        dismiss()
    }
}
