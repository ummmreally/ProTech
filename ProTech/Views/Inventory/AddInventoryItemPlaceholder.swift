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
    @State private var reorderPoint: Int = 5
    @State private var costPrice: Double = 0.0
    @State private var sellingPrice: Double = 0.0
    @State private var location = ""
    @State private var notes = ""
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
                    
                    HStack {
                        Text("Reorder Point")
                        Spacer()
                        TextField("", value: $reorderPoint, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Location", text: $location)
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
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
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
            item.reorderPoint = Int32(reorderPoint)
            item.costPrice = costPrice
            item.sellingPrice = sellingPrice
            item.location = location.isEmpty ? nil : location
            item.notes = notes.isEmpty ? nil : notes
            item.isActive = true
            item.createdAt = Date()
            item.updatedAt = Date()
            
            try viewContext.save()
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
    @State private var reorderPoint: Int = 5
    @State private var costPrice: Double = 0.0
    @State private var sellingPrice: Double = 0.0
    @State private var location = ""
    @State private var notes = ""
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
                    
                    HStack {
                        Text("Reorder Point")
                        Spacer()
                        TextField("", value: $reorderPoint, format: .number)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    TextField("Location", text: $location)
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
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
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
        reorderPoint = Int(item.reorderPoint)
        costPrice = item.costPrice
        sellingPrice = item.sellingPrice
        location = item.location ?? ""
        notes = item.notes ?? ""
    }
    
    private func saveChanges() {
        do {
            item.name = name
            item.partNumber = partNumber.isEmpty ? nil : partNumber
            item.sku = sku.isEmpty ? nil : sku
            item.category = category.rawValue
            item.quantity = Int32(quantity)
            item.reorderPoint = Int32(reorderPoint)
            item.costPrice = costPrice
            item.sellingPrice = sellingPrice
            item.location = location.isEmpty ? nil : location
            item.notes = notes.isEmpty ? nil : notes
            item.updatedAt = Date()
            
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

struct StockAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItem

    var body: some View {
        VStack(spacing: 16) {
            Text("Adjust Stock for \(item.name ?? "Item")")
                .font(.title3)
                .bold()
            Text("Stock adjustments will be available soon.")
                .foregroundColor(.secondary)
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(width: 400, height: 250)
    }
}
