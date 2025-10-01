//
//  InventoryView.swift
//  ProTech
//
//  Parts and inventory management system
//

import SwiftUI

struct InventoryView: View {
    @State private var inventory: [InventoryItem] = []
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var selectedCategory: InventoryCategory = .all
    @State private var sortBy: InventorySortOption = .name
    
    var filteredInventory: [InventoryItem] {
        var items = inventory
        
        // Filter by category
        if selectedCategory != .all {
            items = items.filter { $0.category == selectedCategory }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            items = items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.partNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Sort
        switch sortBy {
        case .name:
            items.sort { $0.name < $1.name }
        case .quantity:
            items.sort { $0.quantity > $1.quantity }
        case .price:
            items.sort { $0.price > $1.price }
        case .lowStock:
            items.sort { $0.quantity < $1.quantity }
        }
        
        return items
    }
    
    var lowStockItems: [InventoryItem] {
        inventory.filter { $0.quantity <= $0.minQuantity }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory")
                        .font(.largeTitle)
                        .bold()
                    Text("\(inventory.count) items • \(lowStockItems.count) low stock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            // Search and filters
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search parts...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(InventoryCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .frame(width: 150)
                
                Picker("Sort", selection: $sortBy) {
                    ForEach(InventorySortOption.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
                .frame(width: 150)
            }
            .padding(.horizontal)
            
            Divider()
                .padding(.top)
            
            // Low stock alert
            if !lowStockItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(lowStockItems.count) item\(lowStockItems.count == 1 ? "" : "s") low on stock")
                        .font(.subheadline)
                    Spacer()
                    Button("View") {
                        sortBy = .lowStock
                    }
                    .buttonStyle(.borderless)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
            
            // Inventory list
            if filteredInventory.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No inventory items" : "No items found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    if searchText.isEmpty {
                        Button {
                            showingAddItem = true
                        } label: {
                            Label("Add Your First Item", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredInventory) { item in
                        InventoryRow(item: item, onUpdate: {
                            loadInventory()
                        })
                    }
                    .onDelete(perform: deleteItems)
                }
                .listStyle(.inset)
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView { newItem in
                inventory.append(newItem)
                saveInventory()
            }
        }
        .onAppear {
            loadInventory()
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        inventory.remove(atOffsets: offsets)
        saveInventory()
    }
    
    private func loadInventory() {
        // Load from UserDefaults or Core Data
        if let data = UserDefaults.standard.data(forKey: "inventory"),
           let decoded = try? JSONDecoder().decode([InventoryItem].self, from: data) {
            inventory = decoded
        }
    }
    
    private func saveInventory() {
        if let encoded = try? JSONEncoder().encode(inventory) {
            UserDefaults.standard.set(encoded, forKey: "inventory")
        }
    }
}

// MARK: - Inventory Item

struct InventoryItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var partNumber: String
    var category: InventoryCategory
    var quantity: Int
    var minQuantity: Int
    var price: Double
    var supplier: String
    var location: String
    var notes: String
    
    init(id: UUID = UUID(), name: String, partNumber: String, category: InventoryCategory, quantity: Int, minQuantity: Int, price: Double, supplier: String, location: String, notes: String) {
        self.id = id
        self.name = name
        self.partNumber = partNumber
        self.category = category
        self.quantity = quantity
        self.minQuantity = minQuantity
        self.price = price
        self.supplier = supplier
        self.location = location
        self.notes = notes
    }
}

// MARK: - Inventory Category

enum InventoryCategory: String, Codable, CaseIterable {
    case all = "all"
    case screens = "screens"
    case batteries = "batteries"
    case cables = "cables"
    case cases = "cases"
    case tools = "tools"
    case adhesives = "adhesives"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .all: return "All Categories"
        case .screens: return "Screens"
        case .batteries: return "Batteries"
        case .cables: return "Cables"
        case .cases: return "Cases"
        case .tools: return "Tools"
        case .adhesives: return "Adhesives"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .screens: return "iphone"
        case .batteries: return "battery.100"
        case .cables: return "cable.connector"
        case .cases: return "square.on.square"
        case .tools: return "wrench.and.screwdriver"
        case .adhesives: return "drop"
        case .other: return "shippingbox"
        }
    }
}

// MARK: - Sort Option

enum InventorySortOption: String, CaseIterable {
    case name = "name"
    case quantity = "quantity"
    case price = "price"
    case lowStock = "low_stock"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .quantity: return "Quantity"
        case .price: return "Price"
        case .lowStock: return "Low Stock"
        }
    }
}

