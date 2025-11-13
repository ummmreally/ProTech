//
//  InventoryListView.swift
//  ProTech
//
//  Comprehensive inventory list with search, filter, and management
//

import SwiftUI

struct InventoryListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \InventoryItem.name, ascending: true)],
        predicate: NSPredicate(format: "isActive == true")
    ) var items: FetchedResults<InventoryItem>
    
    @State private var searchText = ""
    @State private var selectedCategory: InventoryCategory = .all
    @State private var sortOption: InventorySortOption = .name
    @State private var showLowStockOnly = false
    @State private var showingAddItem = false
    @State private var selectedItem: InventoryItem?
    @State private var adjustingItem: InventoryItem?
    @State private var showingBatchPrintDialog = false
    @State private var labelCopies = 1
    
    var filteredItems: [InventoryItem] {
        var filtered = Array(items)
        
        // Search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                ($0.name?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.partNumber?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.sku?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Category filter
        if selectedCategory != .all {
            filtered = filtered.filter { $0.inventoryCategory == selectedCategory }
        }
        
        // Low stock filter
        if showLowStockOnly {
            filtered = filtered.filter { $0.isLowStock }
        }
        
        // Sort
        switch sortOption {
        case .name:
            filtered.sort { ($0.name ?? "") < ($1.name ?? "") }
        case .quantity:
            filtered.sort { $0.quantity > $1.quantity }
        case .price:
            filtered.sort { $0.sellingPrice > $1.sellingPrice }
        case .lowStock:
            filtered.sort { $0.quantity < $1.quantity }
        case .value:
            filtered.sort { $0.totalValue > $1.totalValue }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filters
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search items, part numbers, SKU...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                HStack {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(InventoryCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    .frame(width: 200)
                    
                    Picker("Sort", selection: $sortOption) {
                        ForEach(InventorySortOption.allCases, id: \.self) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .frame(width: 150)
                    
                    Toggle("Low Stock Only", isOn: $showLowStockOnly)
                    
                    Spacer()
                    
                    Text("\(filteredItems.count) items")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // Inventory List
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(filteredItems, id: \.id) { item in
                        InventoryItemRow(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItem = item
                            }
                            .contextMenu {
                                Button {
                                    selectedItem = item
                                } label: {
                                    Label("View Details", systemImage: "eye")
                                }
                                
                                Button {
                                    adjustStock(item: item)
                                } label: {
                                    Label("Adjust Stock", systemImage: "plus.forwardslash.minus")
                                }
                                
                                Button {
                                    DymoPrintService.shared.printProductLabel(product: item)
                                } label: {
                                    Label("Print Label", systemImage: "printer.fill")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    Button {
                        printAllVisibleLabels()
                    } label: {
                        Label("Print All Visible (\(filteredItems.count))", systemImage: "printer.fill")
                    }
                    .disabled(filteredItems.isEmpty)
                    
                    Button {
                        showingBatchPrintDialog = true
                    } label: {
                        Label("Print with Options...", systemImage: "printer.dotmatrix.fill")
                    }
                    .disabled(filteredItems.isEmpty)
                } label: {
                    Label("Print Labels", systemImage: "printer")
                }
                
                Button {
                    exportInventory()
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add Item", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemView()
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item)
        }
        .sheet(item: $adjustingItem) { item in
            StockAdjustmentSheet(item: item)
        }
        .sheet(isPresented: $showingBatchPrintDialog) {
            BatchPrintOptionsView(
                itemCount: filteredItems.count,
                onPrint: { copies in
                    printLabelsWithCopies(copies)
                }
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: searchText.isEmpty ? "shippingbox" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text(searchText.isEmpty ? "No Inventory Items" : "No Results Found")
                .font(.title2)
                .foregroundColor(.secondary)
            if searchText.isEmpty {
                Button {
                    showingAddItem = true
                } label: {
                    Label("Add First Item", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func adjustStock(item: InventoryItem) {
        adjustingItem = item
    }
    
    private func deleteItem(_ item: InventoryItem) {
        InventoryService.shared.deleteItem(item)
    }
    
    private func printAllVisibleLabels() {
        DymoPrintService.shared.printProductLabels(products: filteredItems, copies: 1)
    }
    
    private func printLabelsWithCopies(_ copies: Int) {
        DymoPrintService.shared.printProductLabels(products: filteredItems, copies: copies)
    }
    
    private func exportInventory() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "inventory_\(Date().formatted(date: .numeric, time: .omitted)).csv"
        
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            
            var csv = "Name,Part Number,SKU,Category,Quantity,Cost Price,Selling Price,Location\n"
            for item in filteredItems {
                csv += "\(item.name ?? ""),\(item.partNumber ?? ""),\(item.sku ?? ""),\(item.category ?? ""),\(item.quantity),\(item.costPrice),\(item.sellingPrice),\(item.location ?? "")\n"
            }
            
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Inventory Item Row

struct InventoryItemRow: View {
    @ObservedObject var item: InventoryItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: categoryIcon)
                    .foregroundColor(categoryColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Unknown")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let partNumber = item.partNumber {
                        Text("PN: \(partNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let sku = item.sku {
                        Text("SKU: \(sku)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stock Status
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    if item.isOutOfStock {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    } else if item.isLowStock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                    
                    Text("\(item.quantity)")
                        .font(.title3)
                        .bold()
                        .foregroundColor(item.isOutOfStock ? .red : item.isLowStock ? .orange : .primary)
                }
                
                Text(String(format: "$%.2f", item.sellingPrice))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private var categoryIcon: String {
        guard let category = item.category,
              let inventoryCategory = InventoryCategory(rawValue: category) else {
            return "shippingbox"
        }
        return inventoryCategory.icon
    }
    
    private var categoryColor: Color {
        switch item.category {
        case "screens": return .blue
        case "batteries": return .green
        case "cables": return .orange
        case "tools": return .purple
        default: return .gray
        }
    }
}

// MARK: - Sort Option

enum InventorySortOption: String, CaseIterable {
    case name = "name"
    case quantity = "quantity"
    case price = "price"
    case lowStock = "low_stock"
    case value = "value"
    
    var displayName: String {
        switch self {
        case .name: return "Name"
        case .quantity: return "Quantity"
        case .price: return "Price"
        case .lowStock: return "Low Stock"
        case .value: return "Total Value"
        }
    }
}