// MARK: - Inventory Row

struct InventoryRow: View {
    let item: InventoryItem
    let onUpdate: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            showingDetail = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: item.category.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text("Part #: \(item.partNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 8) {
                        if item.quantity <= item.minQuantity {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        Text("\(item.quantity)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(item.quantity <= item.minQuantity ? .orange : .primary)
                    }
                    Text("$\(item.price, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            InventoryDetailView(item: item, onUpdate: onUpdate)
        }
    }
}

// MARK: - Inventory Detail View

struct InventoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State var item: InventoryItem
    let onUpdate: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    LabeledContent("Name", value: item.name)
                    LabeledContent("Part Number", value: item.partNumber)
                    LabeledContent("Category", value: item.category.displayName)
                }
                
                Section("Stock") {
                    LabeledContent("Current Quantity") {
                        HStack {
                            Button {
                                if item.quantity > 0 {
                                    item.quantity -= 1
                                    saveItem()
                                }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                            
                            Text("\(item.quantity)")
                                .font(.headline)
                                .frame(minWidth: 40)
                            
                            Button {
                                item.quantity += 1
                                saveItem()
                            } label: {
                                Image(systemName: "plus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    
                    LabeledContent("Minimum Quantity", value: "\(item.minQuantity)")
                    
                    if item.quantity <= item.minQuantity {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Low stock - reorder soon")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Pricing") {
                    LabeledContent("Unit Price", value: "$\(item.price, specifier: "%.2f")")
                    LabeledContent("Total Value", value: "$\(Double(item.quantity) * item.price, specifier: "%.2f")")
                }
                
                Section("Additional Info") {
                    LabeledContent("Supplier", value: item.supplier)
                    LabeledContent("Location", value: item.location)
                    if !item.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notes:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(item.notes)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
    
    private func saveItem() {
        // Update in UserDefaults
        if var inventory = UserDefaults.standard.data(forKey: "inventory"),
           var items = try? JSONDecoder().decode([InventoryItem].self, from: inventory) {
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = item
                if let encoded = try? JSONEncoder().encode(items) {
                    UserDefaults.standard.set(encoded, forKey: "inventory")
                    onUpdate()
                }
            }
        }
    }
}

// MARK: - Add Inventory Item

struct AddInventoryItemView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (InventoryItem) -> Void
    
    @State private var name = ""
    @State private var partNumber = ""
    @State private var category: InventoryCategory = .other
    @State private var quantity = 0
    @State private var minQuantity = 5
    @State private var price = ""
    @State private var supplier = ""
    @State private var location = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Item Name *", text: $name)
                    TextField("Part Number *", text: $partNumber)
                    Picker("Category", selection: $category) {
                        ForEach(InventoryCategory.allCases.filter { $0 != .all }, id: \.self) { category in
                            Label(category.displayName, systemImage: category.icon).tag(category)
                        }
                    }
                }
                
                Section("Stock") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 0...1000)
                    Stepper("Min Quantity: \(minQuantity)", value: $minQuantity, in: 0...100)
                }
                
                Section("Pricing") {
                    TextField("Unit Price *", text: $price, prompt: Text("$0.00"))
                }
                
                Section("Additional Details") {
                    TextField("Supplier", text: $supplier)
                    TextField("Storage Location", text: $location, prompt: Text("Shelf A1, Drawer 3, etc."))
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if notes.isEmpty {
                                Text("Notes...")
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .allowsHitTesting(false)
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
                    Button("Add") {
                        addItem()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .frame(width: 600, height: 700)
    }
    
    private var isValid: Bool {
        !name.isEmpty && !partNumber.isEmpty && Double(price) != nil
    }
    
    private func addItem() {
        guard let priceValue = Double(price) else { return }
        
        let item = InventoryItem(
            name: name,
            partNumber: partNumber,
            category: category,
            quantity: quantity,
            minQuantity: minQuantity,
            price: priceValue,
            supplier: supplier,
            location: location,
            notes: notes
        )
        
        onSave(item)
        dismiss()
    }
}
